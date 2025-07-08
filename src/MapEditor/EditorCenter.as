package MapEditor
{
    import starling.display.Sprite;
    import UI.UIContainer;

    /**编辑器中心 */
    public class EditorCenter extends Sprite {
        
        private var nodeContainer:NodeContainer;
        private var uiContainer:UIContainer;
        private var console:Console;
        public var data:Data;
        
        public var scene:SceneController;

        public function EditorCenter(_scene:SceneController){
            nodeContainer = new NodeContainer()
            console = new Console()
            data = new Data()
            this.scene = _scene;
        }

        public function init():void{

        }

        public function deinit():void{

        }
    }
}