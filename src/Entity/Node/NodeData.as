package Entity.Node {
    import flash.utils.Dictionary;
    import Entity.Node;

    public dynamic class NodeData extends Dictionary {

        // 内部维护的属性列表
        private var _serializableProps:Object = {};

        public var x:Number; // 坐标x
        public var y:Number; // 坐标y
        public var team:int; // 势力
        public var size:Number; // 大小
        public var type:String; // 类型
        public var popVal:int; // 人口上限
        public var startShips:Vector.<int>; // 开局飞船，每一项对于各势力飞船数
        public var barrierLinks:Vector.<int>; // 障碍连接数组，储存相连天体tag
        public var orbitNode:int; // 轨道中心天体
        public var orbitSpeed:Number; // 轨道运转速度

        public var hp:Number; // 占领度，中立为0，被任意势力完全占领为100
        public var hpMult:Number; // 占领难度倍率
        public var lineDist:Number; // 选中圈大小
        public var touchDist:Number; // 传统操作模式下的选中圈大小

        public function NodeData(weakKeys:Boolean = false) {
            super(weakKeys);
            addSerializableProp("x", "y", "team", "size", "type", "popVal", "startShips", "barrierLinks", "orbitNode", "orbitSpeed");

            startShips = new Vector.<int>(Globals.teamCount);
            barrierLinks = new Vector.<int>;
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

            for each (var prop:String in keys)
                if (_serializableProps[prop] === true && !(this[prop] is Function))
                    output[prop] = this[prop];

            return output;
        }

        public static function deserialize(obj:Object):NodeData {
            var nodeData:NodeData = new NodeData();
            for (var prop:String in obj) {
                if (prop === "startShips" || prop === "barrierLinks") {
                    var array:Array = obj[prop] as Array;
                    var vector:Vector.<int> = new Vector.<int>();
                    for (var i:int = 0; i < array.length; i++)
                        vector.push(int(array[i]));
                    nodeData[prop] = vector;
                } else
                    nodeData[prop] = obj[prop];
            }
            return nodeData;
        }
        //#endregion
    }
}
