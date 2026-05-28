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

    public class EditorScene extends BasicScene {
        // private const defaultNode:Object = {"x": 980,"y": 154,"type": "planet"};
        private const defaultNode:Object = {"x": 990, "y": 620, "type": "planet", "size": 0.5};

        /** 移动天体
         * @param node:int (tag)
         * @param x:Number
         * @param y:Number
         */
        public static const MOVE:String = "moveNode";

        /** 添加指定天体
         * @param node:Object
         */
        public static const ADD:String = "addNode";

        /** 删除天体
         * @param node:int (tag)
         */
        public static const DELETE:String = "deleteNode";

        public function EditorScene(scene:SceneController) {
            super(scene);
            visible = false;

            _initRegisterCommand();
        }

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
            UIContainer.i.update();
            EntityContainer.entityPool[EntityContainer.INDEX_NODES].updateActive();
        }

        // #region factories & objectPool 命令工厂和命令对象池
        private var _cmdMap:Dictionary = new Dictionary();
        private var _cmdUsage:Dictionary = new Dictionary();

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

        private function _initRegisterCommand():void {
            cmdPool = new Vector.<ICommand>;
            cmdUndoStack = new Vector.<ICommand>;
            cmdRedoStack = new Vector.<ICommand>;
            registerCommand(ADD, AddNode, [Object]);
            registerCommand(MOVE, ModNode, [Node, ModNode.MOVE, Number, Number]);
        }

        public function exeCode(type:String, params:Array):String {
            // 检查命令类型是否已注册
            var usage:Array = _cmdUsage[type];
            if (!usage)
                return "Error: unknown command type " + type;

            // 计算必须参数的最小数量（usage 中 Class 类型的数量）
            var requiredCount:int = 0;
            for each (var item:Object in usage)
                if (item is Class) requiredCount++;
            if (params.length < requiredCount)
                return "Error: insufficient parameters, expected at least " + requiredCount +", got " + params.length;

            var cmd:ICommand = _getCmd(type);
            if (!cmd)
                return "Error: failed to obtain command instance for type " + type;

            var finalParams:Array = createParameterArray();
            var paramIndex:int = 0; // 指向传入 params 的当前位置
            for (var i:int = 0; i < usage.length; i++) {
                var expected:Object = usage[i];
                // 期望的是默认值（非 Class），直接添加
                if (!(expected is Class)) {
                    finalParams.push(expected);
                    continue;
                }
                // 期望的是 Class 类型，从 params 中取下一个参数
                var currentParam:* = params[paramIndex++];
                // 类型直接匹配
                if (currentParam is (expected as Class)) {
                    finalParams.push(currentParam);
                    continue;
                }
                // 特殊处理：期望 Node 类型，但传入的是 int tag
                if (expected == Node && currentParam is int) {
                    var tag:int = currentParam as int;
                    if (tag < 0 || tag >= EntityContainer.nodes.length)
                        return "Error: Node tag out of range " + tag + " (max " + (EntityContainer.nodes.length - 1) + ")";
                    var node:Node = EntityContainer.nodes[tag] as Node;
                    if (!node)
                        return "Error: No node found with tag " + tag;
                    finalParams.push(node);
                    continue;
                }
                // 类型不匹配
                var expectedName:String = getQualifiedClassName(expected).split('::').pop();
                var actualType:String = (currentParam == null) ? "null" : getQualifiedClassName(currentParam).split('::').pop();
                return "Error: Parameter type mismatch at position " + paramIndex + ", expected " + expectedName + ", got " + actualType;
            }

            cmd.params = finalParams;
            var result:String = cmd.exeCode();
            if (result.indexOf("Error") == -1) {
                cmdUndoStack.push(cmd);
                cmdRedoStack.length = 0; // 执行成功
            } else
                cmdPool.push(cmd); // 执行失败
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
            var output:String = cmd.exeCode();
            cmdUndoStack.push(cmd);
            return output;
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
        this.data = arr[0];
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
                output = "move node " + node.tag + " to point ( " + value + " , " + value2 + " )";
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
                output = "undo move node " + node.tag + " from ( " + value + " , " + value2 + " )" + " to ( " + prevValue + " , " + prevValue2 + " )";
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
        this.node = arr[0];
        this.type = arr[1];
        this.value = arr[2];
        if (arr.length >= 4)
            this.value2 = arr[3];
    }
}
