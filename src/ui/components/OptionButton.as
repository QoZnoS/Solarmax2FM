package ui.components {
    import flash.geom.Point;

    import starling.display.Image;
    import starling.display.Quad;
    import starling.display.Sprite;
    import starling.events.Touch;
    import starling.events.TouchEvent;
    import starling.text.TextField;
    import starling.utils.Align;
    import starling.display.BlendMode;

    public class OptionButton extends Sprite {
        public var quad:Quad;
        public var labelBG:Quad;
        public var label:TextField;
        public var down:Boolean;
        public var hitPoint:Point;
        public var buttonArray:Array;
        public var toggled:Boolean;

        public var labelArray:Array;

        /** 多项单选文字按钮
         * <p>注册方法： <code>this.addEventListener("clicked", 回调函数)</code>
         * <p>读取状态： <code>this.toggled</code>
         * @param text 按钮文字
         * @param color 字体颜色
         * @param buttonArray 包含同条目下全部按钮
         */
        public function OptionButton(text:String, color:uint, buttonArray:Array = null) {
            super();
            this.buttonArray = buttonArray;
            labelArray = [];
            label = new TextField(240, 40, text);
            label.format.setTo("downlink", 12, color);
            label.format.horizontalAlign = Align.LEFT;
            label.format.verticalAlign = Align.TOP;
            label.alpha = 0.7
            label.touchable = false;
            labelBG = new Quad(label.textBounds.width + 12, label.textBounds.height + 12, color);
            labelBG.x = -6;
            labelBG.y = -2;
            labelBG.alpha = 0;
            labelBG.touchable = false;
            quad = new Quad(labelBG.width + 4, labelBG.height + 4, 0xFF0000);
            quad.x = labelBG.x - 2;
            quad.y = labelBG.y - 2;
            quad.alpha = 0;
            addChild(quad);
            addChild(label);
            addChild(labelBG);
            hitPoint = new Point(0, 0);
            toggled = false;
            quad.addEventListener("touch", on_touch);
        }

        private function on_touch(touchEvent:TouchEvent):void {
            var touch:Touch = touchEvent.getTouch(this);
            if (!touch) {
                labelBG.alpha = toggled ? 0.2 : 0;
                down = false;
                return;
            }
            switch (touch.phase) {
                case "hover":
                    labelBG.alpha = 0.2;
                    break;
                case "began":
                    labelBG.alpha = 0.5;
                    down = true;
                    break;
                case "moved":
                    if (down && !hitTest(touch.getLocation(this, hitPoint))) {
                        labelBG.alpha = toggled ? 0.2 : 0;
                        down = false;
                    }
                    break;
                case "ended":
                    if (down) {
                        var shouldToggle:Boolean = buttonArray != null;
                        toggled = shouldToggle;
                        labelBG.alpha = shouldToggle ? 0.2 : 0;
                        if (buttonArray) {
                            for each (var _button:OptionButton in buttonArray) {
                                if (_button == this)
                                    continue;
                                _button.untoggle();
                            }
                        }
                        down = false;
                        dispatchEventWith("clicked");
                        break;
                    }
            }
        }

        public function toggle():void {
            toggled = true;
            labelBG.alpha = 0.2;
        }

        public function untoggle():void {
            toggled = false;
            labelBG.alpha = 0;
        }

        public function addLabel(label:TextField, size:Number, color:Number, x:Number, y:Number, hAlign:String = Align.LEFT):void {
            label.format.setTo("downlink", size, color);
            label.format.horizontalAlign = hAlign;
            label.format.verticalAlign = Align.TOP;
            label.x = x;
            label.y = y;
            label.alpha = 0.7;
            label.touchable = false;
            labelArray.push(label);
            addChild(label);
        }

        public function addImage(image:Image, scale:Number = 1):void {
            image.scaleX = image.scaleY = scale;
            image.x = 640;
            image.y = quad.height / 2 - 6;
            image.touchable = false;
            addChild(image);
        }
    }
}
