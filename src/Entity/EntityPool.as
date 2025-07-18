package Entity {
    public class EntityPool {
        /** 活跃实体 */
        public var active:Array;
        /** 保留实体 */
        public var reserve:Array;

        public function EntityPool() {
            super();
            active = [];
            reserve = [];
        }

        public function init():void {
        }

        /** 将活跃实体的元素倒序移入保留实体 */
        public function deInit():void {
            var _GameEntity:GameEntity = null;
            while (active.length > 0) {
                _GameEntity = active.pop(); // 删除活跃实体的最后一个元素，返回删去的元素
                _GameEntity.deInit(); // 执行对应实体中的deInit
                reserve.push(_GameEntity); // 将其添加到保留实体
            }
        }

        /** 添加实体 */
        public function addEntity(_Entity:GameEntity):void {
            active.push(_Entity); // 将传入参数添加至活跃实体
        }

        /** 移除并返回保留实体的最后一项 */
        public function getReserve():GameEntity {
            if (reserve.length > 0)
                return reserve.pop(); // 保留实体中有元素时移除并返回保留实体的最后一项
            return null;
        }

        /** 更新活跃实体数组，移出active为false的实体，执行active为true的实体的update() */
        public function update(_dt:Number):void {
            var _GameEntity:GameEntity = null;
            var l:int = int(active.length); // 活跃实体的总数
            var i:int = 0; // 遍历值，遍历活跃实体的项
            while (i < l) {
                _GameEntity = active[i];
                if (!_GameEntity.active) { // 若实体处于非活跃状态
                    _GameEntity.deInit(); // 执行该实体的deInit
                    reserve.push(_GameEntity); // 将其加入保留实体
                    active[i] = active[l - 1]; // 替换活跃实体的遍历项为最后一项
                    active.pop(); // 删去活跃实体的最后一项
                    l--;
                    i--;
                } else {
                    _GameEntity.update(_dt); // 执行该实体的update
                }
                i++;
            }
        }
    }
}
