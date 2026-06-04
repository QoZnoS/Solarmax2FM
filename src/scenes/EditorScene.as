package scenes {
    import core.EntityContainer;
    import core.EntityHandler;
    import core.EntityPool;
    import core.entities.Node;
    import starling.core.Starling;
    import starling.events.EnterFrameEvent;
    import ui.UIContainer;
    import managers.SaveManager;
    import flash.utils.Dictionary;
    import flash.utils.getQualifiedClassName;
    import flash.ui.Keyboard;
    import flash.geom.Point;
    import flash.events.KeyboardEvent;
    import core.node.NodeType;
    import managers.Globals;

    public class EditorScene extends BasicScene {
        // private const defaultNode:Object = {"x": 980,"y": 154,"type": "planet"};
        private const defaultNode:Object = {"x": 990, "y": 620, "type": "planet", "size": 0.3};

        // #region 指令常量
        /** 移动天体
         * <p> node:int (tag)
         * <p> x:Number
         * <p> y:Number
         */
        public static const MOVE:String = "moveNode";

        /** 修改天体类型
         * <p> node:int (tag)
         * <p> type:String (NodeType)
         */
        public static const CTYPE:String = "changeType";

        /** 修改天体势力
         * <p> node:int (tag)
         * <p> team:int
         */
        public static const CTEAM:String = "changeTeam";

        /** 修改天体Size
         * <p> node:int (tag)
         * <p> size:Number
         */
        public static const CSIZE:String = "changeSize";

        /** 添加指定天体
         * <p> node:Object
         */
        public static const ADD:String = "addNode";

        /** 删除天体
         * <p> node:int (tag)
         */
        public static const DELETE:String = "deleteNode";

        // #endregion

        public function EditorScene(scene:SceneController) {
            super(scene);
            visible = false;
            mousePoint = new Point();

            _initRegisterCommand();
        }

        public var mousePoint:Point;
        public var hoverNode:Node;

        public function on_key_down(event:KeyboardEvent):void {
            var params:Array = createParameterArray();
            var key:uint = event.keyCode;
            var result:String;
            var temp:int;
            switch (key) {
                case Keyboard.NUMPAD_ADD:
                case Keyboard.Z: // 添加天体 撤回 重做
                    if (event.ctrlKey && event.shiftKey) {
                        result = redo();
                        break;
                    }
                    if (event.ctrlKey) {
                        result = undo();
                        break;
                    }
                    defaultNode.x = mousePoint.x;
                    defaultNode.y = mousePoint.y;
                    params.push(defaultNode);
                    result = exeCode(ADD, params);
                    break;
                case Keyboard.X: // 重做 TODO: 添加轨道
                    if (event.ctrlKey)
                        result = redo();
                    if (!hoverNode)
                        break;
                    break;
                case Keyboard.C: // 删除天体 复制
                    if (event.ctrlKey) {
                        copy();
                        break;
                    }
                    if (!hoverNode)
                        break;
                    params.push(hoverNode.tag);
                    result = exeCode(DELETE, params);
                    break;
                case Keyboard.V: // 粘贴
                    if (event.ctrlKey)
                        result = paste();
                    break;
                case Keyboard.A: // 上一个类型
                    if (!hoverNode)
                        break;
                    temp = NodeType.typeStr2Int(hoverNode.nodeData.type);
                    if (temp == 0)
                        temp = NodeType.getTypeCount() - 1;
                    else
                        temp--;
                    params.push(hoverNode.tag, NodeType.typeInt2Str(temp))
                    result = exeCode(CTYPE, params);
                    break;
                case Keyboard.D: // 下一个类型
                    if (!hoverNode)
                        break;
                    temp = NodeType.typeStr2Int(hoverNode.nodeData.type);
                    if (temp == NodeType.getTypeCount() - 1)
                        temp = 0;
                    else
                        temp++;
                    params.push(hoverNode.tag, NodeType.typeInt2Str(temp));
                    result = exeCode(CTYPE, params);
                    break;
                case Keyboard.W: // size + 0.1 只对星球有效
                    if (!hoverNode)
                        break;
                    if (hoverNode.nodeData.type != NodeType.PLANET)
                        break;
                    params.push(hoverNode.tag, hoverNode.nodeData.size + 0.1);
                    result = exeCode(CSIZE, params);
                    break;
                case Keyboard.S: // size - 0.1 只对星球有效 TODO: 保存
                    if (!hoverNode)
                        break;
                    if (hoverNode.nodeData.type != NodeType.PLANET)
                        break;
                    if (hoverNode.nodeData.size <= 0.3)
                        break;
                    params.push(hoverNode.tag, hoverNode.nodeData.size - 0.1);
                    result = exeCode(CSIZE, params);
                    break;
                case Keyboard.Q: // 上一个势力
                    if (!hoverNode)
                        break;
                    temp = hoverNode.nodeData.team;
                    if (temp == 0)
                        temp = Globals.teamCount - 1;
                    else
                        temp--;
                    params.push(hoverNode.tag, temp);
                    result = exeCode(CTEAM, params);
                    break;
                case Keyboard.E: // 下一个势力
                    if (!hoverNode)
                        break;
                    temp = hoverNode.nodeData.team;
                    if (temp == Globals.teamCount - 1)
                        temp = 0;
                    else
                        temp++;
                    params.push(hoverNode.tag, temp);
                    result = exeCode(CTEAM, params);
                    break;
                default:
                    break;
            }
            if (result)
                trace(result);
        }

        // #region 界面方法
        public function init():void {
            this.alpha = 1;
            this.visible = true;
            animateIn();
            EntityContainer.shipTagCounter = 0;
            addEventListener("enterFrame", update);

            // var node:Node = EntityHandler.addNode(defaultNode);
            // node.update(0);

        }

        public function deInit():void {
            for each (var pool:EntityPool in EntityContainer.entityPool)
                pool.deInit();
            removeEventListener("enterFrame", update); // 移除更新帧监听器
            visible = false;
            cmdPool.length = 0;
            cmdUndoStack.length = 0;
            cmdRedoStack.length = 0;
        }

        public function quit():void {
            animateOut();
            scene.exit2TitleMenu(3);
            Starling.juggler.tween(this, SaveManager.transitionSpeed, {onComplete: deInit});
        }

        override public function update(e:EnterFrameEvent):void {
            var dt:Number = e.passedTime;
            UIContainer.i.update(dt);
            EntityContainer.entityPool[EntityContainer.INDEX_NODES].updateActive();
            for (var i:int = 0; i < EntityContainer.nodes.length; i++)
                (EntityContainer.nodes[i] as Node).tag = i;
        }
        // #endregion

        // #region factories & objectPool 命令工厂和命令对象池
        private var _cmdMap:Dictionary = new Dictionary();
        private var _cmdUsage:Dictionary = new Dictionary();

        private function _initRegisterCommand():void {
            cmdPool = new Vector.<ICommand>;
            cmdUndoStack = new Vector.<ICommand>;
            cmdRedoStack = new Vector.<ICommand>;
            registerCommand(ADD, AddNode, [Object]);
            registerCommand(DELETE, DeleteNode, [Node]);
            registerCommand(MOVE, ModNode, [ModNode.MOVE, Node, Number, Number]);
            registerCommand(CTYPE, ModNode, [ModNode.TYPE, Node, String]);
            registerCommand(CTEAM, ModNode, [ModNode.TEAM, Node, int]);
            registerCommand(CSIZE, ModNode, [ModNode.SIZE, Node, Number]);
        }

        /** 统一管理所有可用命令和命令的用法，对上层执行进行转译
         * 可以添加自定义的ICommand实现，并使用自定义的调用方式配置
         * usage: 命令的使用方式，类型为Array
         * 调用命令时，依次检查param各项与usage声明类型是否匹配
         * 也可直接声明为值，作为默认值使用，检查时会跳过该项
         */
        public function registerCommand(type:String, cmdClass:Class, usage:Array):void {
            if (!(new cmdClass() is ICommand))
                throw new Error("commandClass not found")
            _cmdMap[type] = cmdClass;
            _cmdUsage[type] = usage;
        }

        public function exeCode(type:String, params:Array):String {
            // 检查命令类型是否已注册
            var usage:Array = _cmdUsage[type];
            if (!usage)
                return "Error: unknown command type " + type;
            var cmd:ICommand = _getCmd(type);
            if (!cmd)
                return "Error: failed to obtain command instance for type " + type;
            // 计算必须参数的最小数量（usage 中 Class 类型的数量）
            var requiredCount:int = 0;
            for each (var item:Object in usage)
                if (item is Class)
                    requiredCount++;
            if (params.length < requiredCount)
                return "Error: insufficient parameters, expected at least " + requiredCount + ", got " + params.length;
            // ---------- 第一阶段：提前校验所有参数，不修改 params ----------
            var paramIndex:int = 0;
            for (var i:int = 0; i < usage.length; i++) {
                var expected:Object = usage[i];
                if (!(expected is Class))
                    continue;
                // 取出当前参数
                var currentParam:* = params[paramIndex++];
                if (currentParam is (expected as Class))
                    continue;
                // 特殊处理：期望 Node 类型，但传入的是 int tag
                if (expected == Node && currentParam is int) {
                    var tag:int = currentParam as int;
                    if (tag < 0 || tag >= EntityContainer.nodes.length)
                        return "Error: Node tag out of range " + tag + " (max " + (EntityContainer.nodes.length - 1) + ")";
                    var node:Node = EntityContainer.nodes[tag] as Node;
                    if (!node)
                        return "Error: No node found with tag " + tag;
                    continue;
                }
                // 类型不匹配
                var expectedName:String = getQualifiedClassName(expected).split('::').pop();
                var actualType:String = (currentParam == null) ? "null" : getQualifiedClassName(currentParam).split('::').pop();
                return "Error: Parameter type mismatch at position " + paramIndex + ", expected " + expectedName + ", got " + actualType;
            }
            // ---------- 第二阶段：校验通过，就地修改 params 为最终参数数组 ----------
            // 调整长度为目标长度（截断多余参数或扩充）
            params.length = usage.length;
            // 从最后一个原始参数开始逆向读取
            var readIdx:int = requiredCount - 1;
            for (i = usage.length - 1; i >= 0; i--) {
                expected = usage[i];
                if (expected is Class) {
                    var raw:* = params[readIdx--];
                    if (raw is (expected as Class))
                        params[i] = raw;
                    else if (expected == Node && raw is int)
                        params[i] = EntityContainer.nodes[raw as int] as Node;
                } else
                    params[i] = expected;
            }
            cmd.params = params;
            var result:String = cmd.exeCode();
            if (result.indexOf("Error") == -1) {
                cmdUndoStack.push(cmd);
                cmdRedoStack.length = 0; // 执行成功
            } else {
                cmdPool.push(cmd); // 执行失败
            }
            return result;
        }

        public function undo():String {
            if (cmdUndoStack.length == 0)
                return "no command could undo."
            var cmd:ICommand = cmdUndoStack.pop();
            var output:String = cmd.undo();
            cmdRedoStack.push(cmd);
            return output;
        }

        public function redo():String {
            if (cmdRedoStack.length == 0)
                return "no command could redo.";
            var cmd:ICommand = cmdRedoStack.pop();
            var output:String = "redo " + cmd.exeCode();
            cmdUndoStack.push(cmd);
            return output;
        }

        private var clipboard:Object;
        public function copy():void {
            if (!hoverNode)
                return;
            clipboard = hoverNode.nodeData.toJSON();
        }

        public function paste():String {
            if (!clipboard)
                return "Error: clipboard is null";
            clipboard.x = mousePoint.x;
            clipboard.y = mousePoint.y;
            var params:Array = createParameterArray();
            params.push(clipboard);
            return exeCode(ADD, params);
        }

        private var cmdPool:Vector.<ICommand>; // 可使用的命令对象池
        private var cmdUndoStack:Vector.<ICommand>; // 撤回命令栈
        private var cmdRedoStack:Vector.<ICommand>; // 重做命令栈

        /**
         * 获取命令对象
         * @param type 对象类型
         * @return 命令对象
         */
        private function _getCmd(type:String):ICommand {
            var cmd:ICommand = null;
            var len:int = cmdPool.length;
            for (var i:int = 0; i < len; i++) {
                var cmdObj:ICommand = cmdPool[i];
                if (!(cmdObj is _cmdMap[type]))
                    continue;
                cmd = cmdObj;
                cmdPool.splice(i, 1);
                break;
            }
            if (cmd != null)
                return cmd;
            var typeClass:Class = _cmdMap[type] as Class;
            cmd = new typeClass();
            return cmd;
        }
        // #endregion

        // #region utils
        private var TEMP_ARR:Array;

        private function createParameterArray():Array {
            if (!TEMP_ARR)
                TEMP_ARR = [];
            TEMP_ARR.length = 0;
            return TEMP_ARR;
        }
        // #endregion
    }
}

