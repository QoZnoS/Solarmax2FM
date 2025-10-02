package Entity.AI {
    import flash.utils.Dictionary;
    import utils.Rng;

    public class EnemyAIFactory {
        public static const BASIC:String = "BasicAI";
        public static const SIMPLE:String = "SimpleAI";
        public static const SMART:String = "SmartAI";
        public static const DARK:String = "DarkAI";
        public static const FINAL:String = "FinalAI";
        public static const HARD:String = "HardAI";

        /** 存储类型到类路径的映射 */
        private static var _aiMap:Dictionary = new Dictionary();

        private static var _ready:Boolean = false;

        private static function init():void {
            registerAI(BASIC, BasicAI);
            registerAI(SIMPLE, SimpleAI);
            registerAI(SMART, SmartAI);
            registerAI(DARK, DarkAI);
            registerAI(FINAL, FinalAI);
            registerAI(HARD, HardAI);

            _ready = true;
        }

        /** 注册自定义AI类型
         * @param type 自定义类型标识符
         * @param aiClass AI类引用
         * <p>示例：<code>EnemyAIFactory.registerAI("customAI", CustomEnemyAI);</code>
         */
        public static function registerAI(type:String, aiClass:Class):void {
            _aiMap[type] = aiClass;
        }

        public static function create(type:String, rng:Rng, actionDelay:Number = -1, startDelay:Number = -1):IEnemyAI {
            if (!_ready)
                init();

            var aiClass:Class = _aiMap[type] as Class;
            if (actionDelay == -1)
                actionDelay = getDefaultActionDelay(type);
            if (startDelay == -1)
                startDelay = getDefaultStartDelay(type);
            if (aiClass) {
                try {
                    return new aiClass(rng, actionDelay, startDelay);
                } catch (e:Error) {
                    trace("Error creating AI for type", type, ":", e.message);
                }
            }
            return new BasicAI(rng, actionDelay, startDelay);
        }

        private static function getDefaultActionDelay(type:String):Number {
            switch (type) {
                case SIMPLE:
                    return 3;
                case SMART:
                    return 1.5;
                case HARD:
                    return 0;
                case DARK,FINAL:
                    return 0.25;
                default:
                    return 1.5;
            }
        }

        private static function getDefaultStartDelay(type:String):Number {
            switch (type) {
                case SIMPLE:
                    return 3;
                case SMART:
                    return 1.5;
                case HARD:
                    return 1.5;
                case DARK,FINAL:
                    return 0.25;
                default:
                    return 1.5;
            }
        }        
    }
}
