package Entity.FX {
    import Game.GameScene;
    import starling.display.Image;
    import Entity.GameEntity;
    import UI.UIContainer;

    public class ExplodeFX extends GameEntity {

        public static const STATE_GROW:int = 0;
        public static const STATE_SHRINK:int = 1;

        private var x:Number;
        private var y:Number;
        private var size:Number;
        private var color:uint;
        private var image:Image;
        private var foreground:Boolean;
        private var deepColor:Boolean;
        private var state:int;

        public function ExplodeFX() {
            super();
            image = new Image(Root.assets.getTexture("ship_pulse"));
            image.pivotX = image.pivotY = image.width * 0.5;
        }

        public function initExplosion(gameScene:GameScene, x:Number, y:Number, color:uint, foreground:Boolean, deepColor:Boolean):void {
            super.init(gameScene);
            this.x = x;
            this.y = y;
            this.color = color;
            this.foreground = foreground;
            this.deepColor = deepColor;
            this.size = 0;
            image.x = x;
            image.y = y;
            image.color = color;
            image.scaleY = 0;
            image.scaleX = 0;
            image.alpha = 0.5;
            state = STATE_GROW;
        }

        override public function deInit():void {
        }

        override public function update(dt:Number):void {
            if (state == STATE_GROW) {
                size += dt;
                image.scaleX = image.scaleY = size;
                if (size >= 0.5)
                    state = STATE_SHRINK;
            } else {
                size += dt;
                image.scaleX = image.scaleY = size;
                image.alpha -= dt;
                if (image.alpha <= 0) {
                    image.alpha = 0;
                    active = false;
                }
            }
            UIContainer.entityLayer.addImage(image, foreground, deepColor);
        }
    }
}
