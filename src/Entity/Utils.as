package Entity {
    import Entity.*;
    import Game.GameScene;
    import starling.errors.AbstractClassError;
    import flash.geom.Point;
    import Entity.Node.NodeType;

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
                if ((ship.team == _node.nodeData.team) == _hostile)
                    continue; // 建议势力
                dx = ship.x - _node.nodeData.x;
                dy = ship.y - _node.nodeData.y;
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
                dx = node.nodeData.x - _node.nodeData.x;
                dy = node.nodeData.y - _node.nodeData.y;
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
        public static function getLengthInTowerRange(_Node1:Node, _Node2:Node, team:int):Number {
            var _Node:Node = null;
            var _start:Point = null;
            var _end:Point = null;
            var _current:Point = null;
            var _Length:Number = 0;
            var result:Array;
            var resultInside:Boolean; // 线是否在圆内
            var resultIntersects:Boolean; // 线和圆是否相交
            var resultEnter:Point; // 线和圆的第一个交点
            var resultExit:Point; // 线和圆的第二个交点
            for each (_Node in game.nodes.active) {
                if (_Node.nodeData.team == 0 || _Node.nodeData.team == team)
                    continue;
                if (_Node.nodeData.type == NodeType.TOWER || _Node.nodeData.type == NodeType.STARBASE || _Node.nodeData.type == NodeType.CAPTURESHIP) {
                    _start = new Point(_Node1.nodeData.x, _Node1.nodeData.y);
                    _end = new Point(_Node2.nodeData.x, _Node2.nodeData.y);
                    _current = new Point(_Node.nodeData.x, _Node.nodeData.y);
                    result = lineIntersectCircle(_start, _end, _current, _Node.attackStrategy.attackRange);
                    resultInside = result[0],resultIntersects = result[1], resultEnter = result[2], resultExit = result[3];
                    if (resultIntersects) {
                        if (resultEnter && resultExit)
                            _Length += Point.distance(resultEnter, resultExit);
                        else if (resultEnter && !resultExit)
                            _Length += Point.distance(resultEnter, _end);
                        else if (!resultEnter && resultExit)
                            _Length += Point.distance(_start, resultExit);
                        else
                            _Length += Point.distance(_start, _end);
                    } else if (resultInside)
                        _Length += Point.distance(_start, _end);
                }
            }
            return _Length;
        }

        public static function lineIntersectCircle(_pointA:Point, _pointB:Point, _circleCenter:Point, _circleRadius:Number = 1):Array { // 判断线与圆的关系并返回交点
            var _discriminant:Number = NaN;
            var _intersectionParam1:Number = NaN;
            var _intersectionParam2:Number = NaN;
            var resultInside:Boolean = false;
            var resultIntersects:Boolean = false;
            var resultEnter:Point = null;
            var resultExit:Point = null;
            var _lineSegmentLengthSquared:Number = (_pointB.x - _pointA.x) * (_pointB.x - _pointA.x) + (_pointB.y - _pointA.y) * (_pointB.y - _pointA.y);
            var _lineConstant:Number = 2 * ((_pointB.x - _pointA.x) * (_pointA.x - _circleCenter.x) + (_pointB.y - _pointA.y) * (_pointA.y - _circleCenter.y));
            var _circleConstant:Number = _circleCenter.x * _circleCenter.x + _circleCenter.y * _circleCenter.y + _pointA.x * _pointA.x + _pointA.y * _pointA.y - 2 * (_circleCenter.x * _pointA.x + _circleCenter.y * _pointA.y) - _circleRadius * _circleRadius;
            if (_lineConstant * _lineConstant - 4 * _lineSegmentLengthSquared * _circleConstant <= 0)
                resultInside = false;
            else {
                _discriminant = Math.sqrt(_lineConstant * _lineConstant - 4 * _lineSegmentLengthSquared * _circleConstant);
                _intersectionParam1 = (-_lineConstant + _discriminant) / (2 * _lineSegmentLengthSquared);
                _intersectionParam2 = (-_lineConstant - _discriminant) / (2 * _lineSegmentLengthSquared);
                if ((_intersectionParam1 < 0 || _intersectionParam1 > 1) && (_intersectionParam2 < 0 || _intersectionParam2 > 1)) {
                    if (_intersectionParam1 < 0 && _intersectionParam2 < 0 || _intersectionParam1 > 1 && _intersectionParam2 > 1)
                        resultInside = false;
                    else
                        resultInside = true;
                } else {
                    if (0 <= _intersectionParam2 && _intersectionParam2 <= 1)
                        resultEnter = Point.interpolate(_pointA, _pointB, 1 - _intersectionParam2);
                    if (0 <= _intersectionParam1 && _intersectionParam1 <= 1)
                        resultExit = Point.interpolate(_pointA, _pointB, 1 - _intersectionParam1);
                    resultIntersects = true;
                }
            }
            return [resultInside, resultIntersects, resultEnter, resultExit]
        }
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

        /**判断路径是否被拦截并计算拦截点
         * @param _Node1 
         * @param _Node2 
         * @return Point 或 null
         */
        public static function nodesBlocked(_Node1:Node, _Node2:Node):Point {
            if (_Node1.nodeData.type == NodeType.WARP)
                return null; // 对传送门不执行该函数
            var _bar1:Point = null;
            var _bar2:Point = null;
            var _Intersection:Point = null;
            var i:int = 0;
            while (i < int(game.barrierLines.length)) {
                _bar1 = game.barrierLines[i][0];
                _bar2 = game.barrierLines[i][1];
                _Intersection = getIntersection(_Node1.nodeData.x, _Node1.nodeData.y, _Node2.nodeData.x, _Node2.nodeData.y, _bar1.x, _bar1.y, _bar2.x, _bar2.y);
                if (_Intersection)
                    return _Intersection;
                i++;
            }
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
