package core.fx {
    import managers.Globals;

    import ui.layers.LayerFactory;

    import utils.CalcTools;

    public class BeamLine implements IParticle {
        private var p:BasicParticle;
        private var layerCfg:Array;

        private var x1:Number;
        private var y1:Number;
        private var x2:Number;
        private var y2:Number;
        private var size:Number;
        private var angle:Number;
        private var distance:Number;
        private var color:uint;
        private var deepColor:Boolean;
        private var foreground:Boolean;
        private var state:int;

        private static const STATE_GROW:int = 0;
        private static const STATE_SHRINK:int = 1;

        public function BeamLine() {
            layerCfg = [LayerFactory.ADD_IMAGE];
        }

        public function get imageName():String {
            return "quad_16x4glow";
        }

        // 接受参数: x1, y1, x2, y2, team (用于获取颜色)
        public function init(p:BasicParticle, config:Array):void {
            this.p = p;
            this.x1 = config[0];
            this.y1 = config[1];
            this.x2 = config[2];
            this.y2 = config[3];
            var team:int = config[4];
            p.imagePovitYToCenter();
            p.adjustVertices();

            var dx:Number = x2 - x1;
            var dy:Number = y2 - y1;
            this.distance = Math.sqrt(dx * dx + dy * dy);
            this.angle = Math.atan2(dy, dx);
            this.color = Globals.teamColors[team];
            if (Globals.teamColorEnhance[team])
                this.color = CalcTools.scaleColorToMax(this.color);
            this.deepColor = Globals.teamDeepColors[team];
            this.foreground = true;
            this.size = 0;
            this.state = STATE_GROW;
            p.rotation = 0;
            p.x = x1;
            p.y = y1;
            p.width = distance;
            p.color = color;
            p.scaleY = 1;
            p.alpha = 0.75;
            p.rotation = angle;
            layerCfg.length = 1;
            layerCfg.push(foreground, deepColor);
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
            p.scaleY = size * 0.5;
            p.rotation = angle;
            p.addToLayer();
        }

        public function get layerConfig():Array {
            return layerCfg;
        }
    }
}
