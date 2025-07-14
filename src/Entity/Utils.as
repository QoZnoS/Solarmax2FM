package Entity {
    import Entity.*;
    import Game.GameScene;
    import starling.errors.AbstractClassError;
    import flash.geom.Point;

    public class Utils {
        public static var game:GameScene;

        public function Utils() {
            throw new AbstractClassError();
        }

        // #region 天体
        /** 搜寻范围内飞行中的飞船
         * @param _node 目标天体
         * @param _hostile 是否为敌对势力
         * @return 飞船数组
         */
        public static function findShipsInRange(_node:Node, _hostile:Boolean = true):Array {
            var dx:Number;
            var dy:Number;
            var ship:Ship;
            var shipinRange:Array = [];
            for each (ship in game.ships.active) {
                if (ship.state != 3 || ship.warping)
                    continue;
                if ((ship.team == _node.team) == _hostile)
                    continue; // 建议势力
                dx = ship.x - _node.x;
                dy = ship.y - _node.y;
                if (dx > _node.attackStrategy.attackRange || dx < -_node.attackStrategy.attackRange || dy > _node.attackStrategy.attackRange || dy < -_node.attackStrategy.attackRange)
                    continue;
                if (Math.sqrt(dx * dx + dy * dy) < _node.attackStrategy.attackRange)
                    shipinRange.push(ship);
            }
            return shipinRange;
        }

        /** 搜寻范围内的天体
         * @param _node 目标天体
         * @return 天体数组
         */
        public static function findNodeInRange(_node:Node):Array {
            var dx:Number;
            var dy:Number;
            var node:Node;
            var nodeInRange:Array = [];
            for each (node in game.nodes.active) {
                dx = node.x - _node.x;
                dy = node.y - _node.y;
                if (dx > _node.attackStrategy.attackRange || dx < -_node.attackStrategy.attackRange || dy > _node.attackStrategy.attackRange || dy < -_node.attackStrategy.attackRange)
                    continue;
                if (Math.sqrt(dx * dx + dy * dy) < _node.attackStrategy.attackRange)
                    nodeInRange.push(node);
            }
            return nodeInRange;
        }

        /** 根据状态过滤天体上的飞船
         * @param _node 目标天体
         * @param _state 目标状态
         * @return 二层数组
         */
        public static function filterShipByStatic(_node:Node, _state:int):Array {
            var ships:Array = [];
            for each (var shipArr:Array in _node.ships) {
                var filterArr:Array = [];
                for each (var ship:Ship in shipArr) {
                    if (ship.state == _state)
                        filterArr.push(ship);
                }
                ships.push(filterArr);
            }
            return ships;
        }
        // #endregion

        // #region 飞船

        // #endregion

        // #region AI

        // #endregion

        // #region 元素控制
        /** 移除数组中的指定元素
         * @param arr 目标数组
         * @param element 目标元素
         */
        public static function removeElementFromArray(arr:Array, element:*):void {
            for (var i:int = arr.length - 1; i >= 0; i--)
                if (arr[i] == element)
                    arr.splice(i, 1);
        }
        // #endregion

        // #region 绘图

        // #endregion

        // #region 其他

        /** 计算两条线的交点
         * @param _p1x _p1y _p2x _p2y 第一条线的两端点
         * @param _p3x _p3y _p4x _p4y 第二条线的两端点
         * @return Point 或 null
         */
        public static function getIntersection(_p1x:Number, _p1y:Number, _p2x:Number, _p2y:Number, _p3x:Number, _p3y:Number, _p4x:Number, _p4y:Number):Point {
            var l1dx:Number = _p2x - _p1x;
            var l1dy:Number = _p2y - _p1y;
            var l2dx:Number = _p4x - _p3x;
            var l2dy:Number = _p4y - _p3y;
            var ratio1:Number = (-l1dy * (_p1x - _p3x) + l1dx * (_p1y - _p3y)) / (-l2dx * l1dy + l1dx * l2dy);
            var ratio2:Number = (l2dx * (_p1y - _p3y) - l2dy * (_p1x - _p3x)) / (-l2dx * l1dy + l1dx * l2dy);
            if (ratio1 >= 0 && ratio1 <= 1 && ratio2 >= 0 && ratio2 <= 1)
                return new Point(_p1x + ratio2 * l1dx, _p1y + ratio2 * l1dy);
            return null;
        }

        /** 按指定 static 过滤数组中的元素，返回被过滤的元素数组
         * <p>元素必须包含 static 属性
         * @param _arr 目标数组
         * @param _static 目标状态
         * @return 被过滤的元素组成的数组
         */
        public static function fliterByStatic(_arr:Array, _state:int):Array{
            var fliterArr:Array = [];
            for (var i:int = 0; i < _arr.length; i++){
                if (_arr[i].state != _state)
                    continue
                fliterArr.push(_arr[i]);
                _arr.removeAt(i);
                i--;
            }
            return fliterArr;
        }

        // #endregion
    }
}
