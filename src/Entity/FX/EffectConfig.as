// Entity/FX/EffectConfig.as
package Entity.FX {
    public class EffectConfig {
        private static var _configs:Object = {
            "barrier": {
                texture: "barrier_line",
                pivotX: 0.5,
                pivotY: 0.5,
                lifetime: 1.0,
                updateType: "static",
                layer: "fxLayer"
            },
            
            "beam_grow": {
                texture: "quad_16x4glow",
                pivotY: 0.5,
                lifetime: 0.5,
                updateType: "scale_grow",
                growthRate: 20,
                shrinkRate: 10,
                layer: "entityLayer",
                states: [
                    {scaleY: 0.5, alpha: 0.75},
                    {scaleY: 1.0, alpha: 1.0}
                ]
            },
            
            "dark_pulse_grow": {
                texture: "halo",
                pivotX: 0.5,
                pivotY: 0.5,
                lifetime: 1.5,
                updateType: "pulse_grow",
                layer: "glowLayer",
                animation: {
                    startScale: 0,
                    endScale: 1,
                    startAlpha: 1,
                    endAlpha: 0,
                    curve: "easeOut"
                }
            },
            
            "explosion": {
                texture: "ship_pulse",
                pivotX: 0.5,
                pivotY: 0.5,
                lifetime: 1.0,
                updateType: "explosion",
                layer: "entityLayer",
                animation: {
                    phases: [
                        {duration: 0.3, scale: 0.5, alpha: 0.5},
                        {duration: 0.7, scale: 1.0, alpha: 0}
                    ]
                }
            }
            // 更多配置...
        };
        
        public static function getConfig(type:String):Object {
            return _configs[type] || {};
        }
        
        public static function registerConfig(type:String, config:Object):void {
            _configs[type] = config;
        }
    }
}