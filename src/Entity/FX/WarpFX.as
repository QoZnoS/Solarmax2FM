package Entity.FX {

    import UI.LayerFactory;

    public class WarpFX implements IParticle {
        private var p:BasicParticle;

        private static const STATE_GROW:int = 0;
        private static const STATE_SHRINK:int = 1;

        private var x:Number;
        private var y:Number;
        private var angle:Number;
        private var distance:Number;
        private var size:Number;
        private var foreground:Boolean;
        private var deepColor:Boolean;
        private var state:int;
        private var layerCfg:Array;

        public function WarpFX() {
            layerCfg = [];
        }

        // 接受参数 x, y, prevX, prevY, color, foreground, deepColor
        public function init(p:BasicParticle, config:Array):void {
            layerCfg.length = 0;
            this.p = p;
            p.pivotToCenter();
            this.x = config[0];
            this.y = config[1];
            var dx:Number = config[2] - x;
            var dy:Number = config[3] - y;
            this.angle = Math.atan2(dy, dx);
            this.distance = Math.sqrt(dx * dx + dy * dy);
            this.foreground = config[5];
            this.deepColor = config[6];
            this.size = 0;
            state = 0;
            p.x = x;
            p.y = y;
            p.color = config[4];
            p.scale = 0;
            p.alpha = 1;
            layerCfg.push(LayerFactory.ADD_IMAGE, foreground, deepColor);
        }

        public function get imageName():String {
            return "warp_glare";
        }
        public function get layerConfig():Array {
            return layerCfg;
        }

        public function update(dt:Number):void {
            if (state == 0) {
                size += dt * 8;
                if (size >= 1) {
                    size = 1;
                    state = 1;
                }
            } else {
                size -= dt * 3;
                if (size <= 0) {
                    size = 0;
                    p.active = false;
                }
            }
            p.scale = size;
            p.alpha = 1;
            p.rotation = 0;
            p.x = x + Math.cos(angle) * distance * 0.5;
            p.y = y + Math.sin(angle) * distance * 0.5;
            p.width = distance;
            p.scaleY *= 0.5;
            p.alpha = 0.25;
            p.rotation = angle;
            p.addToLayer();
        }
    }
}
