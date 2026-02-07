package core.factories {
    import core.game.victory.*;

    import flash.utils.Dictionary;

    public class VictoryTypeFactory {
        public static const NONE_TYPE:String = "None";
        public static const NORMAL_TYPE:String = "Normal";
        public static const TARGET_TYPE:String = "Target";
        public static const TIME_TYPE:String = "Time";
        public static const ALL_OCCUPY_TYPE:String = "AllOccupy";

        /** 存储类型到类路径的映射 */
        private static var _typeMap:Dictionary = new Dictionary();

        private static var _ready:Boolean = false;

        private static function init():void {
            registerType(NONE_TYPE, NoneVictory);
            registerType(NORMAL_TYPE, NormalVictory);
            registerType(TARGET_TYPE, TargetVictory);
            registerType(TIME_TYPE, TimeVictory);
            registerType(ALL_OCCUPY_TYPE, AllOccupyVictory);
            _ready = true;
        }

        /** 注册自定义Victory类型
         * @param type 自定义类型标识符
         * @param typeClass Victory类引用
         * <p>示例：<code>VictoryTypeFactory.registerType("customType", CustomVictory);</code>
         */
        public static function registerType(type:String, typeClass:Class):void {
            _typeMap[type] = typeClass;
        }

        public static function create(obj:Object):IVictoryType {
            if (!_ready)
                init();

            var type:String;
            var trigger:Object = null;
            if (obj is String)
                type = obj as String;
            else {
                type = ("type" in obj) ? obj.type : NONE_TYPE;
                trigger = ("trigger" in obj) ? obj.trigger : null;
            }

            var typeClass:Class = _typeMap[type] as Class;

            if (typeClass) {
                try {
                    return new typeClass(trigger);
                } catch (e:Error) {
                    trace("Error creating Victory for type", type, ":", e.message);
                }
            }
            return new NoneVictory(null);
        }
    }
}
