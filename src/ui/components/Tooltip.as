// 鼠标悬停在操作方式上出现的文体提示框
package ui.components {
    import starling.display.Quad;
    import starling.display.Sprite;
    import starling.text.TextField;
    import starling.utils.Align;
    import i18n.I18n;
    import starling.display.BlendMode;

    public class Tooltip extends Sprite {
        private const COLOR:uint = 0xFFAAAA;
        public var bg:Quad;
        public var arrow:Quad;
        public var title:TextField;
        public var content:TextField;

        public function Tooltip(type:int) {
            super();
            if (type == 0) {
                bg = new Quad(400, 100, COLOR);
                bg.alpha = 0.9;
                arrow = new Quad(396, 96, 0x000000);
                arrow.alpha = 0.45;
                addChild(bg);
                addChild(arrow);
                title = new TextField(380, 40, I18n._("tooltip.multitouch.title"));
                title.format.setTo("downlink", 16, 0xFFFFFF)
                title.format.horizontalAlign = Align.LEFT;
                title.format.verticalAlign = Align.TOP;
                title.x = 10;
                title.y = 10;
                addChild(title);
                content = new TextField(380, 100, "");
                content.format.setTo("downlink", 10, 0xFFFFFF)
                content.text = I18n._("tooltip.multitouch.content");
            } else {
                bg = new Quad(400, 200, COLOR);
                bg.alpha = 0.9;
                arrow = new Quad(396, 196, 0x000000);
                arrow.alpha = 0.45;
                addChild(bg);
                addChild(arrow);
                title = new TextField(380, 40, I18n._("tooltip.traditional.title"));
                title.format.setTo("downlink", 16, 0xFFFFFF)
                title.format.horizontalAlign = Align.LEFT;
                title.format.verticalAlign = Align.TOP;
                title.x = 10;
                title.y = 10;
                addChild(title);
                content = new TextField(380, 200, "");
                content.format.setTo("downlink", 10, 0xFFFFFF)
                content.text = I18n._("tooltip.traditional.content");
            }
            content.format.horizontalAlign = Align.LEFT;
            content.format.verticalAlign = Align.TOP;
            content.x = 10;
            content.y = 38;
            addChild(content);
            bg.blendMode = BlendMode.ADD;
            this.pivotX = 10;
            this.pivotY = bg.height + 5;
            this.touchable = false;
        }
    }
}
