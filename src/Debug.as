// 这是为改版制作的调试用类，在 Root.as 中实例化
package {
    import starling.display.Sprite;
    import starling.text.TextField;
    import starling.filters.ColorMatrixFilter;

    import flash.ui.Keyboard;

    import scenes.GameScene;
    import scenes.TitleMenu;

    import managers.Globals;

    import ui.UIContainer;

    import core.EntityContainer;
    import core.entities.Node;
    import core.entities.EnemyAI;
    import ui.components.OptionButton;
    import scenes.StartMenu;
    import core.entities.Ship;
    import flash.filesystem.FileStream;
    import flash.filesystem.File;
    import scenes.ReplayScene;
    import flash.utils.ByteArray;
    import flash.utils.CompressionAlgorithm;
    import flash.filesystem.FileMode;
    import utils.NumberInput;

    public class Debug extends Sprite {
        private static var debug:Boolean; // debug 开启状态
        private static var game:GameScene; // GameScene 接口
        private static var title:TitleMenu; // TitleMenu 接口
        private static var replay:ReplayScene; // ReplayScene 接口
        private static var scene:SceneController;
        private static var THIS:Debug;

        private var dt:Number; // 帧时间
        private var debugLables:Array; // 调试显示文本

        private var tagLayer:Sprite;

        private var seed:uint;

        // #region 初始化
        public function Debug(scene:SceneController) {
            super();
            scene = scene;
        }

        public function init(gameScene:GameScene, titleMenu:TitleMenu, replayScene:ReplayScene):void {
            game = gameScene;
            title = titleMenu;
            replay = replayScene;
            debug = false;
            THIS = this;
            fpsCalculator = [0, 0, 0, 0, 0, 0, 0];
            debugLables = [];
            nodeTagLables = [[], [], []];
            seed = 0;
            addDebugView();
            // addEventListener("enterFrame", update);
            // startDebugMode();

            tagLayer = new Sprite();
            tagLayer.x = tagLayer.pivotX = 512;
            tagLayer.y = tagLayer.pivotY = 384;
            addChild(tagLayer)
        }

        private function addDebugView():void {
            var y:Number = 100;
            debugLables.push(new TextField(1000, 40, "DebugView", "Downlink12", -1, 16777215));
            debugLables.push(new TextField(1000, 40, "DebugView", "Downlink12", -1, 16777215));
            debugLables.push(new TextField(1000, 40, "DebugView", "Downlink12", -1, 16777215));
            debugLables.push(new TextField(1000, 40, "DebugView", "Downlink12", -1, 16777215));
            debugLables.push(new TextField(1000, 40, "DebugView", "Downlink12", -1, 16777215));
            debugLables.push(new TextField(1000, 40, "DebugView", "Downlink12", -1, 16777215));
            for each (var label:TextField in debugLables) {
                label.vAlign = "top";
                label.hAlign = "left";
                label.x = 40;
                label.y = y;
                label.alpha = 1;
                label.visible = false;
                label.touchable = false;
                addChild(label);
                y += 12;
            }
            updateDebugLabel();
        }

        // #endregion
        // #region 调试函数调用工具
        public static function update(dt:Number):void {
            if (!debug) {
                clear_tag();
                return;
            }
            THIS.dt = dt;
            updateFPS();
            updateDebugLabel();
            if (game.visible)
                updateTag();
            else
                clear_tag();
            if (game.visible || replay.visible)
                deserializeGame(dt);
        }

        private var pause:Boolean = false;

        public static function on_key_down(keyCode:int):void {
            if (!debug)
                return;
            switch (keyCode) {
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
                case Keyboard.P:
                    THIS.pause = !THIS.pause;
                    if (THIS.pause)
                        Globals.main.starling.stop();
                    else
                        Globals.main.starling.start();
                    break;
                case Keyboard.ENTER:
                case Keyboard.NUMPAD_ENTER:
                    if (!NumberInput.visible)
                        title.loadMap(THIS.seed);
                    break;
                case Keyboard.T: // 进入设置/势力编辑器页面
                    THIS.gotoTeamEditorMenu();
                    break;
                case Keyboard.A: // 进入设置/高级设置页面
                    THIS.gotoAdvancedSettingMenu();
                    break;
                case Keyboard.G: // 导出记录数据
                    THIS.outputGameData();
                    break;
                case Keyboard.I: // 打开种子输入
                    NumberInput.awake(THIS, THIS.debugLables[1]);
                    break;
                default:
                    break;
            }
        }

        // 进入游戏时触发一次
        public function init_game():void {
            tagLayer.scaleX = tagLayer.scaleY = UIContainer.scale;
            gameData = [];
            // init_tag();
        }

        // 启动debug触发一次
        public function startDebugMode():void {
            if (debug)
                debug = false;
            else
                debug = true;
            for each (var label:TextField in debugLables) {
                if (label.visible)
                    label.visible = false;
                else
                    label.visible = true;
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
            for each (var node:Node in EntityContainer.nodes) { // 更新tag位置
                THIS.nodeTagLables[0][node.tag].x = node.nodeData.x - 30 * node.nodeData.size - 60;
                THIS.nodeTagLables[0][node.tag].y = node.nodeData.y - 50 * node.nodeData.size - 48;
                THIS.nodeTagLables[1][node.tag].x = node.nodeData.x - 60;
                THIS.nodeTagLables[1][node.tag].y = node.nodeData.y + 50 * node.nodeData.size - 30;
                THIS.nodeTagLables[2][node.tag].x = node.nodeData.x - 60;
                THIS.nodeTagLables[2][node.tag].y = node.nodeData.y + 50 * node.nodeData.size - 30;
                if (node.conflict)
                    THIS.nodeTagLables[1][node.tag].visible = true;
                else
                    THIS.nodeTagLables[1][node.tag].visible = false;
                if (node.capturing) {
                    THIS.nodeTagLables[2][node.tag].visible = true;
                    THIS.nodeTagLables[2][node.tag].text = "RATE: " + node.captureState.captureRate.toFixed(2);
                } else
                    THIS.nodeTagLables[2][node.tag].visible = false;
            }
        }

        private static function init_tag():void { // 重置tag
            clear_tag();
            for each (var node:Node in EntityContainer.nodes) {
                node.tag = EntityContainer.nodes.indexOf(node);
                var label:TextField = new TextField(60, 48, String(node.tag), "Downlink12", -1, 16777215);
                label.vAlign = label.hAlign = "center";
                label.pivotX = -30;
                label.pivotY = -24;
                label.alpha = 1;
                label.touchable = false;
                label.visible = true;
                THIS.tagLayer.addChild(label);
                THIS.nodeTagLables[0].push(label);
                label = new TextField(60, 48, "conflict", "Downlink12", -1, 16777215);
                label.vAlign = label.hAlign = "center";
                label.pivotX = -30;
                label.pivotY = -24;
                label.alpha = 1;
                label.touchable = false;
                label.visible = false;
                THIS.tagLayer.addChild(label);
                THIS.nodeTagLables[1].push(label);
                label = new TextField(60, 48, "capture", "Downlink12", -1, 16777215);
                label.vAlign = label.hAlign = "center";
                label.pivotX = -30;
                label.pivotY = -24;
                label.alpha = 1;
                label.touchable = false;
                label.visible = false;
                THIS.tagLayer.addChild(label);
                THIS.nodeTagLables[2].push(label);
            }
        }

        private static function clear_tag():void { // 清除tag
            if (THIS.nodeTagLables[0].length == 0)
                return;
            for each (var array:Array in THIS.nodeTagLables) {
                for each (var label:TextField in array) {
                    label.visible = false;
                    THIS.tagLayer.removeChild(label);
                }
            }
            THIS.nodeTagLables = [[], [], []];
        }

        private static var gameData:Array;

        private static function deserializeGame(dt:Number):void {
            var data:Object = {dt: dt,
                    nodes: [],
                    ships: []};
            for each (var node:Node in EntityContainer.nodes)
                data.nodes.push(node.toJSON());
            for each (var ships:Ship in EntityContainer.ships)
                data.ships.push(ships.toJSON());
            gameData.push(data);
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

        private function createFilter():ColorMatrixFilter {
            var filter:ColorMatrixFilter = new ColorMatrixFilter();
            filter.adjustBrightness(0.5);
            return filter;
        }

        private function gotoTeamEditorMenu():void {
            var startMenu:StartMenu = title.optionsMenu;
            if (!startMenu.visible)
                return;
            for each (var page:OptionButton in startMenu.pages)
                page.toggled = false;
            startMenu.pages[7].toggled = true;
            startMenu.on_page(null);
        }

        private function gotoAdvancedSettingMenu():void {
            var startMenu:StartMenu = title.optionsMenu;
            if (!startMenu.visible)
                return;
            for each (var page:OptionButton in startMenu.pages)
                page.toggled = false;
            startMenu.pages[6].toggled = true;
            startMenu.on_page(null);
        }

        private function outputGameData():void {
            var json:String = JSON.stringify(gameData);
            var bytes:ByteArray = new ByteArray();
            bytes.writeUTFBytes(json);
            bytes.compress(CompressionAlgorithm.DEFLATE); // 使用 DEFLATE 压缩

            var file:File = File.applicationStorageDirectory.resolvePath("gameData.dat");
            var stream:FileStream = new FileStream();
            stream.open(file, FileMode.WRITE);
            stream.writeBytes(bytes);
            stream.close();
        }

        // #endregion
        public static function test():void {
        }
    }
}
