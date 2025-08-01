package Entity.Node.States {
    import flash.utils.Dictionary;

    public class NodeStateFactory {
        /**中立天体状态 */
        public static const IDLE:String = "idle";
        /**战争状态 */
        public static const CONFLICT:String = "conflict";
        /**占据状态 */
        public static const CAPTURE:String = "capture";
        /**生成状态 */
        public static const BUILD:String = "build";

        /** 存储类型到类路径的映射 */
        private static var _stateMap:Dictionary = new Dictionary();

        private static var _ready:Boolean = false;

        private static function init():void {
            registerState(IDLE, NodeIdleState);

            _ready = true;
        }

        /**注册自定义类型
         * @param type
         * @param classPath
         * <p><code>AttackStateFactory.registerState("invisible", NodeInvisibleState);</code>
         */
        public static function registerState(type:String, stateClass:Class):void {
            _stateMap[type] = stateClass;
        }

        public static function create(type:String):INodeState {
            if (!_ready)
                init();
            var stateClass:Class = _stateMap[type] as Class;

            if (stateClass) {
                try {
                    return new stateClass();
                } catch (e:Error) {
                    trace("Error creating State for type", type, ":", e.message);
                }
            }
            return new NodeIdleState();
        }
    }
}
