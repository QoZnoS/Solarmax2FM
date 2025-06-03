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
        // #region 界面载入载出
        public function initGameScene():void{

        }

        public function deInitGameScene():void{

        }
        /**
         * 加载标题界面
         * @param type 0为首次加载，1为通关后加载
         */
        public function initTitleMenu(type:int = -1):void{
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

        public function deInitTitleMenu():void{

        }

        public function initEndScene():void{

        }

        public function deInitEndScene():void{

        }
        // #endregion

        // #region 切换界面

        /**
         * 游玩关卡
         */
        public function playMap():void{
            
        }

        /**
         * 编辑关卡
         */
        public function editorMap():void{

        }

        /**
         * 退出到标题界面
         * @param type 0为从关卡退出
         */
        public function exit2TitleMenu(type:int = -1):void{
            switch(type)
            {
                case 0:
                    titleMenu.animateIn()
                default:
                    initTitleMenu()
                    break;
            }
        }

        /**
         * 播放通关动画
         */
        public function playEndScene():void{

        }
        // #endregion
    }
}