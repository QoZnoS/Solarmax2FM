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

        /** 
         * 添加天体贴图
         * <p><code>node:Image</code>
         * <p><code>halo:Image</code>
         * <p><code>glow:Image</code>
         * <p><code>deepColor:Boolean</code>
         */
        public static const ADD_NODE:String = "addNode";

        private static var _layerMap:Dictionary = new Dictionary();
        private static var _functionMap:Dictionary = new Dictionary();

        /**注册自定义图层
         * @param type 图层名称
         * @param layerSprite 图层实体
         * <p><code>NodeStateFactory.registerState("invisible", NodeInvisibleState);</code>
         */
        public static function registerLayer(type:String, layerSprite:Sprite):void {
            if (!_layerMap.hasOwnProperty(type))
                _layerMap[type] = layerSprite as Sprite;
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

        public static function execute(type:String, ...args):* {
            var func:Function = _functionMap[type] as Function;
            if (func != null) {
                return func.apply(null, args);
            }
            return null;
        }

        public static function getLayer(type:String):Sprite {
            return _layerMap[type];
        }
    }
}