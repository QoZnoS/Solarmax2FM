package Entity.FX {

    import UI.LayerFactory;

    public class BarrierFX2 implements IParticle {
        private var _p:BasicParticle;
        public function BarrierFX2() {

        }

        public function get imageName():String {
            return "barrier_line";
        }
        // 参数：p,x,y,angle.color
        public function init(... prop):void {
            _p = prop[0];
            _p.pivotToCenter();
            _p.scale = 0.75
            _p.x = prop[1][0][0];
            _p.y = prop[1][0][1];
            _p.rotation = prop[1][0][2];
            _p.color = prop[1][0][3];
            LayerFactory.call(LayerFactory.ADD_FX)(_p.image)
        }

        public function update(dt:Number):void {

        }
    }
}
