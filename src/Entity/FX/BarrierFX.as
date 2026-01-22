package Entity.FX {
    import Game.GameScene;
    import starling.display.Image;
    import Entity.GameEntity;
    import UI.LayerFactory;

    public class BarrierFX extends GameEntity {

        private var image:Image;

        public function BarrierFX() {
            super();
            image = new Image(Root.assets.getTexture("barrier_line"));
            image.pivotX = image.width * 0.5;
            image.pivotY = image.height * 0.5;
        }

        public function initBarrier(gameScene:GameScene, x:Number, y:Number, angle:Number, color:uint):void {
            super.init(gameScene);
            image.x = x;
            image.y = y;
            image.scaleY = 0.75;
            image.scaleX = 0.75;
            image.rotation = angle;
            image.color = color;
            LayerFactory.call(LayerFactory.ADD_FX)(image);
        }
    }
}
