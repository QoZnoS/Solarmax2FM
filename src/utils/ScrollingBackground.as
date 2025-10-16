package utils {
    import starling.core.Starling;
    import starling.display.Image;
    import starling.display.Sprite;

    /**滚动背景 */
    public class ScrollingBackground extends Sprite {
        public var images:Array;

        public function ScrollingBackground() {
            var bg:Image = null;
            super();
            images = [];
            for (var i:int = 0; i < 4; i++) {
                bg = new Image(Root.assets.getTexture("bg0" + (i + 1).toString()));
                bg.x = i * 1024;
                bg.blendMode = "none";
                if (Globals.scaleFactor == 2 || Globals.scaleFactor == 1)
                    bg.scaleX = 1;
                else
                    bg.scaleX = 1.01;
                images.push(bg);
                addChild(bg);
            }
        }

        public function setX(x:Number):void {
            this.x = x;
            for each (var image:Image in images) {
                image.visible = false;
                if (-x > image.x - 1024 && -x < image.x + 1024)
                    image.visible = true;
            }
        }

        public function scrollTo(x:Number, tweenTime:Number = 2):void {
            Starling.juggler.removeTweens(this);
            Starling.juggler.tween(this, tweenTime, {"x": x,
                    "transition": "easeOut",
                    "onStart": scrollUpdate,
                    "onUpdate": scrollUpdate,
                    "onComplete": scrollUpdate});
        }

        public function scrollUpdate():void {
            for each (var image:Image in images) {
                image.visible = false;
                if (-x > image.x - 1024 && -x < image.x + 1024)
                    image.visible = true;
            }
        }
    }
}
