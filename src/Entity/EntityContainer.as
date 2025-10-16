package Entity {
    import Entity.*;
    import Game.GameScene;
    import starling.errors.AbstractClassError;
    import flash.geom.Point;
    import Entity.Node.NodeType;
    import Entity.FX.WarpFX;
    import Entity.FX.BeamFX;
    import Entity.FX.NodePulse;
    import Entity.FX.FlashFX;
    import Entity.FX.BarrierFX;
    import Entity.FX.DarkPulse;
    import Entity.FX.SelectFade;

    public class EntityContainer {
        public static var game:GameScene;
        public static var INDEX_SHIPS:int = 0;
        public static var INDEX_NODES:int = 1;
        public static var INDEX_AIS:int = 2;
        public static var INDEX_WARPS:int = 3;
        public static var INDEX_BEAMS:int = 4;
        public static var INDEX_PULSES:int = 5;
        public static var INDEX_FLASHES:int = 6;
        public static var INDEX_BARRIERS:int = 7;
        public static var INDEX_EXPLOSIONS:int = 8;
        public static var INDEX_DARKPLUSES:int = 9;
        public static var INDEX_FADES:int = 10;

        private static var _entityPools:Vector.<EntityPool>;
        private static const _ENTITY_POOL_COUNT:int = 11;
        private static var _ready:Boolean = false;

        // #region 实体池
        public function EntityContainer() {
            throw new AbstractClassError();
        }

        private static function init():void{
            _entityPools = new Vector.<EntityPool>(11, true);
            for(var i:int = 0; i < _ENTITY_POOL_COUNT; i++)
                _entityPools[i] = new EntityPool();
            _ready = true;
        }

        public static function get entityPool():Vector.<EntityPool>{
            if (!_ready)
                init();
            return _entityPools;
        }

        public static function get ships():Vector.<Ship>{
            return Vector.<Ship>(_entityPools[INDEX_SHIPS].active);
        }

        public static function get nodes():Vector.<Node>{
            return Vector.<Node>(_entityPools[INDEX_NODES].active);
        }

        public static function get ais():Vector.<EnemyAI>{
            return Vector.<EnemyAI>(_entityPools[INDEX_AIS].active);
        }

        public static function get warps():Vector.<WarpFX>{
            return Vector.<WarpFX>(_entityPools[INDEX_WARPS].active);
        }

        public static function get beams():Vector.<BeamFX>{
            return Vector.<BeamFX>(_entityPools[INDEX_BEAMS].active);
        }

        public static function get pulses():Vector.<NodePulse>{
            return Vector.<NodePulse>(_entityPools[INDEX_PULSES].active);
        }

        public static function get flashes():Vector.<FlashFX>{
            return Vector.<FlashFX>(_entityPools[INDEX_FLASHES].active);
        }

        public static function get barriers():Vector.<BarrierFX>{
            return Vector.<BarrierFX>(_entityPools[INDEX_BARRIERS].active);
        }

        public static function get darkPulses():Vector.<DarkPulse>{
            return Vector.<DarkPulse>(_entityPools[INDEX_DARKPLUSES].active);
        }

        public static function get fades():Vector.<SelectFade>{
            return Vector.<SelectFade>(_entityPools[INDEX_FADES].active);
        }

        public static function addEntity(index:int, entity:GameEntity):void{
            if (!_ready)
                init();
            _entityPools[index].addEntity(entity);
        }

        public static function getReserve(index:int):GameEntity{
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
            var dx:Number;
            var dy:Number;
            var ship:Ship;
            var shipinRange:Vector.<Ship> = new Vector.<Ship>;
            for each (ship in ships) {
                if (ship.state != 3 || ship.warping)
                    continue;
                if ((ship.team == node.nodeData.team) == hostile)
                    continue; // 建议势力
                dx = ship.x - node.nodeData.x;
                dy = ship.y - node.nodeData.y;
                if (dx > node.attackState.attackRange || dx < -node.attackState.attackRange || dy > node.attackState.attackRange || dy < -node.attackState.attackRange)
                    continue;
                if (Math.sqrt(dx * dx + dy * dy) < node.attackState.attackRange)
                    shipinRange.push(ship);
            }
            return shipinRange;
        }

        /** 搜寻范围内的天体
         * @param centerNode 目标天体
         * @return 天体数组
         */
        public static function findNodeInRange(centerNode:Node):Array {
            var dx:Number;
            var dy:Number;
            var node:Node;
            var nodeInRange:Array = [];
            var range:Number = centerNode.attackState.attackRange;
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

        /** 根据状态过滤天体上的飞船
         * @param node 目标天体
         * @param state 目标状态
         * @return 二层数组
         */
        public static function filterShipByStatic(node:Node, state:int):Vector.<Vector.<Ship>> {
            var ships:Vector.<Vector.<Ship>> = new Vector.<Vector.<Ship>>;
            for each (var shipArr:Vector.<Ship> in node.ships) {
                var filterArr:Vector.<Ship> = new Vector.<Ship>;
                for each (var ship:Ship in shipArr) {
                    if (ship.state == state)
                        filterArr.push(ship);
                }
                ships.push(filterArr);
            }
            return ships;
        }
        // #endregion

        // #region 飞船
        public static function removeShipFromVector(vec:Vector.<Ship>, ship:Ship):void {
            for (var i:int = vec.length - 1; i >= 0; i--)
                if (vec[i] == ship)
                    vec.splice(i, 1);
        }

        // #endregion

        // #region AI
        public static function getLengthInTowerRange(node1:Node, node2:Node, team:int):Number {
            var node:Node = null;
            var start:Point = null;
            var end:Point = null;
            var current:Point = null;
            var length:Number = 0;
            var result:Array;
            var resultInside:Boolean; // 线是否在圆内
            var resultIntersects:Boolean; // 线和圆是否相交
            var resultEnter:Point; // 线和圆的第一个交点
            var resultExit:Point; // 线和圆的第二个交点
            for each (node in nodes) {
                if (node.nodeData.team == 0 || node.nodeData.team == team)
                    continue;
                if (node.nodeData.type == NodeType.TOWER || node.nodeData.type == NodeType.STARBASE || node.nodeData.type == NodeType.CAPTURESHIP) {
                    start = new Point(node1.nodeData.x, node1.nodeData.y);
                    end = new Point(node2.nodeData.x, node2.nodeData.y);
                    current = new Point(node.nodeData.x, node.nodeData.y);
                    result = lineIntersectCircle(start, end, current, node.attackState.attackRange);
                    resultInside = result[0],resultIntersects = result[1], resultEnter = result[2], resultExit = result[3];
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
            return length;
        }

        public static function lineIntersectCircle(pointA:Point, pointB:Point, circleCenter:Point, circleRadius:Number = 1):Array { // 判断线与圆的关系并返回交点
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
            if (lineConstant * lineConstant - 4 * lineSegmentLengthSquared * circleConstant <= 0)
                resultInside = false;
            else {
                discriminant = Math.sqrt(lineConstant * lineConstant - 4 * lineSegmentLengthSquared * circleConstant);
                intersectionParam1 = (-lineConstant + discriminant) / (2 * lineSegmentLengthSquared);
                intersectionParam2 = (-lineConstant - discriminant) / (2 * lineSegmentLengthSquared);
                if ((intersectionParam1 < 0 || intersectionParam1 > 1) && (intersectionParam2 < 0 || intersectionParam2 > 1)) {
                    if (intersectionParam1 < 0 && intersectionParam2 < 0 || intersectionParam1 > 1 && intersectionParam2 > 1)
                        resultInside = false;
                    else
                        resultInside = true;
                } else {
                    if (0 <= intersectionParam2 && intersectionParam2 <= 1)
                        resultEnter = Point.interpolate(pointA, pointB, 1 - intersectionParam2);
                    if (0 <= intersectionParam1 && intersectionParam1 <= 1)
                        resultExit = Point.interpolate(pointA, pointB, 1 - intersectionParam1);
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

        // #region 其他

        /** 计算两条线的交点
         * @param p1x p1y p2x p2y 第一条线的两端点
         * @param p3x p3y p4x p4y 第二条线的两端点
         * @return Point 或 null
         */
        public static function getIntersection(p1x:Number, p1y:Number, p2x:Number, p2y:Number, p3x:Number, p3y:Number, p4x:Number, p4y:Number):Point {
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
            if (t >= 0 && t <= 1 && u >= 0 && u <= 1)
                return new Point(p1x + t * dx1, p1y + t * dy1);
            return null;
        }

        /**判断路径是否被拦截并计算拦截点
         * @param node1 
         * @param node2 
         * @return Point 或 null
         */
        public static function nodesBlocked(node1:Node, node2:Node):Point {
            var bar1:Point = null;
            var bar2:Point = null;
            var intersection:Point = null;
            var i:int = 0;
            while (i < int(game.barrierLines.length)) {
                bar1 = game.barrierLines[i][0];
                bar2 = game.barrierLines[i][1];
                intersection = getIntersection(node1.nodeData.x, node1.nodeData.y, node2.nodeData.x, node2.nodeData.y, bar1.x, bar1.y, bar2.x, bar2.y);
                if (intersection)
                    return intersection;
                i++;
            }
            return null;
        }

        /** 按指定 static 过滤数组中的元素，返回被过滤的元素数组
         * <p>元素必须包含 static 属性
         * @param arr 目标数组
         * @param static 目标状态
         * @return 被过滤的元素组成的数组
         */
        public static function fliterByStatic(arr:Array, state:int):Array{
            var fliterArr:Array = [];
            for (var i:int = 0; i < arr.length; i++){
                if (arr[i].state != state)
                    continue
                fliterArr.push(arr[i]);
                arr.removeAt(i);
                i--;
            }
            return fliterArr;
        }

        /** 安全访问 XML 数据
         * <p>尝试访问指定路径的 XML 数据，若失败则返回默认值或抛出错误
         * @param xmlData 目标 XML 数据
         * @param path 访问路径
         * @param defaultValue 默认值
         * @return 访问结果
         */
        public static function safeXMLAccess(xmlData:XML, path:String, defaultValue:XMLList = null):XMLList {
            try {
                return xmlData..*.(name().localName == path);
            } catch (error:Error) {
                if (defaultValue != null)
                    return defaultValue;
                throw error;
            }
        }

        // #endregion
    }
}
