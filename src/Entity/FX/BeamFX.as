package Entity.FX {
    import Game.GameScene;
    import starling.display.Image;
    import Entity.GameEntity;
    import Entity.Node;
    import Entity.Node.NodeType;

    public class BeamFX extends GameEntity {

        public static const STATE_GROW:int = 0;
        public static const STATE_SHRINK:int = 1;

        private var x:Number;
        private var y:Number;
        private var size:Number;
        private var angle:Number;
        private var color:uint;
        private var image:Image; // 这是射线
        private var image2:Image; // 这是攻击塔的特效
        private var foreground:Boolean;
        private var type:String;
        private var state:int;

        public function BeamFX() {
            super();
            image = new Image(Root.assets.getTexture("quad_16x4glow"));
            image.pivotY = image.height * 0.5;
            image.adjustVertices();
            image2 = new Image(Root.assets.getTexture("tower_shape"));
            image2.pivotX = image2.pivotY = image2.width * 0.5;
            foreground = true;
        }

        public function initBeam(_GameScene:GameScene, _x1:Number, _y1:Number, _x2:Number, _y2:Number, _Color:uint, _node:Node):void {
            super.init(_GameScene);
            this.x = _x1;
            this.y = _y1;
            this.color = _Color;
            this.size = 0;
            var _dx:Number = _x2 - _x1;
            var _dy:Number = _y2 - _y1;
            var _Distance:Number = Math.sqrt(_dx * _dx + _dy * _dy);
            angle = Math.atan2(_dy, _dx);
            image.rotation = 0;
            image.x = x;
            image.y = y;
            image.width = _Distance;
            image.color = _Color;
            image.scaleY = 1;
            image.alpha = 0.75;
            image2.x = x;
            image2.y = y;
            image2.color = _Color;
            this.type = _node.nodeData.type;
            state = 0;
            switch (_node.nodeData.type) // 添加攻击塔特效贴图
            {
                case NodeType.TOWER:
                    image2.texture = Root.assets.getTexture("tower_shape");
                    image2.scaleX = image2.scaleY = 0;
                    image2.alpha = 1;
                    break;
                case NodeType.STARBASE:
                    image2.texture = Root.assets.getTexture("starbase_laser");
                    image2.scaleX = image2.scaleY = 1;
                    image2.alpha = 0;
                    break;
                default:
                    image2.texture = Root.assets.getTexture(_node.nodeData.type + "_shape");
                    image2.scaleX = image2.scaleY = _node.moveState.image.scaleX;
                    image2.alpha = 0;
                    break;
            }
        }

        override public function deInit():void {
        }

        override public function update(_dt:Number):void {
            image.rotation = 0;
            if (state == 0) {
                size += _dt * 20;
                if (size >= 1) {
                    size = 1;
                    state = 1;
                }
            } else {
                size -= _dt * 10;
                if (size <= 0) {
                    size = 0;
                    active = false;
                }
            }
            image.alpha = image2.alpha = size;
            image.scaleY = size * 0.5;
            switch (type) {
                case 4:
                    image2.scaleX = image2.scaleY = size;
                    break;
                case 6:
                    image2.alpha = size;
                    break;
            }
            image.rotation = angle;
            entityL.addImage(image, foreground);
            if (image.color != 0)
                entityL.addImage(image2, foreground);
        }
    }
}
