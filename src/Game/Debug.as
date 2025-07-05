// 这是为改版制作的调试用类，在 Root.as 中实例化

package Game {
    import Game.Entity.GameEntity.*;
    import Menus.TitleMenu;
    import starling.display.Sprite;
    import starling.events.EnterFrameEvent;
    import starling.text.TextField;
    import Game.Entity.EntityHandler;
    import flash.ui.Keyboard;
    import starling.filters.FragmentFilter;
    import starling.filters.ColorMatrixFilter;
    import utils.Rng

    public class Debug extends Sprite {
        public var debug:Boolean; // debug 开启状态
        public var dt:Number; // 帧时间
        public var game:GameScene; // GameScene 接口
        public var title:TitleMenu; // TitleMenu 接口
        private var scene:SceneController;

        public var debugLables:Array; // 调试显示文本

        // #region 初始化
        public function Debug(_scene:SceneController) {
            super();
            this.scene = _scene;
        }

        public function init(_gameScene:GameScene, _titleMenu:TitleMenu):void {
            this.game = _gameScene;
            this.title = _titleMenu;
            this.debug = false;
            fpsCalculator = [0, 0, 0, 0, 0, 0, 0];
            debugLables = [];
            nodeTagLables = [[], [], []];
            addDebugView();
            addEventListener("enterFrame", update);
        }

        public function addDebugView():void {
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
        public function update(e:EnterFrameEvent):void {
            if (!debug) {
                clear_tag();
                return;
            }
            dt = e.passedTime;
            updateFPS();
            updateDebugLabel();
            if (game.visible)
                updateTag();
            else
                clear_tag();
        }

        public function on_key_down(_keyCode:int):void {
            if (!debug)
                return;
            switch (_keyCode) {
                case Keyboard.Q: // Q 启用 Debug 模式，已移至 Root.as 中
                    break;
                case Keyboard.W:
                    clear_node(game.ui.debug_touch_Node);
                    break;
                case Keyboard.E: // +100 飞船
                    EntityHandler.addAI(1,2)
                    if (game.ui.debug_touch_Node)
                        EntityHandler.addShips(game.ui.debug_touch_Node, 1, 100);
                    break;
                case Keyboard.R: // 添加特效
                    game.ui.debug_touch_Node.image.filter = createFilter();
                    break;
                case Keyboard.S: // 跳关
                    game.next();
                    break;
                case Keyboard.A:
                    game.ui.debug_touch_Node.changeType(3)
                    break;
                case Keyboard.Z:
                    scene.applyFilter()
                    break;
                case Keyboard.X:
                    title.init()
                    title.animateIn()
                    break;
                case Keyboard.F:
                    var rng:Rng = new Rng();
                    trace(rng.seed);
                    break;
                case Keyboard.C:
                    if (game.ui.debug_touch_Node)
                        EntityHandler.addShips(game.ui.debug_touch_Node, 3, 100);
                    break;
                case Keyboard.F:
                    var _ship:Ship = findShipsInRange();
                    if (_ship)
                        trace(_ship);
                    break;
                default:
                    break;
            }
        }

        // 进入游戏时触发一次
        public function init_game():void {
            init_tag();
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
        private function updateDebugLabel():void {
            if (game.visible) {
                debugLables[1].text = game.ais.active[game.ais.active.length - 1].debugTrace[0];
                debugLables[2].text = game.ais.active[game.ais.active.length - 1].debugTrace[1];
                debugLables[3].text = game.ais.active[game.ais.active.length - 1].debugTrace[2];
                debugLables[4].text = game.ais.active[game.ais.active.length - 1].debugTrace[3];
                debugLables[5].text = game.ais.active[game.ais.active.length - 1].debugTrace[4];
            } else {
                debugLables[1].text = "test";
                debugLables[2].text = "";
                debugLables[3].text = "";
                debugLables[4].text = "";
            }
        }

        private var fpsCalculator:Array; // 帧率计算器
        private function updateFPS():void {
            fpsCalculator[0]++;
            if (fpsCalculator[0] == 6)
                fpsCalculator[0] -= 5;
            fpsCalculator[fpsCalculator[0]] = dt;
            fpsCalculator[6] = 1 / ((fpsCalculator[1] + fpsCalculator[2] + fpsCalculator[3] + fpsCalculator[4] + fpsCalculator[5]) / 5);
            debugLables[0].text = "FPS:" + Math.floor(fpsCalculator[6]);
        }

        private var nodeTagLables:Array; // 显示天体tag和战争占据状态
        private function updateTag():void {
            if (game.nodes.active.length != nodeTagLables[0].length)
                init_tag(); // 重置tag
            for each (var _node:Node in game.nodes.active) { // 更新tag位置
                nodeTagLables[0][_node.tag].x = _node.x - 30 * _node.size - 60;
                nodeTagLables[0][_node.tag].y = _node.y - 50 * _node.size - 48;
                nodeTagLables[1][_node.tag].x = _node.x - 60;
                nodeTagLables[1][_node.tag].y = _node.y + 50 * _node.size - 30;
                nodeTagLables[2][_node.tag].x = _node.x - 60;
                nodeTagLables[2][_node.tag].y = _node.y + 50 * _node.size - 30;
                if (_node.conflict)
                    nodeTagLables[1][_node.tag].visible = true;
                else
                    nodeTagLables[1][_node.tag].visible = false;
                if (_node.capturing) {
                    nodeTagLables[2][_node.tag].visible = true;
                    nodeTagLables[2][_node.tag].text = "RATE: " + _node.captureRate.toFixed(2);
                } else
                    nodeTagLables[2][_node.tag].visible = false;
            }
        }

        private function init_tag():void { // 重置tag
            clear_tag();
            for each (var _node:Node in game.nodes.active) {
                _node.tag = game.nodes.active.indexOf(_node);
                var _label:TextField = new TextField(60, 48, String(_node.tag), "Downlink12", -1, 16777215);
                _label.vAlign = _label.hAlign = "center";
                _label.pivotX = -30;
                _label.pivotY = -24;
                _label.alpha = 1;
                _label.touchable = false;
                _label.visible = true;
                addChild(_label);
                nodeTagLables[0].push(_label);
                _label = new TextField(60, 48, "conflict", "Downlink12", -1, 16777215);
                _label.vAlign = _label.hAlign = "center";
                _label.pivotX = -30;
                _label.pivotY = -24;
                _label.alpha = 1;
                _label.touchable = false;
                _label.visible = false;
                addChild(_label);
                nodeTagLables[1].push(_label);
                _label = new TextField(60, 48, "capture", "Downlink12", -1, 16777215);
                _label.vAlign = _label.hAlign = "center";
                _label.pivotX = -30;
                _label.pivotY = -24;
                _label.alpha = 1;
                _label.touchable = false;
                _label.visible = false;
                addChild(_label);
                nodeTagLables[2].push(_label);
            }
        }

        private function clear_tag():void { // 清除tag
            if (nodeTagLables[0].length == 0)
                return;
            for each (var _array:Array in nodeTagLables) {
                for each (var _label:TextField in _array) {
                    _label.visible = false;
                    removeChild(_label);
                }
            }
            nodeTagLables = [[], [], []];
        }

        // #endregion
        // #region 调试函数，手动触发
        private function set_orbit_node():void {
            var _dx:Number = game.nodes.active[0].x - game.nodes.active[1].x;
            var _dy:Number = game.nodes.active[0].y - game.nodes.active[1].y;
            var _distance:Number = Math.sqrt(_dx * _dx + _dy * _dy);
            var _angle:Number = Math.atan2(_dy, _dx);
            game.nodes.active[0].orbitAngle = _angle;
            game.nodes.active[0].orbitDist = _distance;
            game.nodes.active[0].orbitSpeed = 0.1;
            game.nodes.active[0].orbitNode = game.nodes.active[1];
        }

        private function clear_debug_trace():void {
            game.ais.active[0].debugTrace[0] = null;
            game.ais.active[0].debugTrace[1] = null;
            game.ais.active[0].debugTrace[2] = null;
            game.ais.active[0].debugTrace[3] = null;
            game.ais.active[0].debugTrace[4] = null;
        }

        private function replace_AI():void {
            for each (var _ai:EnemyAI in game.ais.active) {
                _ai.type = 4;
            }
        }

        private function set_expandDarkPulse(_team:int):void {
            game.darkPulse.team = _team;
            game.darkPulse.scaleX = game.darkPulse.scaleY = 0;
            game.darkPulse.visible = true;
        }

        private function clear_node(_Node:Node):void {
            if (!_Node)
                return;
            for each (var arr:Array in _Node.ships) {
                while (arr.length > 0) {
                    arr[0].hp = 0;
                    arr[0].destroy();
                    arr.shift();
                }
            }
            _Node.changeTeam(0);
        }

        private function findShipsInRange():Ship {
            var dx:Number;
            var dy:Number;
            var ship:Ship;
            const range:int = 5;
            for each (ship in game.ships.active) {
                dx = ship.x - game.ui.debug_mouse_x;
                dy = ship.y - game.ui.debug_mouse_y;
                if (dx > range || dx < -range || dy > range || dy < -range)
                    continue;
                if (Math.sqrt(dx * dx + dy * dy) < range)
                    return ship;
            }
            return null;
        }

        private function createFilter():ColorMatrixFilter{
            var filter:ColorMatrixFilter = new ColorMatrixFilter();
            filter.adjustBrightness(0.5);
            return filter;
        }
        // #endregion
    }
}
