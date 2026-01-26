package Entity.FX {

    import UI.LayerFactory;

    public class BarrierFX implements IParticle {
        private var p:BasicParticle;

        public function BarrierFX() {
        }

        public function get imageName():String {
            return "barrier_line";
        }

        // 接受参数: x,y,angle.color
        public function init(p:BasicParticle, config:Array):void {
            this.p = p;
            p.texturePivotToCenter();
            p.x = config[0];
            p.y = config[1];
            p.scale = 0.75;
            p.rotation = config[2];
            p.color = config[3];
            p.addToLayer();
            p.active = false;
        }

        public function update(dt:Number):void {
        }
        private var config:Array = [LayerFactory.ADD_FX];
        public function get layerConfig():Array {
            return config;
        }
    }
}
