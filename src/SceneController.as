package {
    import Menus.TitleMenu;
    import Game.GameScene;
    import Menus.EndScene;
    import Game.Debug;
    import starling.core.Starling;
    import flash.events.KeyboardEvent;
    import starling.display.Sprite;
    import starling.display.Quad;
    import starling.filters.ColorMatrixFilter;
    import UI.UIContainer;
    import utils.Popup;

    public class SceneController extends Sprite {
        private static var _s:SceneController;
        private static var _alert:Vector.<Popup>;

        public var titleMenu:TitleMenu; // 手动单例
        public var gameScene:GameScene; // 手动单例
        public var endScene:EndScene; // 手动单例
        public var debug:Debug; // 自动单例
        public var ui:UIContainer; // 自动单例

        public var speedMult:Number;

        public function SceneController() {
            super();
            _s = this;
            titleMenu = new TitleMenu(this);
            gameScene = new GameScene(this);
            endScene = new EndScene(this);
            debug = new Debug(this);
            ui = new UIContainer(this);
            speedMult = 1;
            initTitleMenu(0);
            debug.init(gameScene, titleMenu);
            addChild(titleMenu);
            addChild(gameScene);
            addChild(endScene);
            addChild(ui);
            addChild(debug);
            Starling.current.nativeStage.addEventListener("keyDown", on_key_down);
            initBlackQuad();

            ui.x = gameScene.x = ui.pivotX = gameScene.pivotX = 512;
            ui.y = gameScene.y = ui.pivotY = gameScene.pivotY = 384;
            gameScene.scaleX = gameScene.scaleY = ui.scale = 1;
            for each (var popup:Popup in _alert)
                addChild(popup)
        }

        // #region 处理黑边
        private var blackQuad:Array;
        private function initBlackQuad():void {
            blackQuad = new Array();
            var quad1:Quad = new Quad(1024, 114, 0);
            quad1.alpha = 0.4;
            addChild(quad1);
            blackQuad.push(quad1);
            var quad2:Quad = new Quad(1024, 114, 0);
            quad2.y = 768 - quad2.height;
            quad2.alpha = 0.4;
            addChild(quad2);
            blackQuad.push(quad2);
            updateBlackQuad();
        }

        public function updateBlackQuad():void {
            blackQuad[0].visible = blackQuad[1].visible = Globals.blackQuad;
        }
        // #endregion
        // #region 私有方法，界面载入载出
        private function initGameScene(seed:uint = 0, rep:Boolean = false):void {
            gameScene.init(seed, rep);
        }

        private function deInitGameScene():void {
            gameScene.deInit()
        }

        /**加载标题界面
         * @param type 0为首次加载，1为通关后加载
         */
        private function initTitleMenu(type:int = -1):void {
            switch (type) {
                case 0:
                    titleMenu.firstInit()
                    break;
                case 1:
                    titleMenu.initAfterEnd()
                    break
                default:
                    titleMenu.init()
                    break;
            }
        }

        private function deInitTitleMenu():void {
            titleMenu.deInit()
        }

        private function initEndScene():void {
            endScene.init()
        }

        private function deInitEndScene():void {
            endScene.deInit()
        }

        // #endregion
        // #region 切换界面

        /**游玩关卡*/
        public function playMap(seed:uint = 0):void {
            speedMult = 1;
            ui.initLevel();
            initGameScene(seed);
            debug.init_game();
        }

        public function replayMap():void {
            speedMult = 1;
            ui.initLevel();
            initGameScene(Globals.replay[0], true);
            debug.init_game();
        }

        /**编辑关卡*/
        public function editorMap():void {

        }

        /**弹出警告
         * @param label 警告文本
         */
        public static function alert(label:String):void {
            var popup:Popup = new Popup("ERROR");
            if (!_s){
                _alert = new Vector.<Popup>;
                _alert.push(popup);
            }else
                _s.addChild(popup);
            popup.addLabel(label);
        }

        /**退出到标题界面
         * @param type 0为直接退出关卡，1为从关卡退出且转到下一关，2为从退出动画进入标题界面
         */
        public function exit2TitleMenu(type:int = -1):void {
            switch (type) {
                case 0:
                    initTitleMenu()
                    titleMenu.animateIn()
                    break;
                case 1:
                    initTitleMenu()
                    titleMenu.animateIn()
                    titleMenu.nextLevel()
                    break;
                case 2:
                    initTitleMenu(1);
                    // applyFilter();
                    break;
                default:
                    initTitleMenu()
                    break;
            }
            ui.deinitLevel()
        }

        /**播放通关动画*/
        public function playEndScene():void {
            initEndScene();
        }

        // #endregion
        // #region 键盘事件
        public function on_key_down(event:KeyboardEvent):void {
            Debug.on_key_down(event.keyCode);
            switch (event.keyCode) {
                case 27: // 对应Esc键
                    if (titleMenu.visible)
                        titleMenu.optionsMenu.visible ? titleMenu.optionsMenu.animateOut() : titleMenu.on_menu(null);
                    else if (gameScene.visible)
                        gameScene.quit();
                    break;
                case 81: // Q 启用 Debug 模式
                    debug.startDebugMode();
                    break;
            }
            if (gameScene.visible)
                gameScene.on_key_down(event.keyCode)
            event.preventDefault();
            event.stopImmediatePropagation();
        }
        // #endregion

        // #region 神秘滤镜

        public function applyFilter():void {
            var fliter:ColorMatrixFilter = new ColorMatrixFilter();
            fliter.adjustBrightness(0.1);
            fliter.adjustContrast(0.25);
            parent.filter = fliter;
        }

        // #endregion
    }
}
