package {
    import Game.Debug;
    import Game.GameScene;
    import Menus.EndScene;
    import Menus.TitleMenu;
    import flash.events.KeyboardEvent;
    import starling.core.Starling;
    import starling.display.Image;
    import starling.display.Quad;
    import starling.display.Sprite;
    import starling.events.Event;
    import starling.filters.ColorMatrixFilter;
    import starling.textures.Texture;
    import starling.utils.AssetManager;
    import utils.ProgressBar;

    public class Root extends Sprite {

        private static var sAssets:AssetManager;
        public static var bg:ScrollingBackground;

        private var mActiveScene:Sprite;
        private var blackQuad:Array;
        public var titleMenu:TitleMenu;
        public var gameScene:GameScene;
        public var endScene:EndScene;
        public var scene:SceneController;
        public var debug:Debug;

        public function Root() {
            super();
        }

        public static function get assets():AssetManager {
            return sAssets;
        }

        public function start(param1:Texture, param2:AssetManager):void {
            var bgImage:Image;
            var progressBar:ProgressBar; // 对象类型：进度条
            var background:Texture = param1;
            var assets:AssetManager = param2;
            sAssets = assets;
            this.alpha = 0.9999;
            bgImage = new Image(background);
            addChild(bgImage);
            progressBar = new ProgressBar(512, 3);
            progressBar.x = (background.width - progressBar.width) / 2;
            progressBar.y = background.height * 0.55;
            addChild(progressBar);
            assets.loadQueue((function():* {
                var onProgress:Function = function(param1:Number):void {
                    var ratio:Number = param1;
                    progressBar.ratio = ratio;
                    if (ratio == 1) // 加载完成时
                    {
                        Starling.juggler.delayCall(function():void {
                            progressBar.removeFromParent(true);
                            removeChildAt(0);
                            LevelData.init();
                            bg = new ScrollingBackground();
                            addChild(bg);
                            scene = new SceneController()
                            titleMenu = new TitleMenu(scene);
                            gameScene = new GameScene(scene);
                            endScene = new EndScene(scene);
                            debug = new Debug(scene);
                            scene.init(titleMenu,gameScene, endScene,debug)
                            addChild(titleMenu);
                            addChild(gameScene);
                            addChild(endScene);
                            GS.init();
                            blackQuad = new Array();
                            var _quad1:Quad = new Quad(1024, 114, 0);
                            _quad1.alpha = 0.4;
                            addChild(_quad1);
                            blackQuad.push(_quad1);
                            var _quad2:Quad = new Quad(1024, 114, 0);
                            _quad2.y = 768 - _quad2.height;
                            _quad2.alpha = 0.4;
                            addChild(_quad2);
                            blackQuad.push(_quad2);
                            titleMenu.firstInit();
                            addChild(debug);
                            debug.init(gameScene, titleMenu);
                            titleMenu.addEventListener("start", on_title_start);
                            Starling.current.nativeStage.addEventListener("keyDown", on_key_down);
                            addEventListener("touch", on_blackQuad);
                        }, 0.15);
                    }
                }; // 声明函数对象
                return onProgress;
            })());
        }

        public function on_key_down(param1:KeyboardEvent):void {
            debug.on_key_down(param1.keyCode);
            switch (param1.keyCode) {
                case 27: // 对应Esc键
                    if (titleMenu.visible) {
                        if (titleMenu.optionsMenu.visible) {
                            titleMenu.optionsMenu.animateOut();
                            break;
                        }
                        titleMenu.on_menu(null);
                        break;
                    }
                    if (gameScene.visible)
                        gameScene.quit();
                    break;
                case 81: // Q 启用 Debug 模式
                    debug.startDebugMode();
                    break;
            }
            if (gameScene.visible) {
                switch (param1.keyCode) {
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
            param1.preventDefault();
            param1.stopImmediatePropagation();
        }

        public function applyFilter():void {
            var fliter:ColorMatrixFilter = new ColorMatrixFilter();
            fliter.adjustBrightness(0.1);
            fliter.adjustContrast(0.25);
            this.filter = fliter;
        }

        public function initTitleMenu():void {
            titleMenu.init();
            titleMenu.addEventListener("start", on_title_start);
        }

        public function deInitTitleMenu():void {
            titleMenu.deInit();
            titleMenu.removeEventListener("start", on_title_start);
        }

        public function on_title_start(param1:Event):void {
            initGameScene();
        }

        public function resumeGameScene():void {
            gameScene.animateIn();
        }

        public function initGameScene():void {
            gameScene.init();
            if (!gameScene.hasEventListener("menu"))
                gameScene.addEventListener("menu", on_menu);
            if (!gameScene.hasEventListener("next"))
                gameScene.addEventListener("next", on_next);
            if (!gameScene.hasEventListener("end"))
                gameScene.addEventListener("end", on_end);
            debug.init_game();
        }

        public function deInitGameScene():void {
            gameScene.deInit();
            gameScene.removeEventListener("menu", on_menu);
            gameScene.removeEventListener("next", on_next);
            gameScene.removeEventListener("end", on_end);
        }

        public function on_menu(param1:Event):void {
            titleMenu.init();
            titleMenu.animateIn();
        }

        public function on_next(param1:Event):void {
            titleMenu.init();
            titleMenu.animateIn();
            titleMenu.nextLevel();
        }

        public function on_end(param1:Event):void {
            endScene.init();
            endScene.addEventListener("done", on_end_done);
        }

        public function on_end_done(param1:Event):void {
            endScene.removeEventListener("done", on_end_done);
            endScene.deInit();
            titleMenu.initAfterEnd();
            GS.playMusic("bgm01");
        }

        public function on_blackQuad(_Event:Event):void {
            blackQuad[0].visible = blackQuad[1].visible = Globals.blackQuad;
        }
    }
}
