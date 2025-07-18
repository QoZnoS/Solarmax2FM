// type 0为扩散式 1为收缩式
package Entity.FX {
    import Game.GameScene;
    import Entity.Node;
    import starling.display.Image;
    import utils.GS;
    import Entity.GameEntity;

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

        public function initPulse(_GameScene:GameScene, _Node:Node, _Color:uint, _type:int, _delay:Number = 0):void {
            super.init(_GameScene);
            this.x = _Node.x;
            this.y = _Node.y;
            this.type = _type;
            this.delay = _delay;
            switch (_type) {
                case 0:
                    size = 0;
                    maxSize = _Node.size * 2;
                    image.alpha = 1;
                    rate = _Node.size;
                    break;
                case 1:
                    size = _Node.size * 1.333;
                    maxSize = _Node.size * 1.333;
                    image.alpha = 0;
                    rate = _Node.size;
            }
            image.x = x;
            image.y = y;
            image.color = _Color;
            image.scaleX = image.scaleY = size;
            image.visible = true;
            if (image.color == 0)
                _GameScene.nodeGlowLayer2.addChild(image);
            else
                _GameScene.nodeGlowLayer.addChild(image);
        }

        override public function deInit():void {
            if (image.color == 0)
                game.nodeGlowLayer2.removeChild(image);
            else
                game.nodeGlowLayer.removeChild(image);
        }

        override public function update(_dt:Number):void {
            if (delay > 0) {
                image.visible = false;
                delay -= _dt;
                if (delay <= 0) {
                    image.visible = true;
                    GS.playCapture(this.x);
                }
                return;
            }
            switch (type) {
                case 0:
                    size += _dt * rate;
                    if (size > maxSize) {
                        size = maxSize;
                        active = false;
                    }
                    image.alpha = 1 - size / maxSize;
                    break;
                case 1:
                    size -= _dt * rate;
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
