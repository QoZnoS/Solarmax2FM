package Entity.FX {
    import Game.GameScene;
    import Menus.EndScene;
    import Entity.Node;
    import starling.display.Image;
    import flash.utils.Dictionary;
    import flash.geom.Rectangle;
    import Entity.GameEntity;
    
    public class UnifiedParticleSystem{
        // 特效类型枚举
        public static const TYPE_BARRIER:String = "barrier";
        public static const TYPE_BEAM:String = "beam";
        public static const TYPE_DARK_PULSE:String = "dark_pulse";
        public static const TYPE_END_STAR:String = "end_star";
        public static const TYPE_EXPLOSION:String = "explosion";
        public static const TYPE_FLASH:String = "flash";
        public static const TYPE_LIGHTNING:String = "lightning";
        public static const TYPE_NODE_PULSE:String = "node_pulse";
        public static const TYPE_SELECT_FADE:String = "select_fade";
        public static const TYPE_WARP:String = "warp";
        
        // 粒子状态
        private static const STATE_GROW:int = 0;
        private static const STATE_SHRINK:int = 1;
        private static const STATE_BLINK:int = 2;
        private static const STATE_ACTIVE:int = 3;
        
        // 对象池
        private var _particlePool:Vector.<ParticleData>;
        private var _activeParticles:Vector.<ParticleData>;
        private var _poolSize:int = 4096; // 支持超过2048个特效
        
        
        public function UnifiedParticleSystem() {
            super();
            _particlePool = new Vector.<ParticleData>(_poolSize);
            _activeParticles = new Vector.<ParticleData>();
        }
                
        // ==================== 公共接口 ====================
        
        /**
         * 创建屏障特效
         */
        public function createBarrier(x:Number, y:Number, angle:Number, color:uint, 
                                     gameScene:GameScene = null):int {
            return createParticle({
                type: TYPE_BARRIER,
                x: x,
                y: y,
                angle: angle,
                color: color,
                textureName: "barrier_line",
                pivotX: 0.5,
                pivotY: 0.5,
                scaleX: 0.75,
                scaleY: 0.75,
                gameScene: gameScene,
                layer: "fxLayer"
            });
        }
        
        /**
         * 创建光束特效
         */
        public function createBeam(x1:Number, y1:Number, x2:Number, y2:Number, 
                                  node:Node, gameScene:GameScene):int {
            var dx:Number = x2 - x1;
            var dy:Number = y2 - y1;
            var distance:Number = Math.sqrt(dx * dx + dy * dy);
            
            return createParticle({
                type: TYPE_BEAM,
                x: x1,
                y: y1,
                targetX: x2,
                targetY: y2,
                color: Globals.teamColors[node.nodeData.team],
                deepColor: Globals.teamDeepColors[node.nodeData.team],
                textureName: "quad_16x4glow",
                secondaryTexture: node.nodeData.type == "TOWER" ? "tower_shape" : 
                                 node.nodeData.type == "STARBASE" ? "starbase_laser" : 
                                 node.nodeData.type + "_shape",
                nodeType: node.nodeData.type,
                angle: Math.atan2(dy, dx),
                width: distance,
                state: STATE_GROW,
                gameScene: gameScene,
                layer: "entityLayer"
            });
        }
        
        /**
         * 创建黑暗脉冲特效
         */
        public function createDarkPulse(node:Node, color:uint, pulseType:int, 
                                       maxSize:Number, rate:Number, angle:Number, 
                                       deepColor:Boolean, delay:Number = 0, 
                                       gameScene:GameScene = null):int {
            var textureMap:Object = {
                0: "halo",        // TYPE_GROW
                1: "halo",        // TYPE_SHRINK
                2: "spot_glow",   // TYPE_BLOB
                3: "spot_glow",   // TYPE_BLOOM
                4: "blackhole_pulse", // TYPE_BLACKHOLE_ATTACK
                5: "blackhole_pulse", // TYPE_BLACKHOLE
                6: "skill_light", // TYPE_BLACKHOLE_FLARE
                7: "skill_glow",
                8: getRandomArcTexture() // TYPE_DIFFUSION_ARC
            };
            
            return createParticle({
                type: TYPE_DARK_PULSE,
                x: node.nodeData.x,
                y: node.nodeData.y,
                color: color,
                pulseType: pulseType,
                maxSize: maxSize,
                rate: rate,
                angle: angle,
                delay: delay,
                deepColor: deepColor,
                textureName: textureMap[pulseType],
                pivotX: 0.5,
                pivotY: 0.5,
                gameScene: gameScene,
                layer: pulseType == 4 ? "blackholeLayer" : "glowLayer"
            });
        }
        
        // 更多创建方法...
        // 由于篇幅限制，这里只展示部分接口
        
        // ==================== 核心管理方法 ====================
        
        private function createParticle(config:Object):int {
            // 从池中获取空闲粒子
            var particle:ParticleData = getFreeParticle();
            if (!particle) return -1;
            
            // 初始化粒子
            particle.id = _activeParticles.length;
            particle.type = config.type;
            particle.config = config;
            particle.active = true;
            particle.age = 0;
            particle.lifetime = getLifetimeByType(config.type);
            
            // 设置初始状态
            initParticleState(particle, config);
            
            // 添加到活跃列表
            _activeParticles.push(particle);
            
            return particle.id;
        }
        
        private function initParticleState(particle:ParticleData, config:Object):void {
            switch(config.type) {
                case TYPE_BARRIER:
                    particle.currentState = STATE_ACTIVE;
                    particle.x = config.x;
                    particle.y = config.y;
                    particle.scaleX = config.scaleX;
                    particle.scaleY = config.scaleY;
                    particle.rotation = config.angle;
                    particle.color = config.color;
                    break;
                    
                case TYPE_BEAM:
                    particle.currentState = STATE_GROW;
                    particle.size = 0;
                    particle.growthRate = 20;
                    particle.shrinkRate = 10;
                    break;
                    
                case TYPE_DARK_PULSE:
                    switch(config.pulseType) {
                        case 0: // GROW
                            particle.size = 0;
                            particle.alpha = 1;
                            break;
                        case 1: // SHRINK
                            particle.size = config.maxSize;
                            particle.alpha = 0;
                            break;
                        case 2: // BLOB
                            particle.size = config.maxSize;
                            particle.alpha = 0;
                            break;
                        case 3: // BLOOM
                            particle.size = 0;
                            particle.alpha = 1;
                            break;
                        default:
                            particle.alpha = config.rate * 0.8;
                            particle.size = config.maxSize;
                    }
                    break;
                    
                // 其他类型初始化...
            }
        }
        
        public function update(dt:Number):void {
            // 批量更新所有活跃粒子
            var i:int = _activeParticles.length;
            while (i-- > 0) {
                var particle:ParticleData = _activeParticles[i];
                
                if (!particle.active) {
                    // 回收粒子
                    recycleParticle(particle);
                    _activeParticles.splice(i, 1);
                    continue;
                }
                
                // 更新粒子年龄
                particle.age += dt;
                
                // 延迟处理
                if (particle.delay > 0) {
                    particle.delay -= dt;
                    continue;
                }
                
                // 根据类型更新
                updateParticle(particle, dt);
                
                // 检查生命周期
                if (particle.age >= particle.lifetime)
                    particle.active = false;
            }
        }
        
        private function updateParticle(particle:ParticleData, dt:Number):void {
            var config:Object = particle.config;
            
            switch(particle.type) {
                case TYPE_BEAM:
                    updateBeam(particle, dt);
                    break;
                    
                case TYPE_DARK_PULSE:
                    updateDarkPulse(particle, dt);
                    break;
                    
                case TYPE_EXPLOSION:
                    // updateExplosion(particle, dt);
                    break;
                    
                // 其他类型更新...
            }
        }
        
        private function updateBeam(particle:ParticleData, dt:Number):void {
            var config:Object = particle.config;
            
            if (particle.currentState == STATE_GROW) {
                particle.size += dt * particle.growthRate;
                if (particle.size >= 1) {
                    particle.size = 1;
                    particle.currentState = STATE_SHRINK;
                }
            } else {
                particle.size -= dt * particle.shrinkRate;
                if (particle.size <= 0) {
                    particle.active = false;
                }
            }
            
            particle.alpha = particle.size;
            particle.scaleY = particle.size * 0.5;
            
            // 根据节点类型处理
            if (config.nodeType == "TOWER") {
                particle.secondaryScale = particle.size;
            } else if (config.nodeType == "STARBASE") {
                particle.secondaryAlpha = particle.size;
            }
        }
        
        private function updateDarkPulse(particle:ParticleData, dt:Number):void {
            var config:Object = particle.config;
            
            switch(config.pulseType) {
                case 0: // GROW
                    particle.size += dt * config.rate;
                    if (particle.size > config.maxSize) {
                        particle.active = false;
                    }
                    particle.alpha = 1 - particle.size / config.maxSize;
                    break;
                    
                case 1: // SHRINK
                    particle.size -= dt * config.rate;
                    if (particle.size < 0) {
                        particle.active = false;
                    }
                    particle.alpha = 1 - particle.size / config.maxSize;
                    break;
                    
                case 2: // BLOB
                    particle.size -= dt * config.rate;
                    if (particle.size < 0) {
                        particle.active = false;
                    }
                    particle.alpha = 1 - particle.size / config.maxSize;
                    particle.scaleX = particle.scaleY = particle.size * 6;
                    break;
                    
                // 其他脉冲类型...
            }
        }
    
        
        // ==================== 工具方法 ====================
        
        private function getFreeParticle():ParticleData {
            for (var i:int = 0; i < _poolSize; i++)
                if (!_particlePool[i].active)
                    return _particlePool[i];
            return expandPool();
        }
        
        private function expandPool():ParticleData {
            var newParticle:ParticleData = new ParticleData();
            _particlePool.push(newParticle);
            _poolSize++;
            return newParticle;
        }
        
        private function recycleParticle(particle:ParticleData):void {
            particle.reset();
        }
        
        private function getLifetimeByType(type:String):Number {
            var lifetimes:Object = {
                "barrier": 1.0,
                "beam": 2.0,
                "dark_pulse": 3.0,
                "explosion": 1.5,
                "flash": 1.0,
                "lightning": 1.0,
                "node_pulse": 2.0,
                "select_fade": 0.5,
                "warp": 1.5,
                "end_star": 10.0
            };
            return lifetimes[type] || 1.0;
        }
        
        private function getRandomArcTexture():String {
            var imageID:int = Math.floor(Math.random() * 16) + 1;
            return "elecarc" + (imageID < 10 ? "0" + imageID : imageID.toString());
        }
    }
}