// 文件: NodePulse_new.as
package Entity.FX {
    import UI.LayerFactory;
    import Entity.Node;
    import utils.GS;

    public class NodePulse implements IParticle {
        private var p:BasicParticle;
        private var layerCfg:Array;
        
        public static const TYPE_GROW:int = 0;
        public static const TYPE_SHRINK:int = 1;
        
        private var type:int;
        private var size:Number;
        private var maxSize:Number;
        private var delay:Number;
        private var rate:Number;
        private var deepColor:Boolean;
        private var targetX:Number;

        public function NodePulse() {
            layerCfg = [];
        }

        public function get imageName():String {
            return "halo";
        }

        // 接受参数: node, color, type, deepColor, delay
        public function init(p:BasicParticle, config:Array):void {
            this.p = p;
            var node:Node = config[0] as Node;
            p.imagePivotToCenter();
            this.targetX = node.nodeData.x;
            p.x = targetX;
            p.y = node.nodeData.y;
            p.color = config[1];
            this.type = config[2];
            this.deepColor = config[3];
            this.delay = config.length > 4 ? config[4] : 0;
            var nodeSize:Number = node.nodeData.size;
            switch (type) {
                case TYPE_GROW:
                    size = 0;
                    maxSize = nodeSize * 2;
                    p.alpha = 1;
                    rate = nodeSize;
                    break;
                case TYPE_SHRINK:
                    size = nodeSize * 1.333;
                    maxSize = size;
                    p.alpha = 0;
                    rate = nodeSize;
                    break;
            }
            p.scale = size;
            p.visible = true;
            layerCfg = [LayerFactory.ADD_GROW, deepColor];
            p.addToLayer();
            
        }

        public function update(dt:Number):void {
            if (delay > 0) {
                p.visible = false;
                delay -= dt;
                if (delay <= 0) {
                    p.visible = true;
                    GS.playCapture(targetX);
                }
                return;
            }
            switch (type) {
                case TYPE_GROW:
                    size += dt * rate;
                    if (size > maxSize) {
                        size = maxSize;
                        p.active = false;
                    }
                    p.alpha = 1 - size / maxSize;
                    break;
                case TYPE_SHRINK:
                    size -= dt * rate;
                    if (size < 0) {
                        size = 0;
                        p.active = false;
                    }
                    p.alpha = 1 - size / maxSize;
                    break;
            }
            p.scale = size;
            if (!p.active)
                p.layerCall(LayerFactory.REMOVE_GROW);
        }
        
        public function get layerConfig():Array {
            return layerCfg;
        }
    }
}
