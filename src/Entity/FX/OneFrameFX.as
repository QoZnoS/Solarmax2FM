package Entity.FX {
    import UI.LayerFactory;

    public class OneFrameFX implements IParticle {
        public static const BLACKHOLE_PULSE:String = "blackhole_pulse";
        public static const SKILL_LIGHT:String = "skill_light";
        public static const SKILL_GLOW:String = "skill_glow";

        private var p:BasicParticle;
        private var layerCfg:Array;
        private var deepColor:Boolean;

        public function OneFrameFX() {
            layerCfg = [LayerFactory.ADD_GROW];
        }

        // 接受参数: imageName, x, y, size, color, alpha, angle, deepColor
        public function init(p:BasicParticle, config:Array):void {
            this.p = p;
            // p.texturePivotToCenter();
            p.rotation = 0;
            p.texture = config[0];
            p.scale = 1;
            p.pivot = p.width * 0.5;
            p.x = config[1];
            p.y = config[2];
            p.scale = config[3];
            p.color = config[4];
            p.alpha = config[5];
            p.rotation = config[6];
            this.deepColor = config[7];
            layerCfg.length = 1;
            layerCfg.push(deepColor);
            p.visible = true;
            pass = true;
            p.addToLayer();
        }

        private var pass:Boolean;

        public function update(dt:Number):void {
            if (!pass) {
                p.visible = false;
                p.active = false;
                return;
            } else
                pass = false;
        }

        public function get imageName():String {
            // 默认纹理，实际纹理在init中设置
            return "blackhole_pulse";
        }

        public function get layerConfig():Array {
            return layerCfg;
        }
    }
}
