package Entity.Node {

    public class NodeType {
        public static const PLANET:String = "planet";
        public static const WARP:String = "warp";
        public static const HABITAT:String = "habitat";
        public static const BARRIER:String = "barrier";
        public static const TOWER:String = "tower";
        public static const DILATOR:String = "dilator";
        public static const STARBASE:String = "starbase";
        public static const PULSECANNON:String = "pulsecannon";
        public static const BLACKHOLE:String = "blackhole";
        public static const CLONETURRET:String = "cloneturret";
        public static const CAPTURESHIP:String = "captureship";

        /**仅用于兼容部分原版函数
         * @param type
         * @return
         */
        public static function switchType(type:int):String {
            switch (type) {
                case 0:
                    return PLANET;
                case 1:
                    return WARP;
                case 2:
                    return HABITAT;
                case 3:
                    return BARRIER;
                case 4:
                    return TOWER;
                case 5:
                    return DILATOR;
                case 6:
                    return STARBASE;
                case 7:
                    return PULSECANNON;
                case 8:
                    return BLACKHOLE;
                case 9:
                    return CLONETURRET;
                case 10:
                    return CAPTURESHIP;
                default:
                    throw new Error("Node type not register");
            }
        }

        /** 获取默认天体大小 */
        public static function getDefaultSize(type:String):Number {
            return LevelData.nodeData.node.(@name == type).defaultSize;
        }

        /** 获取默认人口上限 */
        public static function getDefaultPopVal(type:String, size:Number = undefined):Number {
            if (size)
                return sliceGet(LevelData.nodeData.node.(@name == type).popVal, size);
            return sliceGet(LevelData.nodeData.node.(@name == type).popVal, getDefaultSize(type));
        }

        /** 获取默认初始人口 */
        public static function getDefaultStartVal(type:String, size:Number = undefined):Number {
            if (size)
                return sliceGet(LevelData.nodeData.node.(@name == type).startVal, size);
            return sliceGet(LevelData.nodeData.node.(@name == type).startVal, getDefaultSize(type));
        }

        /** 获取默认生产速度 */
        public static function getDefaultBuildRate(type:String, size:Number = undefined):Number {
            if (size)
                return sliceGet(LevelData.nodeData.node.(@name == type).buildRate, size);
            return sliceGet(LevelData.nodeData.node.(@name == type).buildRate, getDefaultSize(type));
        }

        /** 获取默认占领度倍率 */
        public static function getDefaultHpMult(type:String, size:Number = undefined):Number {
            if (size)
                return sliceGet(LevelData.nodeData.node.(@name == type).hpMult, size);
            return sliceGet(LevelData.nodeData.node.(@name == type).hpMult, getDefaultSize(type));
        }

        /** 获取默认贴图缩放 */
        public static function getDefaultScale(type:String, size:Number = undefined):Number {
            if (size)
                return sliceGet(LevelData.nodeData.node.(@name == type).scale, size);
            return sliceGet(LevelData.nodeData.node.(@name == type).scale, getDefaultSize(type));
        }

        /** 获取默认攻击间隔 */
        public static function getDefaultAttackRate(type:String, size:Number = undefined):Number {
            if (size)
                return sliceGet(LevelData.nodeData.node.(@name == type).attackRate, size);
            return sliceGet(LevelData.nodeData.node.(@name == type).attackRate, getDefaultSize(type));
        }

        /** 获取默认攻击范围 */
        public static function getDefaultAttackRange(type:String, size:Number = undefined):Number {
            if (size)
                return sliceGet(LevelData.nodeData.node.(@name == type).attackRange, size);
            return sliceGet(LevelData.nodeData.node.(@name == type).attackRange, getDefaultSize(type));
        }

        /** 获取默认攻击持续时间 */
        public static function getDefaultAttackLast(type:String, size:Number = undefined):Number {
            if (size)
                return sliceGet(LevelData.nodeData.node.(@name == type).attackLast, size);
            return sliceGet(LevelData.nodeData.node.(@name == type).attackLast, getDefaultSize(type));
        }

        /** 获取默认攻击方式 */
        public static function getDefaultAttackType(type:String):String {
            return LevelData.nodeData.node.(@name == type).attackType;
        }

        /** 获取默认天体旋转角度 */
        public static function getDefaultRotation(type:String):Number {
            return Number(LevelData.nodeData.node.(@name == type).rotation);
        }

        /** 是否启用障碍 */
        public static function isBarrier(type:String):Boolean {
            return LevelData.nodeData.node.(@name == type).isBarrier == "true";
        }

        /** 是否启用传送 */
        public static function isWarp(type:String):Boolean {
            return LevelData.nodeData.node.(@name == type).isWarp == "true";
        }

        /** 是否可点击 */
        public static function isUntouchable(type:String):Boolean {
            return LevelData.nodeData.node.(@name == type).isUntouchable == "true";
        }

        /** 是否AI不可见 */
        public static function isAIinvisible(type:String):Boolean {
            return LevelData.nodeData.node.(@name == type).isAIinvisible == "true";
        }

        private static function sliceGet(get:String, size:Number):Number {
            return (get.indexOf("S*") != -1) ? Number(get.slice(2)) * size : Number(get);
        }
    }
}
