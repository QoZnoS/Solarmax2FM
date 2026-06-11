// 鼠标悬停在操作方式上出现的文体提示框
package ui.components {
    import starling.display.Quad;
    import starling.display.Sprite;
    import starling.text.TextField;
    import starling.utils.Align;
    import i18n.I18n;
    import starling.display.BlendMode;
    import flash.text.TextFormat;

    public class Tooltip extends Sprite {
        private const COLOR:uint = 0xFFAAAA;
        private var bg:Quad;
        private var arrow:Quad;
        private var _title:TextField;
        private var _content:TextField;
        private static var _measureTF:flash.text.TextField;

        public function Tooltip() {
            super();
            bg = new Quad(400, 100, COLOR);
            bg.alpha = 0.9;
            arrow = new Quad(396, 96, 0x000000);
            arrow.alpha = 0.45;
            addChild(bg);
            addChild(arrow);
            _title = new TextField(800, 80, I18n._("tooltip.multitouch.title"));
            _title.format.setTo("downlink", 16, 0xFFFFFF);
            _title.format.horizontalAlign = Align.LEFT;
            _title.format.verticalAlign = Align.TOP;
            _title.x = 10;
            _title.y = 10;
            addChild(_title);
            _content = new TextField(800, 200, "");
            _content.format.setTo("downlink", 10, 0xFFFFFF);
            _content.format.horizontalAlign = Align.LEFT;
            _content.format.verticalAlign = Align.TOP;
            _content.x = 10;
            _content.y = 38;
            _content.text = I18n._("tooltip.multitouch.content");
            addChild(_content);
            bg.blendMode = BlendMode.ADD;
            this.touchable = false;

            updateQuad();
        }

        public function set title(str:String):void {
            _title.text = str;
        }

        public function set content(str:String):void {
            _content.text = str;
            updateQuad();
        }

        private function updateQuad():void {
            if (!_measureTF) {
                _measureTF = new flash.text.TextField();
                _measureTF.wordWrap = true;
                _measureTF.multiline = true;
            }
            var fmt:flash.text.TextFormat = new flash.text.TextFormat("_sans", 10);
            _measureTF.defaultTextFormat = fmt;
            _measureTF.width = 380;
            _measureTF.text = _content.text;

            var contentBottom:Number = _content.y + _measureTF.textHeight;
            var newHeight:Number = contentBottom + 20;
            bg.width = 400;
            bg.height = newHeight;
            arrow.width = 396;
            arrow.height = newHeight - 4;
            this.pivotX = 10;
            this.pivotY = bg.height + 5;
        }
    }
}
