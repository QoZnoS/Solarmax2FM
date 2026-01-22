package Entity.FX {
    import Game.GameScene;
    import starling.display.Image;
    import Entity.GameEntity;
    import UI.LayerFactory;

    public class FlashFX extends GameEntity {

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

        public function FlashFX() {
            super();
            image = new Image(Root.assets.getTexture("ship_flare"));
            image.pivotX = image.width * 0.5;
            image.pivotY = image.height * 0.5;
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
            image.alpha = 1;
            state = STATE_GROW;
        }

        override public function deInit():void {
        }

        override public function update(dt:Number):void {
            if (state == STATE_GROW) {
                size += dt * 10;
                if (size >= 1) {
                    size = 1;
                    state = STATE_SHRINK;
                }
            } else {
                size -= dt * 5;
                if (size <= 0) {
                    size = 0;
                    active = false;
                }
            }
            image.scaleX = image.scaleY = size;
            LayerFactory.call(LayerFactory.ADD_IMAGE)(image, foreground, deepColor);
        }
    }
}
