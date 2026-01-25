package Entity.FX {
    import Game.GameScene;
    import starling.display.Image;
    import Entity.GameEntity;
    import UI.LayerFactory;

    public class WarpFX extends GameEntity {

        public static const STATE_GROW:int = 0;
        public static const STATE_SHRINK:int = 1;

        private var x:Number;
        private var y:Number;
        private var prevX:Number;
        private var prevY:Number;
        private var size:Number;
        private var color:uint;
        private var image:Image;
        private var foreground:Boolean;
        private var deepColor:Boolean;
        private var state:int;

        public function WarpFX(){
            super();
            image = new Image(Root.assets.getTexture("warp_glare"));
            image.pivotX = image.width * 0.5;
            image.pivotY = image.height * 0.5;
        }

        public function initWarp(gameScene:GameScene, x:Number, y:Number, prevX:Number, prevY:Number, color:uint, foreground:Boolean):void {
            super.init(gameScene);
            this.x = x;
            this.y = y;
            this.prevX = prevX;
            this.prevY = prevY;
            this.color = color;
            this.foreground = foreground;
            this.deepColor = deepColor;
            this.size = 0;
            image.x = x;
            image.y = y;
            image.color = color;
            image.scaleY = 0;
            image.scaleX = 0;
            image.alpha = 1;
            state = 0;
        }

        override public function deInit():void {
        }

        override public function update(dt:Number):void {
            if (state == 0) {
                size += dt * 8;
                if (size >= 1) {
                    size = 1;
                    state = 1;
                }
            } else {
                size -= dt * 3;
                if (size <= 0) {
                    size = 0;
                    active = false;
                }
            }
            image.scaleX = image.scaleY = size;
            image.alpha = 1;
            var dx:Number = prevX - x;
            var dy:Number = prevY - y;
            var angle:Number = Math.atan2(dy, dx);
            var distance:Number = Math.sqrt(dx * dx + dy * dy);
            image.rotation = 0;
            image.x = x + Math.cos(angle) * distance * 0.5;
            image.y = y + Math.sin(angle) * distance * 0.5;
            image.width = distance;
            image.scaleY *= 0.5;
            image.alpha = 0.25;
            image.rotation = angle;
            LayerFactory.call(LayerFactory.ADD_IMAGE)(image, foreground, deepColor);
        }
    }
}
