package Entity.FX {

    import UI.LayerFactory;

    public class BarrierFX implements IParticle {
        private var _p:BasicParticle;
        public function BarrierFX() {

        }

        public function get imageName():String {
            return "barrier_line";
        }
        // 接受参数: x,y,angle.color
        public function init(p:BasicParticle, config:Object):void {
            _p = p;
            p.pivotToCenter();
            p.x = config.x;
            p.y = config.y;
            p.scale = 0.75
            p.rotation = config.angle;
            p.color = config.color;
            LayerFactory.call(LayerFactory.ADD_FX)(_p.image)
        }

        public function update(dt:Number):void {

        }
    }
}
