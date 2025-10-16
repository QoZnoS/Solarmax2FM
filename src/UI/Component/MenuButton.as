package UI.Component {
    import flash.geom.Point;
    import starling.display.Image;
    import starling.display.Quad;
    import starling.display.Sprite;
    import starling.events.Touch;
    import starling.events.TouchEvent;
    import utils.GS;

    public class MenuButton extends Sprite {
        public var quad:Quad;
        public var image:Image;
        public var down:Boolean;
        public var hitPoint:Point;
        
        /** 基础控制按钮
         * <p>注册方法： <code>btn.addEventListener("clicked", 回调函数)</code>
         * @param texture 按钮贴图
         */
        public function MenuButton(texture:String, size:Number = 1) {
            super();
            image = new Image(Root.assets.getTexture(texture));
            image.color = 16755370;
            addChild(image);
            quad = new Quad(image.width + 20, image.height + 20, 16711680);
            addChild(quad);
            hitPoint = new Point(0, 0);
            setImage(texture, size);
        }

        public function setImage(texture:String, size:Number = 1):void {
            image.texture = Root.assets.getTexture(texture);
            image.readjustSize();
            image.width = image.texture.width;
            image.height = image.texture.height;
            image.scaleX = image.scaleY = size;
            image.alpha = 0.3;
            quad.width = image.width + 20;
            quad.height = image.height + 20;
            quad.x = -10;
            quad.y = -10;
            quad.alpha = 0;
        }

        public function init():void {
            image.alpha = 0.3;
            addEventListener("touch", on_touch);
        }

        public function deInit():void {
            removeEventListener("touch", on_touch);
        }

        public function on_touch(touchEvent:TouchEvent):void {
            var touch:Touch = touchEvent.getTouch(this);
            if (!touch) {
                image.alpha = 0.3;
                return;
            }
            switch (touch.phase) {
                case "hover":
                    image.alpha = down ? image.alpha : 0.5;
                    break;
                case "began":
                    image.alpha = 0.8;
                    down = true;
                    break;
                case "moved":
                    if (down && !hitTest(touch.getLocation(this, hitPoint))) {
                        image.alpha = 0.3;
                        down = false;
                    }
                    break;
                case "ended":
                    if (down) {
                        dispatchEventWith("clicked");
                        image.alpha = 0.5;
                        down = false;
                        GS.playClick();
                        break;
                    }
            }
        }

        public function set color(value:uint):void{
            image.color = value;
        }
    }
}
