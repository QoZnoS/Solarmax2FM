package Game.SpecialEvent {

    import flash.utils.Dictionary;

    public class SpecialEventFactory {
        /** 原版1关提示 */
        public static var MOVE_GUIDE:String = "MoveGuide";
        /** 原版2关提示 */
        public static var FLEET_SLIDER_GUIDE:String = "FleetSliderGuide";
        /** 原版32关演出 */
        public static var DARKNESS_FALLS:String = "DarknessFalls";
        /** 原版33~35黑色出场 */
        public static var BOSS_APPEAR:String = "BossAppear";
        /** 原版36通关 */
        public static var GAME_END:String = "GameEnd";

        /** 存储类型到类路径的映射 */
        private static var _typeMap:Dictionary = new Dictionary();

        private static var _ready:Boolean = false;

        private static function init():void {
            registerType(MOVE_GUIDE, MoveGuideSE);
            registerType(FLEET_SLIDER_GUIDE, FleetSliderGuideSE);

            _ready = true;
        }

        /** 注册自定义SpecialEvent类型
         * @param type 自定义类型标识符
         * @param typeClass SpecialEvent类引用
         * <p>示例：<code>SpecialEventFactory.registerType("customSE", CustomSE);</code>
         */
        public static function registerType(type:String, typeClass:Class):void {
            _typeMap[type] = typeClass;
        }

        public static function create(type:String, trigger:Object = null):ISpecialEvent {
            if (!_ready)
                init();

            var typeClass:Class = _typeMap[type] as Class;

            if (typeClass) {
                try {
                    return new typeClass(trigger);
                } catch (e:Error) {
                    trace("Error creating SpecialEvent for type", type, ":", e.message);
                }
            }
            throw new Error("event not exist");
        }
    }
}
