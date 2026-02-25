package utils {
    import starling.display.Quad;
    import starling.display.Sprite;
    import starling.text.TextField;
    import starling.utils.HAlign;
    import starling.utils.VAlign;

    import ui.components.OptionButton;

    public class Popup extends MoveableSprite {
        /** 信息提示版，确认后销毁自己，不需要回调 */
        public static const TYPE_INFORMATION:int = 0;
        /** 确认选项 */
        public static const TYPE_CHOOSE:int = 1;

        private const COLOR:uint = 0xFF9DBB;

        private var type:int = 0;
        private var acceptBtn:OptionButton;
        private var rejectBtn:OptionButton;
        private var labels:Vector.<TextField>;

        /**
         * <p>TYPE_INFORMATION title
         * <p>TYPE_CHOOSE info
         */
        public function Popup(type:int = TYPE_INFORMATION, ... prop) {
            this.type = type;
            setBox(560, 270);
            switch (type) {
                case TYPE_INFORMATION:
                    var title:TextField = new TextField(512, 40, prop[0], "Downlink18", -1, COLOR);
                    title.x = 256;
                    title.y = 249; //384-135
                    title.vAlign = title.hAlign = "center";
                    title.touchable = false;
                    addChild(title);
                    break;
                case TYPE_CHOOSE:
                    var info:TextField = new TextField(512, 200, prop[0], "Downlink18", -1, COLOR);
                    info.x = 256;
                    info.y = 180;
                    info.vAlign = info.hAlign = "center";
                    info.touchable = false;
                    addChild(info);
                    break;
                default:
                    break;
            }
            labels = new Vector.<TextField>();
            createBtn();
        }

        public function addLabel(text:String):void {
            var label:TextField = new TextField(512, 270, text, "Downlink12", -1, COLOR);
            label.x = 256;
            label.y = 289;
            label.vAlign = VAlign.TOP;
            label.hAlign = HAlign.LEFT;
            label.touchable = false;
            addChild(label);
            labels.push(label)
        }

        private function createBtn():void {
            switch (type) {
                case TYPE_INFORMATION:
                    acceptBtn = new OptionButton("ACCEPT", COLOR);
                    acceptBtn.x = 480;
                    acceptBtn.y = 491;
                    acceptBtn.quad.color = COLOR;
                    acceptBtn.quad.alpha = 0.2;
                    addChild(acceptBtn);
                    acceptBtn.addEventListener("clicked", on_accept_deinit)
                    break;
                case TYPE_CHOOSE:
                    acceptBtn = new OptionButton("ACCEPT", COLOR);
                    acceptBtn.x = 350;
                    acceptBtn.y = 480;
                    acceptBtn.quad.color = COLOR;
                    acceptBtn.quad.alpha = 0.2;
                    addChild(acceptBtn);
                    acceptBtn.addEventListener("clicked", on_accept_deinit)
                    rejectBtn = new OptionButton("REJECL", COLOR);
                    rejectBtn.x = 610;
                    rejectBtn.y = 480;
                    rejectBtn.quad.color = COLOR;
                    rejectBtn.quad.alpha = 0.2;
                    addChild(rejectBtn);
                    rejectBtn.addEventListener("clicked", on_accept_deinit)
                    break;
                default:
                    break;
            }
        }

        /**<code>accept.addEventListener("clicked", 回调函数)</code>*/
        public function get accept():OptionButton {
            return acceptBtn;
        }

        /**<code>reject.addEventListener("clicked", 回调函数)</code>*/
        public function get reject():OptionButton {
            return rejectBtn;
        }

        private function on_accept_deinit():void {
            this.parent.removeChild(this, true);
            dispose();
        }
    }
}
