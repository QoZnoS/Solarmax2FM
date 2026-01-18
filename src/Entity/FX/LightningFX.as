package Entity.FX {
    import Game.GameScene;
    import starling.display.Image;
    import Entity.GameEntity;
    import Entity.Node;
    import Entity.Node.NodeType;
    import UI.UIContainer;

    public class LightningFX extends GameEntity {

        public static const STATE_GROW:int = 0;
        public static const STATE_SHRINK:int = 1;

        private var x:Number;
        private var y:Number;
        private var alpha:Number;
        private var angle:Number;
        private var color:uint;
        private var image:Image; // 这是闪电
        private var foreground:Boolean;
        private var deepColor:Boolean;
        private var state:int;

        public function LightningFX(imageID:int) {
            super();
            image = new Image(Root.assets.getTexture("lightning0" + imageID.toString()));
            image.pivotY = image.height * 0.5;
            //image.adjustVertices();
            foreground = true;
        }

        public function initLightning(gameScene:GameScene, x1:Number, y1:Number, x2:Number, y2:Number, color:uint, node:Node, deepColor:Boolean):void {
            super.init(gameScene);
            this.x = x1;
            this.y = y1;
            this.color = color;
            this.deepColor = deepColor;
            this.alpha = 0;
            var dx:Number = x2 - x1;
            var dy:Number = y2 - y1;
            var distance:Number = Math.sqrt(dx * dx + dy * dy);
            angle = Math.atan2(dy, dx);
            image.rotation = 0;
            image.width = distance;
            image.rotation = angle;
            image.x = x;
            image.y = y;
            image.color = color;
            image.alpha = alpha;
            state = STATE_GROW;
        }

        override public function deInit():void {
        }

        override public function update(dt:Number):void {
            if (state == STATE_GROW) {
                alpha += dt * 20;
                if (alpha >= 1) {
                    alpha = 1;
                    state = STATE_SHRINK;
                }
            } else {
                alpha -= dt * 5;
                if (alpha <= 0) {
                    alpha = 0;
                    active = false;
                }
            }
            image.alpha = alpha;
            UIContainer.entityLayer.addImage(image, foreground, deepColor);
        }
    }
}
