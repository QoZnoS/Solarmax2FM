package utils
{
    import starling.display.Sprite;
    import starling.display.Quad;
    import UI.Component.OptionButton;
    import starling.text.TextField;
    import starling.utils.VAlign;
    import starling.utils.HAlign;

    public class Popup extends Sprite{

        /** 信息提示版，确认后销毁自己，不需要回调 */
        public static const TYPE_INFORMATION:int = 0;
        /** 确认选项 */
        public static const TYPE_CHOOSE:int = 1;

        private const COLOR:uint = 0xFF9DBB;

        private var type:int = 0;

        private var bg:Quad;
        private var cover:Quad;
        private var acceptBtn:OptionButton;
        private var rejectBtn:OptionButton;
        private var title:TextField;
        private var labels:Vector.<TextField>;

        public function Popup(title:String, type:int = TYPE_INFORMATION){
            this.type = type;
            cover = new Quad(1024,768);
            cover.alpha = 0;
            bg = new Quad(560,270,0x000000);
            bg.alpha = 0.4;
            bg.x = 512;
            bg.y = 384;
            bg.pivotX = 280;
            bg.pivotY = 135;
            bg.touchable = false;
            addChild(cover);
            addChild(bg);
            this.title = new TextField(512,40,title,"Downlink18",-1, COLOR);
            this.title.x = 256;
            this.title.y = 249;//384-135
            this.title.vAlign = this.title.hAlign = "center";
            addChild(this.title);
            labels = new Vector.<TextField>();
            createBtn();
        }

        public function addLabel(text:String):void{
            var label:TextField = new TextField(512, 270, text, "Downlink12", -1, COLOR);
            label.x = 256;
            label.y = 289;
            label.vAlign = VAlign.TOP;
            label.hAlign = HAlign.LEFT;
            label.touchable = false;
            addChild(label);
            labels.push(label)
        }

        private function createBtn():void{
            switch(type)
            {
                case TYPE_INFORMATION:
                    acceptBtn = new OptionButton("ACCEPT", COLOR);
                    acceptBtn.x = 480;
                    acceptBtn.y = 491;
                    acceptBtn.quad.color = COLOR;
                    acceptBtn.quad.alpha = 0.2;
                    addChild(acceptBtn);
                    acceptBtn.addEventListener("clicked", on_accept_deinit)
                    break;
                default:
                    break;
            }
        }

        /**<code>accept.addEventListener("clicked", 回调函数)</code>*/
        public function get accept():OptionButton{
            return acceptBtn;
        }

        /**<code>reject.addEventListener("clicked", 回调函数)</code>*/
        public function get reject():OptionButton{
            return rejectBtn;
        }

        private function on_accept_deinit():void{
            this.parent.removeChild(this, true);
        }
    }
}