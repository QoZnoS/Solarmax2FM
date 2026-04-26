// type 0为扩散式 1为收缩式
package core.fx {
    import starling.display.MeshBatch;

    import ui.layers.LayerFactory;

    import utils.Drawer;

    public class SelectFade implements IParticle {

        public static const TYPE_GROW:int = 0;
        public static const TYPE_SHRINK:int = 1;

        private var x:Number;
        private var y:Number;
        private var size:Number;
        private var alpha:Number;
        private var color:uint;
        private var type:int;
        private var deepColor:Boolean;
        private var p:BasicParticle;

        public function SelectFade() {
        }

        // 接受参数: x, y, size, color, type
        public function init(p:BasicParticle, config:Array):void {
            this.p = p;
            this.x = config[0];
            this.y = config[1];
            this.color = config[2];
            this.size = config[3];
            this.type = config[4];
            alpha = 1;
        }

        public function update(dt:Number):void {
            if (type == 0)
                size += dt * 0.2;
            else
                size -= dt * 0.2;
            alpha -= dt * 4;
            if (alpha <= 0) {
                alpha = 0;
                p.active = false;
            }
            var radius:Number = 150 * size - 4;
            var voidR:Number = Math.max(0, radius - 3);
            Drawer.drawCircle(LayerFactory.getLayer(LayerFactory.BEHAVIOR) as MeshBatch, x, y, color, radius, voidR, false, alpha);
        }

        public function get imageName():String {
            return "halo";
        }

        public function get layerConfig():Array {
            throw new Error("Method not implemented.");
        }
    }
}
