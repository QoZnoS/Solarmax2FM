package
{
    import Menus.TitleMenu;
    import Game.GameScene;
    import Menus.EndScene;
    import Game.Debug;

    public class SceneController{
        public var titleMenu:TitleMenu;
        public var gameScene:GameScene;
        public var endScene:EndScene;
        public var debug:Debug;

        public function SceneController(){
            super();
        }

        public function init(_t:TitleMenu, _g:GameScene, _e:EndScene, _d:Debug):void{
            titleMenu = _t;
            gameScene = _g;
            endScene = _e;
            debug = _d;
        }
        // #region 私有方法，界面载入载出
        private function initGameScene():void{
            gameScene.init();
        }

        private function deInitGameScene():void{
            gameScene.deInit()
        }
        /**
         * 加载标题界面
         * @param type 0为首次加载，1为通关后加载
         */
        private function initTitleMenu(type:int = -1):void{
            switch(type)
            {
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

        private function deInitTitleMenu():void{
            titleMenu.deInit()
        }

        private function initEndScene():void{
            endScene.init()
        }

        private function deInitEndScene():void{
            endScene.deInit()
        }
        // #endregion

        // #region 切换界面

        /**
         * 游玩关卡
         */
        public function playMap():void{
            initGameScene();
            debug.init_game();
        }

        /**
         * 编辑关卡
         */
        public function editorMap():void{

        }

        /**
         * 退出到标题界面
         * @param type 0为直接退出关卡，1为从关卡退出且转到下一关，2为从退出动画进入标题界面
         */
        public function exit2TitleMenu(type:int = -1):void{
            switch(type)
            {
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
        public function playEndScene():void{
            initEndScene();
        }
        // #endregion
    }
}