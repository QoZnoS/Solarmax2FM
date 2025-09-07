package Game.LoseType {
    import flash.utils.Dictionary;

    public class LoseTypeFactory {
        public static const NONE_TYPE:String = "None";
        public static const NORMAL_TYPE:String = "Normal";
        public static const TARGET_TYPE:String = "target";
        public static const TIME_TYPE:String = "Time";

        /** 存储类型到类路径的映射 */
        private static var _typeMap:Dictionary = new Dictionary();

        private static var _ready:Boolean = false;

        private static function init():void {
            registerType(NONE_TYPE, NoneLose);
            registerType(NORMAL_TYPE, NormalLose);
            registerType(TARGET_TYPE, TargetLose);
            registerType(TIME_TYPE, TimeLose);

            _ready = true;
        }

        /** 注册自定义Lose类型
         * @param type 自定义类型标识符
         * @param typeClass Lose类引用
         * <p>示例：<code>LoseTypeFactory.registerType("customType", CustomLose);</code>
         */
        public static function registerType(type:String, typeClass:Class):void {
            _typeMap[type] = typeClass;
        }

        public static function create(type:String, trigger:Object = null):ILoseType {
            if (!_ready)
                init();

            var typeClass:Class = _typeMap[type] as Class;

            if (typeClass) {
                try {
                    return new typeClass(trigger);
                } catch (e:Error) {
                    trace("Error creating Lose for type", type, ":", e.message);
                }
            }
            return new NoneLose(trigger);
        }
    }
}
