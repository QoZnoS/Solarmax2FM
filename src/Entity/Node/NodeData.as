package Entity.Node {
    import flash.utils.Dictionary;

    public dynamic class NodeData extends Dictionary {

        // 内部维护的属性列表
        private var _serializableProps:Object = {};

        public var x:Number; // 坐标x
        public var y:Number; // 坐标y
        public var team:int; // 势力
        public var size:Number; // 大小
        public var type:String; // 类型
        public var popVal:int; // 人口上限
        public var hp:Number; // 占领度，中立为0，被任意势力完全占领为100
        public var hpMult:Number; // 占领难度倍率
        public var lineDist:Number; // 选中圈大小
        public var touchDist:Number; // 传统操作模式下的选中圈大小
        
        public var buildRate:Number; // 生产速度，生产时间的倒数
        public var orbitNode:int; // 轨道中心天体tag
        public var orbitDist:Number; // 轨道半径
        public var orbitSpeed:Number; // 轨道运转速度
        public var attackStrategy:String; // 攻击方式
        public var startShips:Array; // 开局飞船，每一项对于各势力飞船数
        public var barrierLinks:Array; // 障碍连接数组，储存相连天体tag
        public var barrierCostom:Boolean; // 障碍是否为自定义连接

        public function NodeData(weakKeys:Boolean = false) {
            super(weakKeys);
            addSerializableProp("x", "y", "team", "size", "type", "popVal", "buildRate", "orbitNode", "orbitDist", "orbitSpeed", "hpMult", "attackStrategy", "hp", "startShips", "barrierLinks", "lineDist", "touchDist");
        }

        //#region 序列化
        /**添加可序列化属性（支持多个参数）
         * @param ...props 要添加的属性名
         */
        public function addSerializableProp(... props):void {
            for each (var prop:String in props) {
                _serializableProps[prop] = true;
            }
        }

        /**
         * 移除序列化属性（支持多个参数）
         * @param ...props 要移除的属性名
         */
        public function removeSerializableProp(... props):void {
            for each (var prop:String in props) {
                delete _serializableProps[prop];
            }
        }

        /**
         * 检查属性是否可序列化
         * @param prop 属性名
         * @return Boolean 是否可序列化
         */
        public function isSerializable(prop:String):Boolean {
            return _serializableProps[prop] === true;
        }

        public function toJSON(k:String):* {
            var output:Object = {};

            var keys:Array = [];
            for (var key:String in this)
                keys.push(key);

            var typeDesc:XML = flash.utils.describeType(this);
            var accList:XMLList = typeDesc..variable;
            for each (var acc:XML in accList) {
                var accName:String = acc.@name;
                if (keys.indexOf(accName) == -1)
                    keys.push(accName);
            }

            for each (var prop:String in keys) {
                if (_serializableProps[prop] === true && !(this[prop] is Function)) {
                    output[prop] = this[prop];
                }
            }
            return output;
        }
        //#endregion
    }
}
