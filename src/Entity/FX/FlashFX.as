package Entity.FX {
    import Game.GameScene;
    import starling.display.Image;
    import Entity.GameEntity;
    import UI.UIContainer;

    public class FlashFX extends GameEntity {

        public static const STATE_GROW:int = 0;
        public static const STATE_SHRINK:int = 1;

        private var x:Number;
        private var y:Number;
        private var size:Number;
        private var color:uint;
        private var image:Image;
        private var foreground:Boolean;
        private var state:int;

        public function FlashFX() {
            super();
            image = new Image(Root.assets.getTexture("ship_flare"));
            image.pivotX = image.width * 0.5;
            image.pivotY = image.height * 0.5;
        }

        public function initExplosion(_GameScene:GameScene, _x:Number, _y:Number, _Color:uint, _foreground:Boolean):void {
            super.init(_GameScene);
            this.x = _x;
            this.y = _y;
            this.color = _Color;
            this.foreground = _foreground;
            this.size = 0;
            image.x = _x;
            image.y = _y;
            image.color = _Color;
            image.scaleY = 0;
            image.scaleX = 0;
            image.alpha = 1;
            state = 0;
        }

        override public function deInit():void {
        }

        override public function update(_dt:Number):void {
            if (state == 0) {
                size += _dt * 10;
                if (size >= 1) {
                    size = 1;
                    state = 1;
                }
            } else {
                size -= _dt * 5;
                if (size <= 0) {
                    size = 0;
                    active = false;
                }
            }
            image.scaleX = image.scaleY = size;
            UIContainer.entityLayer.addImage(image, foreground);
        }
    }
}
