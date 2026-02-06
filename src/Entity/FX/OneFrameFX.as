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
            p.texture = config[0];
            p.rotation = 0;
            p.scale = 1;
            p.texturePivotToCenter();
            p.x = config[1];
            p.y = config[2];
            p.scale = config[3];
            p.color = config[4];
            p.alpha = config[6];
            p.rotation = config[7];
            this.deepColor = config[8];
            layerCfg.length = 1;
            layerCfg.push(deepColor);
            p.addToLayer();
        }

        public function update(dt:Number):void {
            p.active = false;
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
