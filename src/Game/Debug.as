// 这是为改版制作的调试用类，在 Root.as 中实例化

package Game {
    import Menus.TitleMenu;
    import starling.display.Sprite;
    import starling.events.EnterFrameEvent;
    import starling.text.TextField;
    import flash.ui.Keyboard;
    import starling.filters.ColorMatrixFilter;
    import Entity.Node;
    import Entity.EnemyAI;
    import Entity.EntityContainer;
    import utils.Rng;

    public class Debug extends Sprite {
        private static var debug:Boolean; // debug 开启状态
        private static var game:GameScene; // GameScene 接口
        private static var title:TitleMenu; // TitleMenu 接口
        private static var scene:SceneController;
        private static var THIS:Debug;

        private var dt:Number; // 帧时间
        private var debugLables:Array; // 调试显示文本


        private var seed:uint;

        // #region 初始化
        public function Debug(_scene:SceneController) {
            super();
            scene = _scene;
        }

        public function init(_gameScene:GameScene, _titleMenu:TitleMenu):void {
            game = _gameScene;
            title = _titleMenu;
            debug = false;
            THIS = this;
            fpsCalculator = [0, 0, 0, 0, 0, 0, 0];
            debugLables = [];
            nodeTagLables = [[], [], []];
            seed = 0;
            addDebugView();
            addEventListener("enterFrame", update);
            startDebugMode();
        }

        private function addDebugView():void {
            var _y:Number = 100;
            debugLables.push(new TextField(1000, 40, "DebugView", "Downlink12", -1, 16777215));
            debugLables.push(new TextField(1000, 40, "DebugView", "Downlink12", -1, 16777215));
            debugLables.push(new TextField(1000, 40, "DebugView", "Downlink12", -1, 16777215));
            debugLables.push(new TextField(1000, 40, "DebugView", "Downlink12", -1, 16777215));
            debugLables.push(new TextField(1000, 40, "DebugView", "Downlink12", -1, 16777215));
            debugLables.push(new TextField(1000, 40, "DebugView", "Downlink12", -1, 16777215));
            for each (var _label:TextField in debugLables) {
                _label.vAlign = "top";
                _label.hAlign = "left";
                _label.x = 40;
                _label.y = _y;
                _label.alpha = 1;
                _label.visible = false;
                _label.touchable = false;
                addChild(_label);
                _y += 12;
            }
        }

        // #endregion
        // #region 调试函数调用工具
        public static function update(e:EnterFrameEvent):void {
            if (!debug) {
                clear_tag();
                return;
            }
            THIS.dt = e.passedTime;
            updateFPS();
            updateDebugLabel();
            if (game.visible)
                updateTag();
            else
                clear_tag();
        }

        private var pause:Boolean = false;
        public static function on_key_down(_keyCode:int):void {
            if (!debug)
                return;
            switch (_keyCode) {
                case Keyboard.Q: // Q 启用 Debug 模式，已移至 Root.as 中
                    break;
                case Keyboard.S: // 跳关
                    game.next();
                    break;
                case Keyboard.W:
                    test();
                    break;
                case Keyboard.Z:
                    scene.applyFilter()
                    break;
                case Keyboard.C:
                    THIS.pause = !THIS.pause;
                    if (THIS.pause)
                        Globals.main.starling.stop();
                    else
                        Globals.main.starling.start();
                    break;
                case Keyboard.NUMBER_0:
                case Keyboard.NUMBER_1:
                case Keyboard.NUMBER_2:
                case Keyboard.NUMBER_3:
                case Keyboard.NUMBER_4:
                case Keyboard.NUMBER_5:
                case Keyboard.NUMBER_6:
                case Keyboard.NUMBER_7:
                case Keyboard.NUMBER_8:
                case Keyboard.NUMBER_9:
                    if(THIS.seed > uint.MAX_VALUE/10)
                        THIS.seed = 0
                    THIS.seed = THIS.seed*10 + (_keyCode-48);
                    break;
                case Keyboard.NUMPAD_0:
                case Keyboard.NUMPAD_1:
                case Keyboard.NUMPAD_2:
                case Keyboard.NUMPAD_3:
                case Keyboard.NUMPAD_4:
                case Keyboard.NUMPAD_5:
                case Keyboard.NUMPAD_6:
                case Keyboard.NUMPAD_7:
                case Keyboard.NUMPAD_8:
                case Keyboard.NUMPAD_9:
                    if(THIS.seed > uint.MAX_VALUE/10)
                        THIS.seed = 0
                    THIS.seed = THIS.seed*10 + (_keyCode-96);
                    break;
                case Keyboard.ENTER:
                case Keyboard.NUMPAD_ENTER:
                    title.loadMap(THIS.seed);
                    break;
                default:
                    break;
            }
        }

        // 进入游戏时触发一次
        public function init_game():void {
            // init_tag();
        }

        // 启动debug触发一次
        public function startDebugMode():void {
            if (debug)
                debug = false;
            else
                debug = true;
            for each (var _label:TextField in debugLables) {
                if (_label.visible)
                    _label.visible = false;
                else
                    _label.visible = true;
            }
        }

        // #endregion
        // #region 调试函数，自动触发
        private static function updateDebugLabel():void {
            if (game.visible) {
                THIS.debugLables[1].text = "seed: " + String(game.rng.seed);
                THIS.debugLables[2].text = "";
                THIS.debugLables[3].text = "";
                THIS.debugLables[4].text = "";
                THIS.debugLables[5].text = "";
                // THIS.debugLables[1].text = EntityContainer.ais[EntityContainer.ais.length - 1].debugTrace[0];
                // THIS.debugLables[2].text = EntityContainer.ais[EntityContainer.ais.length - 1].debugTrace[1];
                // THIS.debugLables[3].text = EntityContainer.ais[EntityContainer.ais.length - 1].debugTrace[2];
                // THIS.debugLables[4].text = EntityContainer.ais[EntityContainer.ais.length - 1].debugTrace[3];
                // THIS.debugLables[5].text = EntityContainer.ais[EntityContainer.ais.length - 1].debugTrace[4];
            } else {
                THIS.debugLables[1].text = "seed: " + String(THIS.seed);
                THIS.debugLables[2].text = "";
                THIS.debugLables[3].text = "";
                THIS.debugLables[4].text = "";
                THIS.debugLables[5].text = "";
            }
        }

        private static var fpsCalculator:Array; // 帧率计算器
        private static function updateFPS():void {
            fpsCalculator[0]++;
            if (fpsCalculator[0] == 6)
                fpsCalculator[0] -= 5;
            fpsCalculator[fpsCalculator[0]] = THIS.dt;
            fpsCalculator[6] = 1 / ((fpsCalculator[1] + fpsCalculator[2] + fpsCalculator[3] + fpsCalculator[4] + fpsCalculator[5]) / 5);
            THIS.debugLables[0].text = "FPS:" + Math.floor(fpsCalculator[6]);
        }

        private var nodeTagLables:Array; // 显示天体tag和战争占据状态
        private static function updateTag():void {
            if (EntityContainer.nodes.length != THIS.nodeTagLables[0].length)
                init_tag(); // 重置tag
            for each (var _node:Node in EntityContainer.nodes) { // 更新tag位置
                THIS.nodeTagLables[0][_node.tag].x = _node.nodeData.x - 30 * _node.nodeData.size - 60;
                THIS.nodeTagLables[0][_node.tag].y = _node.nodeData.y - 50 * _node.nodeData.size - 48;
                THIS.nodeTagLables[1][_node.tag].x = _node.nodeData.x - 60;
                THIS.nodeTagLables[1][_node.tag].y = _node.nodeData.y + 50 * _node.nodeData.size - 30;
                THIS.nodeTagLables[2][_node.tag].x = _node.nodeData.x - 60;
                THIS.nodeTagLables[2][_node.tag].y = _node.nodeData.y + 50 * _node.nodeData.size - 30;
                if (_node.conflict)
                    THIS.nodeTagLables[1][_node.tag].visible = true;
                else
                    THIS.nodeTagLables[1][_node.tag].visible = false;
                if (_node.capturing) {
                    THIS.nodeTagLables[2][_node.tag].visible = true;
                    THIS.nodeTagLables[2][_node.tag].text = "RATE: " + _node.captureState.captureRate.toFixed(2);
                } else
                    THIS.nodeTagLables[2][_node.tag].visible = false;
            }
        }

        private static function init_tag():void { // 重置tag
            clear_tag();
            for each (var _node:Node in EntityContainer.nodes) {
                _node.tag = EntityContainer.nodes.indexOf(_node);
                var _label:TextField = new TextField(60, 48, String(_node.tag), "Downlink12", -1, 16777215);
                _label.vAlign = _label.hAlign = "center";
                _label.pivotX = -30;
                _label.pivotY = -24;
                _label.alpha = 1;
                _label.touchable = false;
                _label.visible = true;
                THIS.addChild(_label);
                THIS.nodeTagLables[0].push(_label);
                _label = new TextField(60, 48, "conflict", "Downlink12", -1, 16777215);
                _label.vAlign = _label.hAlign = "center";
                _label.pivotX = -30;
                _label.pivotY = -24;
                _label.alpha = 1;
                _label.touchable = false;
                _label.visible = false;
                THIS.addChild(_label);
                THIS.nodeTagLables[1].push(_label);
                _label = new TextField(60, 48, "capture", "Downlink12", -1, 16777215);
                _label.vAlign = _label.hAlign = "center";
                _label.pivotX = -30;
                _label.pivotY = -24;
                _label.alpha = 1;
                _label.touchable = false;
                _label.visible = false;
                THIS.addChild(_label);
                THIS.nodeTagLables[2].push(_label);
            }
        }

        private static function clear_tag():void { // 清除tag
            if (THIS.nodeTagLables[0].length == 0)
                return;
            for each (var _array:Array in THIS.nodeTagLables) {
                for each (var _label:TextField in _array) {
                    _label.visible = false;
                    THIS.removeChild(_label);
                }
            }
            THIS.nodeTagLables = [[], [], []];
        }

        // #endregion
        // #region 调试函数，手动触发

        private function clear_debug_trace():void {
            (EntityContainer.ais[0] as EnemyAI).debugTrace[0] = null;
            (EntityContainer.ais[0] as EnemyAI).debugTrace[1] = null;
            (EntityContainer.ais[0] as EnemyAI).debugTrace[2] = null;
            (EntityContainer.ais[0] as EnemyAI).debugTrace[3] = null;
            (EntityContainer.ais[0] as EnemyAI).debugTrace[4] = null;
        }

        private function createFilter():ColorMatrixFilter{
            var filter:ColorMatrixFilter = new ColorMatrixFilter();
            filter.adjustBrightness(0.5);
            return filter;
        }
        // #endregion
        public static function test():void{
        }
    }
}
