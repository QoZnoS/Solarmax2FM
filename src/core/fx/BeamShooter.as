package core.fx {
    import core.entities.Node;
    import core.node.NodeType;

    import managers.Globals;

    import ui.layers.LayerFactory;

    import utils.CalcTools;

    public class BeamShooter implements IParticle {
        private var p:BasicParticle;
        private var layerCfg:Array;

        private static const STATE_GROW:int = 0;
        private static const STATE_SHRINK:int = 1;

        private var type:String;
        private var size:Number;
        private var color:uint;
        private var deepColor:Boolean;
        private var foreground:Boolean;
        private var state:int;

        public function BeamShooter() {
            layerCfg = [LayerFactory.ADD_IMAGE];
        }

        public function get imageName():String {
            // 默认纹理，实际纹理在init中根据类型设置
            return "tower_shape";
        }

        // 接受参数: node
        public function init(p:BasicParticle, config:Array):void {
            this.p = p;
            var node:Node = config[0] as Node;
            var x:Number = node.nodeData.x;
            var y:Number = node.nodeData.y;
            p.imagePivotToCenter();
            p.x = x;
            p.y = y;
            this.color = Globals.teamColors[node.nodeData.team];
            if (Globals.teamColorEnhances[node.nodeData.team])
                this.color = CalcTools.scaleColorToMax(this.color);
            this.deepColor = Globals.teamDeepColors[node.nodeData.team];
            this.foreground = true;
            this.type = node.nodeData.type;
            this.size = 0;
            this.state = STATE_GROW;
            p.color = color;
            p.alpha = 0;
            switch (type) {
                case NodeType.TOWER:
                    p.texture = "tower_shape";
                    p.scale = 0;
                    break;
                case NodeType.STARBASE:
                    p.texture = "starbase_laser";
                    p.scale = 1;
                    break;
                default:
                    p.texture = node.nodeData.type + "_shape";
                    p.scale = node.moveState.image.scaleX;
                    break;
            }
            layerCfg.length = 1;
            layerCfg.push(foreground, deepColor);
            p.addToLayer();
        }

        public function update(dt:Number):void {
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
                    p.active = false;
                    return;
                }
            }
            p.alpha = size;
            if (type == NodeType.TOWER)
                p.scale = size;
        }

        public function get layerConfig():Array {
            return layerCfg;
        }
    }
}