import core.EntityHandler;
import core.entities.Node;
import core.node.NodeStaticLogic;

/** 构造函数声明参数类型， set param 应用参数 */
interface ICommand {
    function exeCode():String
    function undo():String
    function set params(arr:Array):void // 务必实现自定义读取，而非直接存放 arr 引用
}

class AddNode implements ICommand {
    var data:Object;
    var node:Node;

    public function AddNode(node:Object = null) {
    }

    public function exeCode():String {
        try {
            node = EntityHandler.addNode(data);
        } catch (error:Error) {
            return "Error: " + error.message;
        }
        node.update(0);
        return "add node.";
    }

    public function undo():String {
        try {
            EntityHandler.removeNode(node);
        } catch (error:Error) {
            return "Error: " + error.message;
        }
        return "undo add node.";
    }

    public function set params(arr:Array):void {
        this.data = JSON.parse(JSON.stringify(arr[0]));
    }
}

class DeleteNode implements ICommand {
    var data:Object;
    var node:Node;

    public function DeleteNode(node:Object = null) {
    }

    public function exeCode():String {
        try {
            EntityHandler.removeNode(node);
        } catch (error:Error) {
            return "Error: " + error.message;
        }
        return "remove node.";
    }

    public function undo():String {
        try {
            node = EntityHandler.addNode(data);
        } catch (error:Error) {
            return "Error: " + error.message;
        }
        node.update(0);
        return "undo remove node.";
    }

