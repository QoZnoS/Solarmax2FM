// 鼠标悬停在操作方式上出现的文体提示框
package ui.components {
    import starling.display.Quad;
    import starling.display.Sprite;
    import starling.text.TextField;
    import starling.utils.Align;

    public class Tooltip extends Sprite {
        public var bg:Quad;
        public var arrow:Quad;
        public var title:TextField;
        public var content:TextField;

        public function Tooltip(type:int) {
            super();
            if (type == 0) {
                bg = new Quad(400, 100, 0);
                bg.alpha = 0.9;
                addChild(bg);
                title = new TextField(380, 40, "MULTI-TOUCH CONTROLS");
                title.format.setTo("downlink", 16, 0xFFFFFF)
                title.format.horizontalAlign = Align.LEFT;
                title.format.verticalAlign = Align.TOP;
                title.x = 10;
                title.y = 10;
                addChild(title);
                content = new TextField(380, 100, "");
                content.format.setTo("downlink", 10, 0xFFFFFF)
                content.text = "+ Hold LEFT CLICK on a planet and drag onto target\n\n+ SCROLL WHEEL to change move percentage";
            } else {
                bg = new Quad(400, 200, 0);
                bg.alpha = 0.9;
                addChild(bg);
                title = new TextField(380, 40, "TRADITIONAL CONTROLS");
                title.format.setTo("downlink", 16, 0xFFFFFF)
                title.format.horizontalAlign = Align.LEFT;
                title.format.verticalAlign = Align.TOP;
                title.x = 10;
                title.y = 10;
                addChild(title);
                content = new TextField(380, 200, "");
                content.format.setTo("downlink", 10, 0xFFFFFF)
                content.text = "+ LEFT CLICK on a planet to select it\n\n+ LEFT LICK and drag a box to select planets\n\n+ Hold SHIFT and LEFT CLICK to add or remove planets\n\n+ LEFT CLICK on empty space to deselect\n\n+ RIGHT CLICK on a planet to move ships\n\n+ SCROLL WHEEL to change move percentage";
            }
            content.format.horizontalAlign = Align.LEFT;
            content.format.verticalAlign = Align.TOP;
            content.x = 10;
            content.y = 38;
            addChild(content);
            this.pivotX = 10;
            this.pivotY = bg.height + 5;
            this.touchable = false;
        }
    }
}
