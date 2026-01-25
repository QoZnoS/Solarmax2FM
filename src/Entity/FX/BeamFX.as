package Entity.FX {
    import Game.GameScene;
    import starling.display.Image;
    import Entity.GameEntity;
    import Entity.Node;
    import Entity.Node.NodeType;
    import UI.UIContainer;
    import utils.CalcTools;

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
        private var deepColor:Boolean;
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

        public function initBeam(gameScene:GameScene, x1:Number, y1:Number, x2:Number, y2:Number, node:Node):void {
            super.init(gameScene);
            this.x = x1;
            this.y = y1;
            this.color = Globals.teamColors[node.nodeData.team];
            if (Globals.teamColorEnhance[node.nodeData.team])
                this.color = CalcTools.scaleColorToMax(this.color);
            this.deepColor = Globals.teamDeepColors[node.nodeData.team];
            this.size = 0;
            var dx:Number = x2 - x1;
            var dy:Number = y2 - y1;
            var distance:Number = Math.sqrt(dx * dx + dy * dy);
            angle = Math.atan2(dy, dx);
            image.rotation = 0;
            image.x = x;
            image.y = y;
            image.width = distance;
            image.color = color;
            image.scaleY = 1;
            image.alpha = 0.75;
            image2.x = x;
            image2.y = y;
            image2.color = color;
            this.type = node.nodeData.type;
            state = STATE_GROW;
            switch (node.nodeData.type) { // 添加攻击塔特效贴图
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
                    image2.texture = Root.assets.getTexture(node.nodeData.type + "_shape");
                    image2.scaleX = image2.scaleY = node.moveState.image.scaleX;
                    image2.alpha = 0;
                    break;
            }
        }

        override public function deInit():void {
        }

        override public function update(dt:Number):void {
            image.rotation = 0;
            if (state == STATE_GROW) {
                size += dt * 20;
                if (size >= 1) {
                    size = 1;
                    state = STATE_SHRINK;
                }
            } else {
                size -= dt * 10;
                if (size <= 0) {
                    size = 0;
                    active = false;
                }
            }
            image.alpha = image2.alpha = size;
            image.scaleY = size * 0.5;
            switch (type) {
                case NodeType.TOWER:
                    image2.scaleX = image2.scaleY = size;
                    break;
                case NodeType.STARBASE:
                    image2.alpha = size;
                    break;
            }
            image.rotation = angle;
            UIContainer.entityLayer.addImage(image, foreground, deepColor);
            if (!deepColor)
                UIContainer.entityLayer.addImage(image2, foreground, deepColor);
        }
    }
}
