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
        public var startShips:Vector.<int>; // 开局飞船，每一项对于各势力飞船数
        public var barrierLinks:Vector.<int>; // 障碍连接数组，储存相连天体tag
        public var orbitNode:int = -1; // 轨道中心天体
        public var orbitSpeed:Number = 0.1; // 轨道运转速度
        public var rotation:Number = 0;

        public var isBarrier:Boolean = false; // 启用障碍
        public var isWarp:Boolean = false; // 启用传送
        public var isUntouchable:Boolean = false; // 不可选中
        public var isAIinvisible:Boolean = false; // AI不可见

        public var hp:Number; // 占领度，中立为0，被任意势力完全占领为100
        public var hpMult:Number; // 占领难度倍率
        public var lineDist:Number; // 选中圈大小

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

        public function deserialize(obj:Object):void {
            var array:Array;
            var vector:Vector.<int>;
            var i:int = 0;
            for (var prop:String in obj) {
                if (prop === "startShips" && !(obj[prop] is Array)) {
                    vector = new Vector.<int>(Globals.teamCount);
                    vector[team] = int(obj[prop]);
                    this[prop] = vector;
                } else if (obj[prop] is Array){
                    array = obj[prop] as Array;
                    vector = new Vector.<int>();
                    for (i = 0; i < array.length; i++)
                        vector.push(int(array[i]));
                    this[prop] = vector;
                } else
                    this[prop] = obj[prop];
            }

            if (!this.startShips)
                this.startShips = new Vector.<int>(Globals.teamCount);
            if (!this.barrierLinks)
                this.barrierLinks = new Vector.<int>();
        }
        //#endregion
    }
}
