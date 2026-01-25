package Entity.FX {
    import starling.errors.AbstractClassError;

    public class ParticleSystem {
        // 所有粒子必须先注册类型
        private static var _registerType:Vector.<String> = new Vector.<String>;
        private static var _typeClass:Vector.<Class> = new Vector.<Class>;
        // 为每种粒子分配一个实体池
        private static var _particlePool:Vector.<Vector.<BasicParticle>> = new Vector.<Vector.<BasicParticle>>;

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
        }

        public static function deinit():void {
            for each (var pool:Vector.<BasicParticle> in _particlePool)
                for each (var p:BasicParticle in pool)
                    p.reset();
        }

        public static function update(dt:Number):void {
            for each (var pool:Vector.<BasicParticle> in _particlePool)
                for each (var p:BasicParticle in pool)
                    if (p.active)
                        p.update(dt);
        }

        public static function addParticle(type:String, config:Array):void {
            var index:int = _registerType.indexOf(type);
            if (index == -1)
                throw new Error("particle type not regist");

            var recycle:Boolean = false;
            for each (var p:BasicParticle in _particlePool[index]) {
                if (p.active)
                    continue;
                p.reset();
                p.init(config);
                recycle = true;
                break;
            }

            if (recycle)
                return;
            var pClass:Class = _typeClass[index];
            p = new BasicParticle(type, new pClass());
            p.init(config);
            _particlePool[index].push(p);
        }

        public static function registerType(type:String, particleClass:Class):void {
            _registerType.push(type);
            _typeClass.push(particleClass);
        }
    }
}
