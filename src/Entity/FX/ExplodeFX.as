// 文件: ExplodeFX_new.as
package Entity.FX {
    import UI.LayerFactory;

    public class ExplodeFX implements IParticle {
        private var p:BasicParticle;
        private var layerCfg:Array;
        
        private static const STATE_GROW:int = 0;
        private static const STATE_SHRINK:int = 1;
        
        private var state:int;
        private var size:Number;
        private var foreground:Boolean;
        private var deepColor:Boolean;

        public function ExplodeFX() {
            layerCfg = [];
        }

        public function get imageName():String {
            return "ship_pulse";
        }

        // 接受参数: x, y, color, foreground, deepColor
        public function init(p:BasicParticle, config:Array):void {
            this.p = p;
            p.texturePivotToCenter();
            p.x = config[0];
            p.y = config[1];
            p.color = config[2];
            this.foreground = config[3];
            this.deepColor = config[4];
            
            p.scale = 0;
            p.alpha = 0.5;
            this.size = 0;
            state = STATE_GROW;
            
            layerCfg = [LayerFactory.ADD_IMAGE, foreground, deepColor];
        }

        public function update(dt:Number):void {
            if (state == STATE_GROW) {
                size += dt;
                p.scale = size;
                if (size >= 0.5)
                    state = STATE_SHRINK;
            } else {
                size += dt;
                p.scale = size;
                p.alpha -= dt;
                if (p.alpha <= 0) {
                    p.alpha = 0;
                    p.active = false;
                }
            }
            p.addToLayer();
        }
        
        public function get layerConfig():Array {
            return layerCfg;
        }
    }
}