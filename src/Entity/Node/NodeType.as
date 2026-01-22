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
        public static const DIFFUSION:String = "diffusion";

        // 缓存XML数据到更高效的数据结构
        private static var nodeDataCache:Object;
        private static var typeVectorCache:Vector.<String>;

        /**留着给旧版关卡文件参考
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
                case 11:
                    return DIFFUSION;
                default:
                    throw new Error("Node type not register");
            }
        }

        // 初始化缓存
        public static function init():void {
            var nodeXmlList:XMLList = LevelData.nodeData.node;
            nodeDataCache = {};
            typeVectorCache = new Vector.<String>();

            for each (var nodeXml:XML in nodeXmlList) {
                var typeName:String = String(nodeXml.@name);
                typeVectorCache.push(typeName);

                // 将XML数据转换为对象，避免后续频繁查询
                nodeDataCache[typeName] = {defaultSize: parseNumberValue(String(nodeXml.defaultSize)),
                        popVal: String(nodeXml.popVal),
                        startVal: String(nodeXml.startVal),
                        buildRate: String(nodeXml.buildRate),
                        hpMult: String(nodeXml.hpMult),
                        scale: String(nodeXml.scale),
                        attackRate: String(nodeXml.attackRate),
                        attackRange: String(nodeXml.attackRange),
                        attackLast: String(nodeXml.attackLast),
                        attackType: String(nodeXml.attackType),
                        rotation: parseNumberValue(String(nodeXml.rotation)),
                        isBarrier: String(nodeXml.isBarrier) == "true",
                        isWarp: String(nodeXml.isWarp) == "true",
                        isUntouchable: String(nodeXml.isUntouchable) == "true",
                        isAIinvisible: String(nodeXml.isAIinvisible) == "true"};
            }
        }

        public static function getTypeVector():Vector.<String> {
            return typeVectorCache;
        }

        /** 获取默认天体大小 */
        public static function getDefaultSize(type:String):Number {
            return getCachedValue(type, "defaultSize") as Number;
        }

        /** 获取默认人口上限 */
        public static function getDefaultPopVal(type:String, size:Number = undefined):Number {
            var popValStr:String = getCachedValue(type, "popVal") as String;
            return sliceGet(popValStr, size || getDefaultSize(type));
        }

        /** 获取默认初始人口 */
        public static function getDefaultStartVal(type:String, size:Number = undefined):Number {
            var startValStr:String = getCachedValue(type, "startVal") as String;
            return sliceGet(startValStr, size || getDefaultSize(type));
        }

        /** 获取默认生产速度 */
        public static function getDefaultBuildRate(type:String, size:Number = undefined):Number {
            var buildRateStr:String = getCachedValue(type, "buildRate") as String;
            return sliceGet(buildRateStr, size || getDefaultSize(type));
        }

        /** 获取默认占领度倍率 */
        public static function getDefaultHpMult(type:String, size:Number = undefined):Number {
            var hpMultStr:String = getCachedValue(type, "hpMult") as String;
            return sliceGet(hpMultStr, size || getDefaultSize(type));
        }

        /** 获取默认贴图缩放 */
        public static function getDefaultScale(type:String, size:Number = undefined):Number {
            var scaleStr:String = getCachedValue(type, "scale") as String;
            return sliceGet(scaleStr, size || getDefaultSize(type));
        }

        /** 获取默认攻击间隔 */
        public static function getDefaultAttackRate(type:String, size:Number = undefined):Number {
            var attackRateStr:String = getCachedValue(type, "attackRate") as String;
            return sliceGet(attackRateStr, size || getDefaultSize(type));
        }

        /** 获取默认攻击范围 */
        public static function getDefaultAttackRange(type:String, size:Number = undefined):Number {
            var attackRangeStr:String = getCachedValue(type, "attackRange") as String;
            return sliceGet(attackRangeStr, size || getDefaultSize(type));
        }

        /** 获取默认攻击持续时间 */
        public static function getDefaultAttackLast(type:String, size:Number = undefined):Number {
            var attackLastStr:String = getCachedValue(type, "attackLast") as String;
            return sliceGet(attackLastStr, size || getDefaultSize(type));
        }

        /** 获取默认攻击方式 */
        public static function getDefaultAttackType(type:String):String {
            return getCachedValue(type, "attackType") as String;
        }

        /** 获取默认天体旋转角度 */
        public static function getDefaultRotation(type:String):Number {
            return getCachedValue(type, "rotation") as Number;
        }

        /** 是否启用障碍 */
        public static function isBarrier(type:String):Boolean {
            return getCachedValue(type, "isBarrier") as Boolean;
        }

        /** 是否启用传送 */
        public static function isWarp(type:String):Boolean {
            return getCachedValue(type, "isWarp") as Boolean;
        }

        /** 是否可点击 */
        public static function isUntouchable(type:String):Boolean {
            return getCachedValue(type, "isUntouchable") as Boolean;
        }

        /** 是否AI不可见 */
        public static function isAIinvisible(type:String):Boolean {
            return getCachedValue(type, "isAIinvisible") as Boolean;
        }

        // 私有方法
        private static function getCachedValue(type:String, property:String):* {
            if (nodeDataCache && nodeDataCache[type])
                return nodeDataCache[type][property];
            // 回退机制：如果缓存中没有，使用原始XML查询
            return getFromXML(type, property);
        }

        private static function getFromXML(type:String, property:String):* {
            var nodeXml:XML = LevelData.nodeData.node.(@name == type)[0];
            if (!nodeXml)
                return null;

            var value:String = String(nodeXml[property]);
            switch (property) {
                case "isBarrier":
                case "isWarp":
                case "isUntouchable":
                case "isAIinvisible":
                    return value == "true";
                case "rotation":
                case "defaultSize":
                    return parseNumberValue(value);
                default:
                    return value;
            }
        }

        private static function parseNumberValue(str:String):Number {
            return str ? Number(str) : 0;
        }

        private static function sliceGet(get:String, size:Number):Number {
            if (!get)
                return 0;
            return (get.indexOf("S*") != -1) ? Number(get.slice(2)) * size : Number(get);
        }
    }
}
