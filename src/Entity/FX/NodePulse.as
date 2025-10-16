// type 0为扩散式 1为收缩式
package Entity.FX {
    import Game.GameScene;
    import Entity.Node;
    import starling.display.Image;
    import utils.GS;
    import Entity.GameEntity;
    import UI.UIContainer;

    public class NodePulse extends GameEntity {

        public static const TYPE_GROW:int = 0;
        public static const TYPE_SHRINK:int = 1;

        private var x:Number;
        private var y:Number;
        private var size:Number;
        private var maxSize:Number;
        private var delay:Number;
        private var rate:Number;
        private var image:Image;
        private var type:int;

        public function NodePulse() {
            super();
            image = new Image(Root.assets.getTexture("halo"));
            image.pivotX = image.pivotY = image.width * 0.5;
        }

        public function initPulse(gameScene:GameScene, node:Node, color:uint, type:int, delay:Number = 0):void {
            super.init(gameScene);
            this.x = node.nodeData.x;
            this.y = node.nodeData.y;
            this.type = type;
            this.delay = delay;
            switch (type) {
                case 0:
                    size = 0;
                    maxSize = node.nodeData.size * 2;
                    image.alpha = 1;
                    rate = node.nodeData.size;
                    break;
                case 1:
                    size = node.nodeData.size * 1.333;
                    maxSize = node.nodeData.size * 1.333;
                    image.alpha = 0;
                    rate = node.nodeData.size;
            }
            image.x = x;
            image.y = y;
            image.color = color;
            image.scaleX = image.scaleY = size;
            image.visible = true;
            UIContainer.entityLayer.addGlow(image);
        }

        override public function deInit():void {
            UIContainer.entityLayer.removeGlow(image);
        }

        override public function update(dt:Number):void {
            if (delay > 0) {
                image.visible = false;
                delay -= dt;
                if (delay <= 0) {
                    image.visible = true;
                    GS.playCapture(this.x);
                }
                return;
            }
            switch (type) {
                case 0:
                    size += dt * rate;
                    if (size > maxSize) {
                        size = maxSize;
                        active = false;
                    }
                    image.alpha = 1 - size / maxSize;
                    break;
                case 1:
                    size -= dt * rate;
                    if (size < 0) {
                        size = 0;
                        active = false;
                    }
                    image.alpha = 1 - size / maxSize;
            }
            image.scaleX = image.scaleY = size;
        }
    }
}
