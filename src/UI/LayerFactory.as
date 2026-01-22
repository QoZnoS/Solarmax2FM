package UI
{
    import flash.utils.Dictionary;
    import starling.display.Sprite;
    import starling.display.DisplayObject;

    public class LayerFactory
    {
        // public static const ENTITY:String = "entityLayer";
        public static const BTN:String = "buttonLayer";
        public static const BTN_ADD:String = "buttonAddLayer";
        public static const BTN_NORMAL:String = "buttonNormalLayer";
        public static const GAME_CONTAINER:String = "gameContainer";
        public static const BEHAVIOR:String = "behaviorBatch";
        public static const LABEL:String = "labelLayer";

        /** 
         * 添加天体贴图
         * <p><code>node:Image</code>
         * <p><code>halo:Image</code>
         * <p><code>glow:Image</code>
         * <p><code>deepColor:Boolean</code>
         */
        public static const ADD_NODE:String = "addNode";

        /** 
         * 移除天体贴图
         * <p><code>node:Image</code>
         * <p><code>halo:Image</code>
         * <p><code>glow:Image</code>
         */
        public static const REMOVE_NODE:String = "removeNode";

        /**
         * 添加贴图到飞船图层
         * <p><code>image:Image</code>
         * <p><code>foreground:Boolean</code>
         * <p><code>deepColor:Boolean</code>
         */
        public static const ADD_IMAGE:String = "addImage";

        /**
         * 添加贴图到天体光圈图层
         * <p><code>glow:Image</code>
         * <p><code>deepColor:Boolean</code>
         */
        public static const ADD_GROW:String = "addGrow";

        /**
         * 从天体光圈图层移除贴图
         * <p><code>glow:Image</code>
         */
        public static const REMOVE_GROW:String = "removeGrow";

        /**
         * 添加贴图到黑洞图层
         * <p><code>image:Image</code>
         */
        public static const ADD_BLACKHOLE:String = "addBlackhole";

        /**
         * 添加贴图到fx图层
         * <p><code>image:Image</code>
         */
        public static const ADD_FX:String = "addFx";



        private static var _layerMap:Dictionary = new Dictionary();
        private static var _functionMap:Dictionary = new Dictionary();

        /**注册自定义图层
         * @param type 图层名称
         * @param layerObject 图层对象
         * <p><code>NodeStateFactory.registerState("invisible", NodeInvisibleState);</code>
         */
        public static function registerLayer(type:String, layerObject:DisplayObject):void {
            if (!_layerMap.hasOwnProperty(type))
                _layerMap[type] = layerObject as DisplayObject;
            else
                throw new Error("type already exist");
        }

        public static function registerFunction(type:String, func:Function):void {
            if (!_functionMap.hasOwnProperty(type))
                _functionMap[type] = func;
            else
                throw new Error("type already exist");
        }

        public static function addChild(type:String, child:DisplayObject):void {
            var layer:Sprite = _layerMap[type] as Sprite;
            if (layer)
                layer.addChild(child);
            else
                throw new Error("layer do not exist");
        }

        public static function removeChild(type:String, child:DisplayObject):void {
            var layer:Sprite = _layerMap[type] as Sprite;
            if (layer)
                layer.removeChild(child);
            else
                throw new Error("layer do not exist");
        }

        public static function addChildAt(type:String, child:DisplayObject, index:int):void {
            var layer:Sprite = _layerMap[type] as Sprite;
            if (layer)
                layer.addChildAt(child, index);
            else
                throw new Error("layer do not exist");
        }

        public static function swapChildren(type:String, child1:DisplayObject, child2:DisplayObject):void {
            var layer:Sprite = _layerMap[type] as Sprite;
            if (layer)
                layer.swapChildren(child1, child2);
            else
                throw new Error("layer do not exist");
        }

        public static function call(type:String):Function {
            return _functionMap[type];
        }

        public static function getLayer(type:String):DisplayObject {
            return _layerMap[type];
        }
    }
}