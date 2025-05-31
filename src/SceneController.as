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

        public function initGameScene():void{

        }

        public function deInitGameScene():void{

        }

        public function initTitleMenu():void{

        }

        public function deInitTitleMenu():void{

        }

        public function initEndScene():void{

        }

        public function deInitEndScene():void{

        }

    }
}