package Entity.Node.Interface {
    import Entity.Node.Attack.*;
    import flash.utils.Dictionary;

    public class AttackStrategyFactory {
        public static const TOWER:String = "tower";
        public static const PULSECANNON:String = "pulsecannon";
        public static const BLACKHOLE:String = "blackhole";
        public static const CLONETURRENT:String = "cloneturrent";
        public static const CAPTURESHIP:String = "captureship";

        /** 存储类型到类路径的映射 */
        private static var _strategyMap:Dictionary = new Dictionary();

        private static var _ready:Boolean = false;
        private static function init():void {
            registerStrategy(TOWER, TowerAttack);
            registerStrategy(PULSECANNON, PulsecannonAttack);
            registerStrategy(BLACKHOLE, BlackholeAttack);
            registerStrategy(CLONETURRENT, CloneturrentAttack);
            registerStrategy(CAPTURESHIP, CaptureshipAttack);

            _ready = true;
        }

        /**注册自定义类型
         * @param type
         * @param classPath
         * <p><code>AttackStrategyFactory.registerStrategy("laserbeam", ModAttack);</code>
         */
        public static function registerStrategy(type:String, strategyClass:Class):void {
            _strategyMap[type] = strategyClass;
        }

        public static function create(type:String, attackRate:Number = 0.1, attackRange:Number = 180, attackLast:Number = 5):IAttackStrategy {
            if (!_ready)
                init();
            var strategyClass:Class = _strategyMap[type] as Class;

            if (strategyClass) {
                try {
                    return new strategyClass(attackRate, attackRange, attackLast);
                } catch (e:Error) {
                    trace("Error creating strategy for type", type, ":", e.message);
                }
            }
            return new BasicAttack(attackRate, attackRange, attackLast);
        }
    }
}
