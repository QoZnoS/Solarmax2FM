package {
    import Menus.TitleMenu;
    import Game.GameScene;
    import Menus.EndScene;
    import Game.Debug;
    import starling.core.Starling;
    import flash.events.KeyboardEvent;
    import MapEditor.EditorCenter;
    import starling.display.Sprite;
    import starling.display.Quad;
    import starling.filters.ColorMatrixFilter;

    public class SceneController extends Sprite {
        public var titleMenu:TitleMenu;
        public var gameScene:GameScene;
        public var endScene:EndScene;
        public var mapEditor:EditorCenter;
        public var debug:Debug;

        public function SceneController() {
            super();
            titleMenu = new TitleMenu(this);
            gameScene = new GameScene(this);
            endScene = new EndScene(this);
            debug = new Debug(this);
            initTitleMenu(0);
            debug.init(gameScene, titleMenu);
            addChild(titleMenu);
            addChild(gameScene);
            addChild(endScene);
            initBlackQuad()
            addChild(debug);
            Starling.current.nativeStage.addEventListener("keyDown", on_key_down);
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
        private function initGameScene():void {
            gameScene.init();
        }

        private function deInitGameScene():void {
            gameScene.deInit()
        }

        /**
         * 加载标题界面
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

        /**
         * 游玩关卡
         */
        public function playMap():void {
            initGameScene();
            debug.init_game();
        }

        /**
         * 编辑关卡
         */
        public function editorMap():void {

        }

        /**
         * 退出到标题界面
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
                    break;
                default:
                    initTitleMenu()
                    break;
            }
        }

        /**
         * 播放通关动画
         */
        public function playEndScene():void {
            initEndScene();
        }

        // #endregion

        // #region 键盘事件
        public function on_key_down(event:KeyboardEvent):void {
            debug.on_key_down(event.keyCode);
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
            if (gameScene.visible) {
                switch (event.keyCode) {
                    case 32: // 对应Spacebar，即空格
                        if (!Starling.current.isStarted) {
                            Globals.main.on_resume(null);
                            break;
                        }
                        gameScene.pause();
                        break;
                    case 49: // 大键盘上的1
                    case 97: // 小键盘上的1
                        gameScene.ui.movePerc = 0.1;
                        break;
                    case 50: // 大键盘上的2
                    case 98: // 小键盘上的2
                        gameScene.ui.movePerc = 0.2;
                        break;
                    case 51:
                    case 99:
                        gameScene.ui.movePerc = 0.3;
                        break;
                    case 52:
                    case 100:
                        gameScene.ui.movePerc = 0.4;
                        break;
                    case 53:
                    case 101:
                        gameScene.ui.movePerc = 0.5;
                        break;
                    case 54:
                    case 102:
                        gameScene.ui.movePerc = 0.6;
                        break;
                    case 55:
                    case 103:
                        gameScene.ui.movePerc = 0.7;
                        break;
                    case 56:
                    case 104:
                        gameScene.ui.movePerc = 0.8;
                        break;
                    case 57:
                    case 105:
                        gameScene.ui.movePerc = 0.9;
                        break;
                    case 48:
                    case 96:
                        gameScene.ui.movePerc = 1;
                }
                gameScene.ui.movePercentBar(gameScene.ui.movePerc);
            }
            event.preventDefault();
            event.stopImmediatePropagation();
        }
        // #endregion

        // #region 神秘滤镜

        public function applyFilter():void {
            var fliter:ColorMatrixFilter = new ColorMatrixFilter();
            fliter.adjustBrightness(0.1);
            fliter.adjustContrast(0.25);
            this.filter = fliter;
        }

        // #endregion
    }
}
