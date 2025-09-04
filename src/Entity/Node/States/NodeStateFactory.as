package Entity.Node.States {
    import Entity.Node;
    import flash.utils.Dictionary;

    public class NodeStateFactory {
        /** 处理杂项 */
        public static const BASIC:String = "basic";
        /** 处理移动和贴图 */
        public static const MOVE:String = "move";
        /** 攻击状态 */
        public static const ATTACK:String = "attack";
        /** 战争状态 */
        public static const CONFLICT:String = "conflict";
        /** 占据状态 */
        public static const CAPTURE:String = "capture";
        /** 生产状态 */
        public static const BUILD:String = "build";

        /** 存储类型到类路径的映射 */
        private static var _stateMap:Dictionary = new Dictionary();

        private static var _ready:Boolean = false;

        private static function init():void {
            registerState(BASIC, NodeBasicState);
            registerState(MOVE, NodeMoveState);
            registerState(ATTACK, NodeAttackState);
            registerState(CONFLICT, NodeConflictState);
            registerState(CAPTURE, NodeCaptureState);
            registerState(BUILD, NodeBuildState);

            _ready = true;
        }

        /**注册自定义类型
         * @param type
         * @param stateClass
         * <p><code>NodeStateFactory.registerState("invisible", NodeInvisibleState);</code>
         */
        public static function registerState(type:String, stateClass:Class):void {
            _stateMap[type] = stateClass;
        }

        public static function create(type:String, node:Node):INodeState {
            if (!_ready)
                init();
            var stateClass:Class = _stateMap[type] as Class;
            if (stateClass) {
                try {
                    return new stateClass(node);
                } catch (e:Error) {
                    trace("Error creating State for type", type, ":", e.message);
                }
            }
            return null;
        }

        public static function createStatePool(node:Node):Dictionary {
            if (!_ready)
                init();
            var _statePool:Dictionary = new Dictionary;
            for (var key:String in _stateMap) {
                _statePool[key] = create(key, node);
            }
            return _statePool;
        }
    }
}
