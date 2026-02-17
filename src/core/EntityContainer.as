package core {
    import core.entities.*;
    import core.node.NodeType;

    import flash.geom.Point;

    import managers.Globals;

    import scenes.GameScene;

    import starling.errors.AbstractClassError;

    public class EntityContainer {
        public static var game:GameScene;
        public static var INDEX_SHIPS:int = 0;
        public static var INDEX_NODES:int = 1;
        public static var INDEX_AIS:int = 2;
        public static var INDEX_BEAMS:int = 3;
        public static var INDEX_DARKPLUSES:int = 4;

        private static var _entityPools:Vector.<EntityPool>;
        private static const _ENTITY_POOL_COUNT:int = 5;
        private static var _ready:Boolean = false;

        // #region 实体池
        public function EntityContainer() {
            throw new AbstractClassError();
        }

        private static function init():void {
            _entityPools = new Vector.<EntityPool>(_ENTITY_POOL_COUNT, true);
            _pointPool = new Vector.<Point>;
            for (var i:int = 0; i < _ENTITY_POOL_COUNT; i++)
                _entityPools[i] = new EntityPool();
            _ready = true;
        }

        public static function get entityPool():Vector.<EntityPool> {
            if (!_ready)
                init();
            return _entityPools;
        }

        public static function get ships():Vector.<GameEntity> {
            return _entityPools[INDEX_SHIPS].active;
        }

        public static function get nodes():Vector.<GameEntity> {
            return _entityPools[INDEX_NODES].active;
        }

        public static function get ais():Vector.<GameEntity> {
            return _entityPools[INDEX_AIS].active;
        }

        public static function addEntity(index:int, entity:GameEntity):void {
            if (!_ready)
                init();
            _entityPools[index].addEntity(entity);
        }

        public static function getReserve(index:int):GameEntity {
            if (!_ready)
                init();
            return _entityPools[index].getReserve();
        }

        // #endregion

        // #region 天体

        /** 搜寻范围内飞行中的飞船
         * @param node 目标天体
         * @param hostile 是否为敌对势力
         * @return 飞船数组
         */
        public static function findShipsInRange(node:Node, hostile:Boolean = true):Vector.<Ship> {
            // 预计算常用值
            var nodeX:Number = node.nodeData.x;
            var nodeY:Number = node.nodeData.y;
            var range:Number = node.attackState.attackRange;
            var rangeSquared:Number = range * range;
            var nodeTeamGroup:int = Globals.teamGroups[node.nodeData.team];
            // 重用结果数组
            var result:Vector.<Ship> = TEMP_SHIP_RESULT;
            result.length = 0;
            var allShips:Vector.<GameEntity> = ships;
            var shipCount:int = allShips.length;
            for (var i:int = 0; i < shipCount; i++) {
                var ship:Ship = allShips[i] as Ship;
                // 状态检查
                if (ship.state != 3 || ship.warping)
                    continue;
                // 势力检查
                var shipGroup:int = Globals.teamGroups[ship.team];
                if ((shipGroup == nodeTeamGroup) == hostile)
                    continue;
                // 快速距离检查（使用平方距离避免Math.sqrt）
                var dx:Number = ship.x - nodeX;
                if (dx > range || dx < -range)
                    continue;
                var dy:Number = ship.y - nodeY;
                if (dy > range || dy < -range)
                    continue;
                if (dx * dx + dy * dy < rangeSquared)
                    result[result.length] = ship;
            }
            return result;
        }

        private static var TEMP_SHIP_RESULT:Vector.<Ship> = new Vector.<Ship>();
        private static var TEMP_ARRAY:Array = new Array;

        /** 搜寻范围内的天体
         * @param centerNode 目标天体
         * @return 天体数组
         */
        public static function findNodeInRange(centerNode:Node):Array {
            var dx:Number;
            var dy:Number;
            var node:Node;
            var nodeInRange:Array = TEMP_ARRAY;
            var range:Number = centerNode.attackState.attackRange;
            nodeInRange.length = 0;
            for each (node in nodes) {
                dx = centerNode.nodeData.x - node.nodeData.x;
                dy = centerNode.nodeData.y - node.nodeData.y;
                if (dx > range || dx < -range || dy > range || dy < -range)
                    continue;
                if (Math.sqrt(dx * dx + dy * dy) < range)
                    nodeInRange.push(node);
            }
            return nodeInRange;
        }

        /** 检测目标天体是否在**指定天体**攻击范围内
         * @param centerNode 目标天体
         * @param team **指定天体**势力
         * @param type **指定天体**类型
         * @param hostile team是否特指其敌对的势力，默认为false
         * @return Boolean
         */
        public static function inAttackNodeCheck(centerNode:Node, team:int, type:String, hostile:Boolean = false):Boolean {
            var inRange:Boolean = false;
            var group:int = Globals.teamGroups[team];
            var node:Node;
            var dx:Number, dy:Number, range:Number;
            for each (node in nodes) {
                var nodeGroup:int = Globals.teamGroups[node.nodeData.team];
                if (hostile ? group == nodeGroup : group != nodeGroup) // 排除不符合是否敌对要求的
                    continue;
                if (node.nodeData.team == 0) // 排除中立天体
                    continue;
                if (node.nodeData.type != type) // 排除不符合类型要求的天体
                    continue;
                if (node == centerNode) // 排除检查天体本身
                    continue;

                dx = centerNode.nodeData.x - node.nodeData.x;
                dy = centerNode.nodeData.y - node.nodeData.y;
                range = node.attackState.attackRange;
                if (dx > range || dx < -range || dy > range || dy < -range)
                    continue;
                if (Math.sqrt(dx * dx + dy * dy) < range)
                    inRange = true;
            }
            return inRange;
        }

        /** 根据状态过滤天体上的飞船
         * @param node 目标天体
         * @param state 目标状态
         * @param output 返回值，传入后会自动清空元素
         * @return 二层数组
         */
        public static function filterShipByState(node:Node, state:int, output:Vector.<Vector.<Ship>>):void {
            for each (var vec:Vector.<Ship> in output)
                vec.length = 0;
            while (output.length < Globals.teamCount)
                output.push(new Vector.<Ship>);
            for (var i:int = 0; i < Globals.teamCount; i++)
                for each (var ship:Ship in node.ships[i])
                    if (ship.state == state)
                        output[i].push(ship);
        }

        // #endregion

        // #region 飞船
        public static function removeShipFromVector(vec:Vector.<Ship>, ship:Ship):void {
            var writeIndex:int = 0;
            for (var i:int = 0; i < vec.length; i++) {
                if (vec[i] == ship)
                    continue;
                if (writeIndex != i)
                    vec[writeIndex] = vec[i];
                writeIndex++;
            }
            vec.length = writeIndex; // 释放尾部元素
        }

        // #endregion

        // #region AI
        public static function getLengthInTowerRange(node1:Node, node2:Node, team:int):Number {
            var group:int = Globals.teamGroups[team];
            var node:Node = null;
            var start:Point = null;
            var end:Point = null;
            var current:Point = null;
            var length:Number = 0;
            var result:Array;
            var resultInside:Boolean;
            var resultIntersects:Boolean;
            var resultEnter:Point;
            var resultExit:Point;
            try {
                start = getPoint(node1.nodeData.x, node1.nodeData.y);
                end = getPoint(node2.nodeData.x, node2.nodeData.y);
                current = getPoint();
                for each (node in nodes) {
                    var nodeGroup:int = Globals.teamGroups[node.nodeData.team];
                    if (node.nodeData.team == 0 || nodeGroup == group)
                        continue;
                    if (node.nodeData.type == NodeType.TOWER || node.nodeData.type == NodeType.STARBASE || node.nodeData.type == NodeType.CAPTURESHIP) {
                        current.x = node.nodeData.x;
                        current.y = node.nodeData.y;
                        result = lineIntersectCircle(start, end, current, node.attackState.attackRange);
                        resultInside = result[0];
                        resultIntersects = result[1];
                        resultEnter = result[2];
                        resultExit = result[3];
                        if (resultIntersects) {
                            if (resultEnter && resultExit)
                                length += Point.distance(resultEnter, resultExit);
                            else if (resultEnter && !resultExit)
                                length += Point.distance(resultEnter, end);
                            else if (!resultEnter && resultExit)
                                length += Point.distance(start, resultExit);
                            else
                                length += Point.distance(start, end);
                        } else if (resultInside)
                            length += Point.distance(start, end);
                    }
                }
            } finally {
                returnPoint(start);
                returnPoint(end);
                returnPoint(current);
            }
            return length;
        }

        public static function isInBlackhole(node1:Node, node2:Node, team:int):Boolean {
            var group:int = Globals.teamGroups[team];
            var node:Node = null;
            var start:Point = null;
            var end:Point = null;
            var current:Point = null;
            var result:Array;
            var resultInside:Boolean;
            var resultIntersects:Boolean;
            var resultEnter:Point;
            var resultExit:Point;
            var inBlackhole:Boolean = false;
            try {
                start = getPoint(node1.nodeData.x, node1.nodeData.y);
                end = getPoint(node2.nodeData.x, node2.nodeData.y);
                current = getPoint();
                for each (node in nodes) {
                    var nodeGroup:int = Globals.teamGroups[node.nodeData.team];
                    if (node.nodeData.team == 0 || nodeGroup == group)
                        continue;
                    if (node.nodeData.type == NodeType.BLACKHOLE && (node.attackState.attackStrategy.attacking || node.attackState.attackStrategy.attackTimer < 1)) {
                        current.x = node.nodeData.x;
                        current.y = node.nodeData.y;
                        result = lineIntersectCircle(start, end, current, node.attackState.attackRange);
                        resultInside = result[0];
                        resultIntersects = result[1];
                        resultEnter = result[2];
                        resultExit = result[3];
                        if (resultIntersects || resultInside) {
                            inBlackhole = true;
                            break;
                        }
                    }
                }
            } finally {
                returnPoint(start);
                returnPoint(end);
                returnPoint(current);
            }
            return inBlackhole;
        }

        public static function lineIntersectCircle(pointA:Point, pointB:Point, circleCenter:Point, circleRadius:Number = 1):Array {
            var discriminant:Number = NaN;
            var intersectionParam1:Number = NaN;
            var intersectionParam2:Number = NaN;
            var resultInside:Boolean = false;
            var resultIntersects:Boolean = false;
            var resultEnter:Point = null;
            var resultExit:Point = null;
            var lineSegmentLengthSquared:Number = (pointB.x - pointA.x) * (pointB.x - pointA.x) + (pointB.y - pointA.y) * (pointB.y - pointA.y);
            var lineConstant:Number = 2 * ((pointB.x - pointA.x) * (pointA.x - circleCenter.x) + (pointB.y - pointA.y) * (pointA.y - circleCenter.y));
            var circleConstant:Number = circleCenter.x * circleCenter.x + circleCenter.y * circleCenter.y + pointA.x * pointA.x + pointA.y * pointA.y - 2 * (circleCenter.x * pointA.x + circleCenter.y * pointA.y) - circleRadius * circleRadius;
            try {
                if (lineConstant * lineConstant - 4 * lineSegmentLengthSquared * circleConstant <= 0) {
                    resultInside = false;
                } else {
                    discriminant = Math.sqrt(lineConstant * lineConstant - 4 * lineSegmentLengthSquared * circleConstant);
                    intersectionParam1 = (-lineConstant + discriminant) / (2 * lineSegmentLengthSquared);
                    intersectionParam2 = (-lineConstant - discriminant) / (2 * lineSegmentLengthSquared);
                    if ((intersectionParam1 < 0 || intersectionParam1 > 1) && (intersectionParam2 < 0 || intersectionParam2 > 1)) {
                        resultInside = !((intersectionParam1 < 0 && intersectionParam2 < 0) || (intersectionParam1 > 1 && intersectionParam2 > 1))
                    } else {
                        if (0 <= intersectionParam2 && intersectionParam2 <= 1) {
                            resultEnter = getPoint();
                            resultEnter.x = pointA.x + intersectionParam2 * (pointB.x - pointA.x);
                            resultEnter.y = pointA.y + intersectionParam2 * (pointB.y - pointA.y);
                        }
                        if (0 <= intersectionParam1 && intersectionParam1 <= 1) {
                            resultExit = getPoint();
                            resultExit.x = pointA.x + intersectionParam1 * (pointB.x - pointA.x);
                            resultExit.y = pointA.y + intersectionParam1 * (pointB.y - pointA.y);
                        }
                        resultIntersects = true;
                    }
                }
            } finally {
                returnPoint(resultEnter);
                returnPoint(resultExit);
            }
            return [resultInside, resultIntersects, resultEnter, resultExit];
        }

        // #endregion

        // #region 其他

        /** 计算两条线的交点
         * @param p1x p1y p2x p2y 第一条线的两端点
         * @param p3x p3y p4x p4y 第二条线的两端点
         * @param output 输出值，若存在则不创建新对象
         * @return Point 或 null
         */
        public static function getIntersection(p1x:Number, p1y:Number, p2x:Number, p2y:Number, p3x:Number, p3y:Number, p4x:Number, p4y:Number, output:Point = null):Point {
            var dx1:Number = p2x - p1x;
            var dy1:Number = p2y - p1y;
            var dx2:Number = p4x - p3x;
            var dy2:Number = p4y - p3y;
            var denominator:Number = dy2 * dx1 - dx2 * dy1;
            if (Math.abs(denominator) < Number.MIN_VALUE)
                return null;
            var dx3:Number = p1x - p3x;
            var dy3:Number = p1y - p3y;
            var t:Number = (dx2 * dy3 - dy2 * dx3) / denominator;
            var u:Number = (dx1 * dy3 - dy1 * dx3) / denominator;
            if (t >= 0 && t <= 1 && u >= 0 && u <= 1) {
                if (output == null)
                    output = new Point();
                output.x = p1x + t * dx1;
                output.y = p1y + t * dy1;
                return output;
            }
            return null;
        }

        /**判断路径是否被拦截并计算拦截点
         * @param node1
         * @param node2
         * @param output 输出值，若存在则不创建新对象
         * @return Point 或 null
         */
        public static function nodesBlocked(node1:Node, node2:Node, output:Point = null):Point {
            var bar1x:Number, bar1y:Number, bar2x:Number, bar2y:Number;
            var intersection:Point = null;
            var i:int = 0;
            while (i < int(game.barrierLines.length)) {
                bar1x = game.barrierLines[i][0].nodeData.x;
                bar1y = game.barrierLines[i][0].nodeData.y;
                bar2x = game.barrierLines[i][1].nodeData.x;
                bar2y = game.barrierLines[i][1].nodeData.y;
                intersection = getIntersection(node1.nodeData.x, node1.nodeData.y, node2.nodeData.x, node2.nodeData.y, bar1x, bar1y, bar2x, bar2y, output);
                if (intersection)
                    return intersection;
                i++;
            }
            return null;
        }

        /** 判断路径是否被拦截并计算拦截点
         * @param x1 起点x
         * @param y1 起点y
         * @param x2 终点x
         * @param y2 终点y
         * @return Point 或 null
         */
        public static function lineBlocked(x1:Number, y1:Number, x2:Number, y2:Number):Point {
            var intersection:Point = null;
            var bar1x:Number, bar1y:Number, bar2x:Number, bar2y:Number;
            for each (var bar:Array in game.barrierLines) {
                bar1x = bar[0].nodeData.x;
                bar1y = bar[0].nodeData.y;
                bar2x = bar[1].nodeData.x;
                bar2y = bar[1].nodeData.y;
                intersection = getIntersection(x1, y1, x2, y2, bar1x, bar1y, bar2x, bar2y);
                if (intersection)
                    return intersection;
            }
            return null;
        }

        public static function lineSegmentsIntersect(ax1:Number, ay1:Number, ax2:Number, ay2:Number, bx1:Number, by1:Number, bx2:Number, by2:Number):Boolean {
            var d1:Number = (bx2 - bx1) * (ay1 - by1) - (by2 - by1) * (ax1 - bx1);
            var d2:Number = (bx2 - bx1) * (ay2 - by1) - (by2 - by1) * (ax2 - bx1);
            var d3:Number = (ax2 - ax1) * (by1 - ay1) - (ay2 - ay1) * (bx1 - ax1);
            var d4:Number = (ax2 - ax1) * (by2 - ay1) - (ay2 - ay1) * (bx2 - ax1);
            return (d1 * d2 <= 0) && (d3 * d4 <= 0);
        }

        public static function isBlocked(node1:Node, node2:Node):Boolean {
            var x1:Number = node1.nodeData.x;
            var y1:Number = node1.nodeData.y;
            var x2:Number = node2.nodeData.x;
            var y2:Number = node2.nodeData.y;
            for each (var bar:Array in game.barrierLines) {
                var bx1:Number = bar[0].nodeData.x;
                var by1:Number = bar[0].nodeData.y;
                var bx2:Number = bar[1].nodeData.x;
                var by2:Number = bar[1].nodeData.y;
                if (lineSegmentsIntersect(x1, y1, x2, y2, bx1, by1, bx2, by2)) {
                    return true;
                }
            }
            return false;
        }

        // #endregion

        // #region point对象池

        private static var _pointPool:Vector.<Point> = new Vector.<Point>();
        private static var _pointPoolIndex:int = 0;
        private static const MAX_POOL_SIZE:int = 64; // 可根据需要调整

        /**
         * 从对象池获取一个Point对象
         * @param x 初始x坐标，默认为0
         * @param y 初始y坐标，默认为0
         * @return Point对象
         */
        public static function getPoint(x:Number = 0, y:Number = 0):Point {
            if (_pointPoolIndex > 0) {
                // 从池中取出
                _pointPoolIndex--;
                var point:Point = _pointPool[_pointPoolIndex];
                point.x = x;
                point.y = y;
                _pointPool[_pointPoolIndex] = null; // 清空引用，避免重复使用
                return point;
            } else {
                // 池为空，创建新对象
                return new Point(x, y);
            }
        }

        /**
         * 归还Point对象到池中
         * @param point 要归还的Point对象
         */
        public static function returnPoint(point:Point):void {
            if (!point)
                return;

            if (_pointPoolIndex < MAX_POOL_SIZE) {
                // 重置Point
                point.x = 0;
                point.y = 0;
                _pointPool[_pointPoolIndex] = point;
                _pointPoolIndex++;
            }
            // 如果池已满，则丢弃该对象，让GC回收
        }

        /**
         * 清空Point对象池
         */
        public static function clearPointPool():void {
            for (var i:int = 0; i < _pointPoolIndex; i++)
                _pointPool[i] = null;
            _pointPoolIndex = 0;
        }

        // #endregion


    }
}
