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

        public function EditorCenter(){
            nodeContainer = new NodeContainer()
            uiContainer = new UIContainer()
            console = new Console()
            data = new Data()
        }

        public function init():void{

        }

        public function deinit():void{

        }
    }
}