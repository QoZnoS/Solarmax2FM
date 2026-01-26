package Entity {
    import starling.errors.AbstractClassError;
    import Entity.FX.*;

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
        private static var recycleFrame:int // 上一次回收粒子的帧
        private static var firstInactive:Vector.<int> // 每个粒子池一帧内第一个不活跃粒子
        private static var maxP:Vector.<int>; // 每个粒子池正在活跃的最大编号

        // 粒子池
        public function ParticleSystem() {
            throw new AbstractClassError();
        }

        public static function init():void {
            registerType("FX", BarrierFX);
            registerType("warp", WarpFX);
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
        }

        public static function update(dt:Number):void {
            frame++;
            var length:int = _particlePool.length;
            for (var index:int = 0; index < length; index++) {
                var pool:Vector.<BasicParticle> = _particlePool[index];
                for (var i:int = 0; i < maxP[index]; i++) {
                    var p:BasicParticle = pool[i];
                    if (p.active)
                        p.update(dt);
                }
                maxP[index] = i;
            }
        }

        public static function addParticle(type:String, config:Array):void {
            var index:int = _registerType.indexOf(type);
            if (index == -1)
                throw new Error("particle type not regist");

            var recycle:Boolean = false;
            var length:int = _particlePool[index].length;
            for (var i:int = 0; i < length; i++) {
                // 单帧内需要大量添加实体时，总是从上一次回收结束时开始回收，减少遍历次数
                if (recycleFrame == frame)
                    i = firstInactive[index];
                if (i >= length)
                    break;
                var p:BasicParticle = _particlePool[index][i];
                if (p.active) {
                    firstInactive[index] = i + 1;
                    continue;
                }
                p.reset();
                p.init(config);
                recycle = true;
                recycleFrame = frame;
                firstInactive[index] = p.active ? i + 1 : i;
                maxP[index] = i + 1;
                break;
            }

            if (recycle)
                return;
            var pClass:Class = _typeClass[index];
            p = new BasicParticle(type, new pClass());
            p.init(config);
            _particlePool[index].push(p);
            maxP[index] = _particlePool[index].length;
        }

        public static function registerType(type:String, particleClass:Class):void {
            _registerType.push(type);
            _typeClass.push(particleClass);
        }
    }
}
