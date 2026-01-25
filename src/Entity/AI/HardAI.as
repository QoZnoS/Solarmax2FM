package Entity.AI {
    import utils.Rng;
    import Entity.Node;
    import flash.geom.Point;
    import Entity.Node.NodeStaticLogic;
    import Entity.Node.NodeType;
    import Entity.EntityContainer;

    public class HardAI extends BasicAI {
        public function HardAI(rng:Rng, actionDelay:Number, startDelay:Number) {
            super(rng, actionDelay, startDelay);
        }

        override public function update(dt:Number):void {
            if (!updateTimer(dt))
                return;
            updateHard();
        }

        public function updateHard():void {
            var surrender:Boolean = true;
            for each (var node:Node in nodeArray) {
                if (node.nodeData.team == this.team)
                    surrender = false; // 有己方天体则不认输
            }
            if (surrender && Globals.teamPops[team] < 30)
                return;
            if (nodeArray[0].nodeData.type == NodeType.DILATOR && nodeArray[0].nodeData.team == team && nodeArray[0].hard_AllStrength(team) * 0.6 < nodeArray[0].hard_oppAllStrength(team)) {
                blackDefend();
                return;
            }
            attackV1();
        }

        public function attackV1():void {
            var nodeGroup:int = -1;
            var senderGroup:int = -1;
            var targetGroup:int = -1;
            var captureGroup:int = -1;
            var node:Node = null;
            var distance:Number = NaN;
            senders.length = 0;
            for each (node in nodeArray) { // 计算出兵天体
                nodeGroup = Globals.teamGroups[node.nodeData.team];
                if (!senderCheckBasic(node))
                    continue;
                if (node.hard_oppAllStrength(team) != 0 || node.conflict) { // (预)战争状态
                    if (node.hard_teamStrength(team) * 0.6 > node.hard_oppAllStrength(team)) {
                        if (nodeGroup != group && node.hard_teamStrength(team) < node.nodeData.size * 200)
                            continue; // 保留占据兵力
                        senders.push(node); // 己方过强时出兵（损失不到五分之一）
                        node.senderType = "overflow"; // 类型：兵力溢出
                    } else if (node.hard_AllStrength(team) < node.hard_oppAllStrength(team)) {
                        if (!node.hard_retreatCheck(team))
                            continue; // 战术撤退时机检测
                        senders.push(node); // 己方过弱时出兵
                        node.senderType = "retreat"; // 类型：战术撤退
                    }
                    continue;
                }
                if (node.capturing) {
                    if (node.nodeData.team == 0 && (100 - node.nodeData.hp) / node.captureState.captureRate < 0.5 && !node.nodeData.isWarp) {
                        senders.push(node); // 提前出兵
                        node.senderType = "attack"; // 类型：正常出兵
                    }
                    continue;
                }
                senders.push(node);
                node.senderType = "attackcom"; // 类型：正常出兵
            }
            if (senders.length == 0)
                return;
            targets.length = 0;
            for each (node in nodeArray) { // 计算目标天体
                nodeGroup = Globals.teamGroups[node.nodeData.team];
                captureGroup = Globals.teamGroups[node.captureState.captureTeam];
                if (!targetCheckBasic(node))
                    continue;
                if (node.hard_oppAllStrength(team) != 0) { // (预)战争状态
                    if (node.hard_AllStrength(team) * 0.866 < node.hard_oppAllStrength(team)) {
                        targets.push(node); // 己方强度不足时作为目标（损失超过一半）
                        node.targetType = "lack"; // 类型：兵力不足
                    }
                    continue;
                }
                if (node.nodeData.team == 0 && node.capturing && captureGroup == group && (100 - node.nodeData.hp) / node.captureState.captureRate < node.aiValue / 50)
                    continue; // 不向快占完的天体派兵
                if (nodeGroup == group && !node.nodeData.isWarp)
                    continue; // 除传送门不向己方天体派兵
                targets.push(node);
                node.targetType = "attack"; // 类型：正常目标
            }
            if (targets.length == 0)
                return;
            for each (var senderNode:Node in senders) { // 出兵
                senderGroup = Globals.teamGroups[senderNode.nodeData.team];
                for each (var targetNode:Node in targets) { // 先排序
                    distance = calcDistence(senderNode, targetNode) + rng.nextNumber() * 32;
                    targetNode.aiValue = distance * 0.8 + targetNode.hard_oppAllStrength(team);
                    if (targetNode.attackState.attackRate != 0)
                        targetNode.aiValue += getTowerAIValue();
                    if (targetNode.nodeData.type == NodeType.STARBASE)
                        targetNode.aiValue -= Globals.teamCaps[0];
                    if (targetNode.nodeData.isWarp)
                        targetNode.aiValue += getWarpAIValue();
                    var targetClose:Node = breadthFirstSearch(senderNode, targetNode);
                    if (!targetClose)
                        continue;
                    var towerAttack:Number = hard_getTowerAttackUltra(senderNode, targetClose);
                    targetNode.aiValue += towerAttack * 4; // 估损权重
                }
                targets.sortOn("aiValue", 16);
                for each (targetNode in targets) { // 再派兵
                    targetGroup = Globals.teamGroups[targetNode.nodeData.team];
                    targetClose = breadthFirstSearch(senderNode, targetNode);
                    if (!targetClose)
                        continue;
                    if (targetClose.nodeData.isWarp && senderNode.nodeData.isWarp && senderGroup == group)
                        continue; // 避免传送门之间反复横跳
                    var ships:Number = senderNode.hard_teamStrength(team);
                    if (senderNode.senderType == "overflow") {
                        if (senderGroup != group)
                            ships -= senderNode.nodeData.size * 200; // 尝试占领时减少派兵数量
                        ships -= Math.floor(senderNode.hard_oppAllStrength(team) * 1.667); // 兵力溢出时减少派兵数量
                    }
                    if (targetNode.targetType == "lack") {
                        if (targetGroup == group)
                            ships = Math.min(ships, Math.floor(targetNode.hard_oppAllStrength(team) * 1.2 - targetNode.hard_AllStrength(team)) + 4); // 目标兵力不足时防止派兵过度
                        else
                            ships = Math.min(ships, Math.floor(targetNode.hard_oppAllStrength(team) * 1.6 - targetNode.hard_AllStrength(team))); // 目标兵力不足时防止派兵过度
                    }
                    ships = Math.max(ships, ((hard_distance(senderNode, targetNode) * targetNode.buildState.buildRate / 50) * 1.2 + 3));
                    towerAttack = hard_getTowerAttackUltra(senderNode, targetClose);
                    if (towerAttack > 0 && ships < towerAttack + 30)
                        continue; // 派出的兵力不超估损30兵时不派兵
                    if (ships - towerAttack < targetNode.hard_oppAllStrength(team) - targetNode.hard_AllStrength(team))
                        continue; // 己方兵力不足敌方时不派兵
                    NodeStaticLogic.sendAIShips(senderNode, team, targetClose, ships);
                    // traceDebug("attackV1: " + senderNode.senderType + " " + senderNode.tag + " -> " + targetNode.tag + " " + targetNode.targetType + " ships: " + ships + " guessDieShips: " + towerAttack);
                    return;
                }
            }
        }

        public function blackDefend():void { // 回防
            var boss:Node = nodeArray[0];
            if (boss.conflict || boss.capturing) {
                for each (var node:Node in nodeArray) {
                    if (!senderCheckBasic(node) || !moveCheckBasic(node, boss))
                        continue;
                    if (boss.hard_AllStrength(team) * 0.6 < boss.hard_oppAllStrength(team))
                        NodeStaticLogic.sendAIShips(node, team, boss, node.hard_teamStrength(team)); // 回防
                }
            }
        }

        public function senderCheckBasic(node:Node):Boolean { // 判断能否出兵
            if (node.hard_teamStrength(team) == 0)
                return false; // 无己方飞船不出兵
            return true;
        }

        public function targetCheckBasic(node:Node):Boolean {
            if (node.nodeData.isAIinvisible)
                return false;
            return true;
        }

        public function moveCheckBasic(senderNode:Node, targetNode:Node):Boolean { // 移动判断
            var senderGroup:int = Globals.teamGroups[senderNode.nodeData.team];
            if (senderNode == targetNode)
                return false;
            if (senderNode.nodeData.isWarp && senderGroup == group)
                return true;
            else if (senderNode.nodeLinks[team].indexOf(targetNode) != -1)
                return true;
            return false;
        }

        public function getTowerAIValue():Number { // 计算攻击天体价值
            var capValue:Number = 0;
            for (var i:int = 1; i < Globals.teamCaps.length; i++) {
                capValue += Globals.teamCaps[i];
            }
            return (Globals.teamCaps[0] - capValue);
        }

        public function getWarpAIValue():Number { // 计算传送价值
            var nodeGroup:int = -1;
            var warpValue:Number = 0;
            for each (var node:Node in nodeArray) {
                nodeGroup = Globals.teamGroups[node.nodeData.team];
                warpValue += node.nodeData.popVal;
                if (node.nodeData.team != 0 && nodeGroup != group)
                    warpValue -= node.attackState.attackRange * 3.5;
            }
            return warpValue;
        }

        public function breadthFirstSearch(startNode:Node, targetNode:Node):Node { // 广度优先搜索，寻路算法
            if (startNode == targetNode)
                return null;
            if (moveCheckBasic(startNode, targetNode))
                return targetNode;
            clearbreadthFirstSearch();
            var queue:Array = new Array();
            queue.push(startNode);
            var visited:Array = new Array();
            visited.push(startNode);
            while (queue.length > 0) {
                var current:Node = queue.shift();
                for each (var next:Node in current.nodeLinks[team]) {
                    if (visited.indexOf(next) != -1 || !targetCheckBasic(next))
                        continue;
                    if (moveCheckBasic(current, next)) {
                        queue.push(next);
                        visited.push(next);
                        next.breadthFirstSearchNode = current;
                    }
                }
                if (visited.indexOf(targetNode) != -1) {
                    while (current.breadthFirstSearchNode != null) {
                        if (current.breadthFirstSearchNode == startNode)
                            return current;
                        current = current.breadthFirstSearchNode;
                    }
                }
            }
            return null;
        }

        public function calcDistence(startNode:Node, targetNode:Node):Number {
            // 计算寻路距离
            clearbreadthFirstSearch();
            if (startNode == targetNode)
                return 9999;
            if (moveCheckBasic(startNode, targetNode))
                return hard_distance(startNode, targetNode);
            var distance:Number = 0;
            var queue:Array = new Array();
            queue.push(startNode);
            var visited:Array = new Array();
            visited.push(startNode);
            while (queue.length > 0) {
                var current:Node = queue.shift();
                for each (var next:Node in current.nodeLinks[team]) {
                    if (visited.indexOf(next) != -1)
                        continue;
                    if (moveCheckBasic(current, next)) {
                        queue.push(next);
                        visited.push(next);
                        next.breadthFirstSearchNode = current;
                    }
                }
                if (visited.indexOf(targetNode) != -1) {
                    distance += hard_distance(current, targetNode);
                    while (current.breadthFirstSearchNode != null) {
                        distance += hard_distance(current, current.breadthFirstSearchNode);
                        if (current.breadthFirstSearchNode == startNode)
                            return distance;
                        current = current.breadthFirstSearchNode;
                    }
                }
            }
            return 9999;
        }

        public function clearbreadthFirstSearch():void { // 清除广度优先搜索父节点
            for each (var node:Node in nodeArray)
                node.breadthFirstSearchNode = null;
        }

        public function hard_getTowerAttack(node1:Node, node2:Node):Number { // 高精度估损
            var node1Group:int = Globals.teamGroups[node1.nodeData.team];
            var nodeGroup:int = -1;
            var node:Node = null;
            var start:Point = null;
            var end:Point = null;
            var current:Point = null;
            var length:Number = 0;
            var towerAttack:Number = 0;
            var result:Array;
            var resultInside:Boolean; // 线是否在圆内
            var resultIntersects:Boolean; // 线和圆是否相交
            var resultEnter:Point; // 线和圆的第一个交点
            var resultExit:Point; // 线和圆的第二个交点
            if (node1.nodeData.isWarp && node1Group == group)
                return 0; // 对传送门不执行该函数

            for each (node in nodeArray) {
                nodeGroup = Globals.teamGroups[node.nodeData.team];
                length = 0;
                if (node.nodeData.team == 0 || nodeGroup == group)
                    continue;
                if (node.attackState.attackRange != 0) {
                    start = new Point(node1.nodeData.x, node1.nodeData.y);
                    end = new Point(node2.nodeData.x, node2.nodeData.y);
                    current = new Point(node.nodeData.x, node.nodeData.y);
                    result = EntityContainer.lineIntersectCircle(start, end, current, node.attackState.attackRange);
                    resultInside = result[0], resultIntersects = result[1], resultEnter = result[2], resultExit = result[3];
                    if (resultIntersects) {
                        if (!resultEnter)
                            resultEnter = start;
                        if (!resultExit)
                            resultExit = end;
                        length += Point.distance(resultEnter, resultExit);
                    } else if (resultInside)
                        length += Point.distance(start, end);
                    if (node.nodeData.type == NodeType.TOWER || node.nodeData.type == NodeType.STARBASE || node.nodeData.type == NodeType.CAPTURESHIP)
                        towerAttack += (length / Globals.teamShipSpeeds[team]) / node.attackState.attackRate;
                }
            }

            return Math.floor(towerAttack);
        }

        public function hard_getTowerAttackUltra(node1:Node, node2:Node):Number {
            if (node1.nodeData.isWarp && Globals.teamGroups[node1.nodeData.team] == group) {
                return 0;
            }

            // 所有变量声明在函数顶部
            var teamGroups:Array = Globals.teamGroups;
            var teamShipSpeed:Number = Globals.teamShipSpeeds[team];
            var node1TeamGroup:int = teamGroups[node1.nodeData.team];
            var startX:Number = node1.nodeData.x;
            var startY:Number = node1.nodeData.y;
            var endX:Number = node2.nodeData.x;
            var endY:Number = node2.nodeData.y;
            var dx:Number = endX - startX;
            var dy:Number = endY - startY;
            var segLengthSquared:Number = dx * dx + dy * dy;
            var segmentLength:Number = Math.sqrt(segLengthSquared);
            var towerAttack:Number = 0;

            // 预先计算所有攻击型节点的攻击参数
            var nodes:Vector.<Node> = nodeArray;
            var nodeCount:int = nodes.length;

            // 预筛选节点，只处理敌方攻击节点
            for (var i:int = 0; i < nodeCount; i++) {
                var node:Node = nodes[i];
                var nodeData:Object = node.nodeData;

                // 快速跳过条件
                if (nodeData.team == 0)
                    continue;
                if (teamGroups[nodeData.team] == group)
                    continue;

                var nodeType:String = nodeData.type;
                if (nodeType != NodeType.TOWER && nodeType != NodeType.STARBASE && nodeType != NodeType.CAPTURESHIP)
                    continue;

                var attackState:Object = node.attackState;
                var attackRange:Number = attackState.attackRange;
                if (attackRange <= 0)
                    continue;

                // 使用内联的快速几何判断
                var centerX:Number = nodeData.x;
                var centerY:Number = nodeData.y;
                var radiusSquared:Number = attackRange * attackRange;

                // 计算圆心到起点的向量
                var cx:Number = centerX - startX;
                var cy:Number = centerY - startY;

                // 计算投影参数
                var t:Number = (cx * dx + cy * dy) / segLengthSquared;
                t = t < 0 ? 0 : (t > 1 ? 1 : t);

                // 计算最近点距离平方
                var closestX:Number = startX + t * dx;
                var closestY:Number = startY + t * dy;
                var distX:Number = centerX - closestX;
                var distY:Number = centerY - closestY;
                var distSquared:Number = distX * distX + distY * distY;

                // 如果不相交，跳过
                if (distSquared > radiusSquared)
                    continue;

                // 计算重叠长度
                var length:Number = 0;

                // 检查是否完全在圆内
                var startDistSquared:Number = cx * cx + cy * cy;
                var endDistSquared:Number = (centerX - endX) * (centerX - endX) + (centerY - endY) * (centerY - endY);

                if (startDistSquared <= radiusSquared && endDistSquared <= radiusSquared) {
                    length = segmentLength;
                } else {
                    // 计算半弦长
                    var halfChordLength:Number = Math.sqrt(radiusSquared - distSquared);
                    var dt:Number = halfChordLength / segmentLength;
                    var t1:Number = t - dt;
                    var t2:Number = t + dt;

                    t1 = t1 < 0 ? 0 : (t1 > 1 ? 1 : t1);
                    t2 = t2 < 0 ? 0 : (t2 > 1 ? 1 : t2);

                    length = (t2 - t1) * segmentLength;
                }

                if (length > 0) {
                    towerAttack += (length / teamShipSpeed) / attackState.attackRate;
                }
            }

            return Math.floor(towerAttack);
        }

        public function hard_distance(node1:Node, node2:Node):Number { // 计算天体距离
            var dx:Number = node2.nodeData.x - node1.nodeData.x;
            var dy:Number = node2.nodeData.y - node1.nodeData.y;
            return Math.sqrt(dx * dx + dy * dy);
        }

        override public function get type():String {
            return EnemyAIFactory.HARD;
        }
    }
}