    public function set params(arr:Array):void {
        this.node = arr[0];
        this.data = arr[0].nodeData.toJSON();
    }
}

class ModNode implements ICommand {
    private var node:Node;
    private var type:String;
    private var value:Object;
    private var value2:Object;
    private var prevValue:Object;
    private var prevValue2:Object;

    public static const MOVE:String = "move";
    public static const TYPE:String = "type";
    public static const TEAM:String = "team";
    public static const SIZE:String = "size";

    public function ModNode(node:Node = null, type:String = null, value:Object = null, value2:Object = null) {
    }

    public function exeCode():String {
        var output:String;
        switch (type) {
            case MOVE:
                prevValue = node.nodeData.x;
                prevValue2 = node.nodeData.y;
                node.nodeData.x = value as Number;
                node.nodeData.y = value2 as Number;
                output = "move node " + node.tag + " to point (" + value + " , " + value2 + ")";
                break;
            case TYPE:
                prevValue = node.nodeData.type;
                NodeStaticLogic.changeType(node, value as String);
                output = "change node " + node.tag + " type to " + value;
                break;
            case TEAM:
                prevValue = node.nodeData.team;
                NodeStaticLogic.changeTeam(node, value as int, false);
                output = "change node " + node.tag + " team to " + value;
                break;
            case SIZE:
                prevValue = node.nodeData.size;
                NodeStaticLogic.changeSize(node, value as Number);
                output = "change node " + node.tag + " size to " + value;
                break;
            default:
                break;
        }
        node.update(0);
        if (!output)
            return "Error: command not execute";
        return output;
    }

    public function undo():String {
        var output:String;
        switch (type) {
            case MOVE:
                node.nodeData.x = prevValue as Number;
                node.nodeData.y = prevValue2 as Number;
                output = "undo move node " + node.tag + " from (" + value + " , " + value2 + ")" + " to (" + prevValue + " , " + prevValue2 + ")";
                break;
            case TYPE:
                NodeStaticLogic.changeType(node, prevValue as String);
                output = "undo change node " + node.tag + " form type " + prevValue + " to type " + value;
                break;
            case TEAM:
                NodeStaticLogic.changeTeam(node, prevValue as int, false);
                output = "undo change node " + node.tag + " form team " + prevValue + " to team " + value;
                break;
            case SIZE:
                NodeStaticLogic.changeSize(node, prevValue as Number);
                output = "undo change node " + node.tag + " form size " + prevValue + " to size " + value;
                break;
            default:
                break;
        }
        node.update(0);
        if (!output)
            return "Error: command not execute";
        return output;
    }

    public function set params(arr:Array):void {
        this.type = arr[0];
        this.node = arr[1];
        this.value = arr[2];
        if (arr.length >= 4)
            this.value2 = arr[3];
    }
}
