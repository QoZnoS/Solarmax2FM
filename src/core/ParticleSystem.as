package core {
    import core.fx.*;

    import starling.errors.AbstractClassError;

    public class ParticleSystem {
        // 所有粒子必须先注册类型
        private static var _registerType:Vector.<String> = new Vector.<String>;
        private static var _typeClass:Vector.<Class> = new Vector.<Class>;
        // 为每种粒子分配一个实体池
        private static var _particlePool:Vector.<Vector.<BasicParticle>> = new Vector.<Vector.<BasicParticle>>;

        // 粒子进入池后会一直存留，不做任何位置上的变化
        // 当粒子周期结束后，该粒子会被标记为不活跃，直到需要再次用到该粒子
        // 添加粒子时，直接遍历找到第一个不活跃粒子
        // 显然池中粒子总数总是等同于场上同时存在的最大粒子数量
        // 由于每帧遍历超大向量可能产生性能问题，以下变量专用于减少遍历次数
        private static var frame:int // 帧
        private static var firstInactive:Vector.<int> // 每个粒子池一帧内第一个不活跃粒子
        private static var maxP:Vector.<int>; // 每个粒子池正在活跃的最大编号

        public static const BARRIER:String = "FX";
        public static const WARP:String = "warp";
        public static const EXPLODE:String = "explode";
        public static const FLASH:String = "flash";
        public static const NODE_PULSE:String = "nodePulse";
        public static const BEAM_LINE:String = "beamLine";
        public static const BEAM_SHOOTER:String = "beamShooter";
        public static const ONE_FRAME:String = "oneFrame";
        public static const SELECT_FADE:String = "selectFade";

        // 粒子池
        public function ParticleSystem() {
            throw new AbstractClassError();
        }

        public static function init():void {
            registerType(BARRIER, BarrierFX);
            registerType(WARP, WarpFX);
            registerType(EXPLODE, ExplodeFX);
            registerType(FLASH, FlashFX);
            registerType(NODE_PULSE, NodePulse);
            registerType(BEAM_LINE, BeamLine);
            registerType(BEAM_SHOOTER, BeamShooter);
            registerType(ONE_FRAME, OneFrameFX);
            registerType(SELECT_FADE, SelectFade);

            // 初始化所有已注册类型
            for (var i:int = 0; i < _registerType.length; i++)
                if (_particlePool.length < i + 1)
                    _particlePool.push(new Vector.<BasicParticle>);
            frame = 1;
            firstInactive = new Vector.<int>(_particlePool.length, true);
            maxP = new Vector.<int>(_particlePool.length, true);
        }

        public static function deinit():void {
            frame = 1;
            for each (var pool:Vector.<BasicParticle> in _particlePool)
                for each (var p:BasicParticle in pool)
                    p.reset();
            for (var i:int = 0; i < firstInactive.length; i++) {
                firstInactive[i] = 0;
                maxP[i] = 0;
            }
        }

        public static function update(dt:Number):void {
            frame++;
            var length:int = _particlePool.length;
            for (var i:int = 0; i < firstInactive.length; i++)
                firstInactive[i] = 0;
            for (var index:int = 0; index < length; index++) {
                var pool:Vector.<BasicParticle> = _particlePool[index];
                var max:int = 0;
                for (i = 0; i < maxP[index]; i++) {
                    var p:BasicParticle = pool[i];
                    if (!p.active)
                        continue;
                    p.update(dt);
                    max = i + 1;
                }
                maxP[index] = max;
            }
        }

        public static function addParticle(type:String, config:Array):void {
            var index:int = _registerType.indexOf(type);
            if (index == -1)
                throw new Error("particle type not registered");

            var pool:Vector.<BasicParticle> = _particlePool[index];
            var reused:Boolean = false;
            var start:int = firstInactive[index]; // 当前帧已扫描到的位置提示

            // 1. 从 firstInactive 位置开始向后查找不活跃粒子
            for (var i:int = start; i < pool.length; i++) {
                if (!pool[i].active) {
                    reuseParticle(index, i, config);
                    firstInactive[index] = i + 1; // 下次从下一个位置开始
                    reused = true;
                    break;
                }
            }

            // 2. 如果未找到，再从 0 到 start-1 扫描（覆盖 start 之前的空洞）
            if (!reused) {
                for (i = 0; i < start; i++) {
                    if (!pool[i].active) {
                        reuseParticle(index, i, config);
                        firstInactive[index] = i + 1;
                        reused = true;
                        break;
                    }
                }
            }

            // 3. 仍未找到，则创建新粒子
            if (!reused) {
                var pClass:Class = _typeClass[index];
                var newParticle:BasicParticle = new BasicParticle(type, new pClass());
                newParticle.init(config);
                pool.push(newParticle);
                maxP[index] = pool.length; // 新粒子在末尾，更新最大索引
                firstInactive[index] = pool.length; // 无空闲位置，指向末尾之后
            }
        }

        // 辅助函数：复用指定索引的粒子
        private static function reuseParticle(typeIndex:int, particleIndex:int, config:Array):void {
            var pool:Vector.<BasicParticle> = _particlePool[typeIndex];
            var p:BasicParticle = pool[particleIndex];
            p.reset();
            p.init(config);
            // 更新 maxP：可能粒子索引大于当前 maxP，需要扩展活跃范围
            if (particleIndex + 1 > maxP[typeIndex])
                maxP[typeIndex] = particleIndex + 1;
        }

        public static function registerType(type:String, particleClass:Class):void {
            _registerType.push(type);
            _typeClass.push(particleClass);
        }
    }
}
