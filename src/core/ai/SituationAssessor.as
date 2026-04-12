package core.ai
{
    import core.entities.Node;
    import core.entities.GameEntity;
    import core.EntityContainer;
    import core.node.NodeStaticLogic;
    import managers.Globals;
    import core.entities.Ship;
    import core.node.NodeData;

    public class SituationAssessor
    {

        /**
         * 返回飞船数最多的敌对队伍的总飞船数
         * @param node 目标天体
         * @param team AI势力
         * @param attributed 是否考虑属性（攻击力×防御力的平方根），默认为 true
         * @return 敌对队伍中最大的综合强度值
         */
        public static function oppStrength(node:Node, team:int, attributed:Boolean = true):int {
            var strength:int = 0;
            var ships:Vector.<Vector.<Ship>> = node.ships;
            var group:int = Globals.teamGroups[team];
            var groupStrengths:Vector.<int> = new Vector.<int>(Globals.teamCount);
            for (var i:int = 0; i < ships.length; i++) {
                var oppGroup:Number = Globals.teamGroups[i];
                if (oppGroup == group)
                    continue;
                groupStrengths[oppGroup] += ships[i].length;
                if (attributed)
                    groupStrengths[oppGroup] *= Math.sqrt(Globals.teamShipAttacks[i] * Globals.teamShipDefences[i])
            }
            for each (i in groupStrengths)
                strength = Math.max(i, strength);
            return strength;
        }

        /**
         * 估算后续可能面对的非指定势力方最快占领速度
         * @param node 目标天体
         * @param team AI势力
         * @param attributed 是否考虑属性，默认为 true
         * @return 预测的敌对占领风险值
         */
        public static function predictedOppCaptureRisk(node:Node, team:int, attributed:Boolean = true):Number {
            var risk:Number = 0;
            var ships:Vector.<Vector.<Ship>> = node.ships;
            var group:int = Globals.teamGroups[team];
            var groupRisks:Vector.<int> = new Vector.<int>(Globals.teamCount);
            for (var i:int = 0; i < ships.length; i++) {
                var oppGroup:int = Globals.teamGroups[i];
                if (oppGroup == group)
                    continue;
                var addRisk:Number = (ships[i].length + node.transitShips[i]);
                if (attributed)
                    addRisk *= Globals.teamDestroyingSpeeds[i];
                groupRisks[oppGroup] += addRisk;
            }
            for each (i in groupRisks)
                risk = Math.max(i, risk);
            return risk;
        }

        /**
         * 估算后续可能面对的非指定势力方最强飞船强度
         * @param node 目标天体
         * @param team AI势力
         * @param attributed 是否考虑属性（攻击力×防御力的平方根），默认为 true
         * @return 预测的敌对最大强度值（当 attributed=false 时为飞船数量，否则为综合强度）
         */
        public static function predictedOppStrength(node:Node, team:int, attributed:Boolean = true):int {
            var strength:int = 0;
            var ships:Vector.<Vector.<Ship>> = node.ships;
            var group:int = Globals.teamGroups[team];
            var groupValues:Vector.<Number> = new Vector.<Number>(Globals.teamCount);
            for (var i:int = 0; i < ships.length; i++) {
                var oppGroup:int = Globals.teamGroups[i];
                if (oppGroup == group)
                    continue;
                var addStrength:Number = ships[i].length + node.transitShips[i];
                if (attributed)
                    addStrength *= Math.sqrt(Globals.teamShipAttacks[i] * Globals.teamShipDefences[i]);
                if (node.buildState.buildRate > 0 && (Globals.teamGroups[node.nodeData.team] == Globals.teamGroups[i]))
                    addStrength *= 1.25;
                groupValues[oppGroup] += addStrength;
            }
            for each (var val:Number in groupValues)
                if (val > strength) strength = val;
            return strength;
        }

        /**
         * 返回该势力飞船数
         * @param node 目标天体
         * @param team 目标势力
         * @param attributed 是否考虑属性（攻击力×防御力的平方根），默认为 true
         * @return 指定队伍的综合强度值
         */
        public static function teamStrength(node:Node, team:int, attributed:Boolean = true):int {
            var strength:Number = Number(node.ships[team].length);
            if (attributed) 
                strength *= Math.sqrt(Globals.teamShipAttacks[team] * Globals.teamShipDefences[team]);
            return strength;
        }

        /**
         * 返回该队伍飞船数（考虑属性）
         * @param node 目标天体
         * @param team 目标势力
         * @param attributed 是否考虑属性（攻击力×防御力的平方根），默认为 true
         * @return 同队伍组的总综合强度值
         */
        public static function groupStrength(node:Node, team:int, attributed:Boolean = true):int {
            var strength:int = 0;
            var ships:Vector.<Vector.<Ship>> = node.ships;
            var group:int = Globals.teamGroups[team];
            for (var i:int = 0; i < ships.length; i++){
                if (Globals.teamGroups[i] == group)
                    strength += Number(ships[i].length);
                if (attributed) 
                    strength *= Math.sqrt(Globals.teamShipAttacks[team] * Globals.teamShipDefences[team]);
            }
            return strength;
        }

        /**
         * 预测该势力可能的强度
         * @param node 目标天体
         * @param team 目标势力
         * @param attributed 是否考虑属性（攻击力×防御力的平方根），默认为 true
         * @return 预测的指定队伍综合强度值
         */
        public static function predictedTeamStrength(node:Node, team:int, attributed:Boolean = true):int {
            var group:int = Globals.teamGroups[team];
            var strength:Number = Number(node.ships[team].length + node.transitGroupShips[group]);
            if (attributed) 
                strength *= Math.sqrt(Globals.teamShipAttacks[team] * Globals.teamShipDefences[team]);
            if (node.buildState.buildRate > 0 && team == node.nodeData.team)
                strength *= 1.25;
            return strength;
        }

        /**
         * 预测该队伍可能的强度
         * @param node 目标天体
         * @param team 目标势力
         * @param attributed 是否考虑属性（攻击力×防御力的平方根），默认为 true
         * @return 预测的同队伍组综合强度值
         */
        public static function predictedGroupStrength(node:Node, team:int, attributed:Boolean = true):int {
            var strength:int = 0;
            var group:int = Globals.teamGroups[team];
            for (var i:int = 0; i < node.ships.length; i++){
                if (Globals.teamGroups[i] == group)
                    strength += Number(node.ships[i].length + node.transitShips[i]) * Math.sqrt(Globals.teamShipAttacks[i] * Globals.teamShipDefences[i]);
                if (attributed) 
                    strength *= Math.sqrt(Globals.teamShipAttacks[team] * Globals.teamShipDefences[team]);
            }
            if (node.buildState.buildRate > 0 && group == Globals.teamGroups[node.nodeData.team])
                strength *= 1.25;
            return strength;
        }

        /**
         * 返回值越大，天体离作战前线越近
         * @param node 目标天体
         * @param team AI势力
         * @return 前线接近程度值，可能为Infinity
         */
        public static function getOppCloseLinks(node:Node, team:int):Number {
            if (node.nodeData.isWarp)
                return Infinity;
            var group:int = Globals.teamGroups[team];
            var link:Number = 0;
            var dx:Number = 0;
            var dy:Number = 0;
            var distance:Number = 0;
            var nodeLinks:Vector.<Node> = node.nodeLinks[team];
            for each (var node2:Node in nodeLinks) {
                if (node2 == node)
                    continue;
                var nd1:NodeData = node.nodeData, nd2:NodeData = node2.nodeData;
                if (Globals.teamGroups[nd2.team] != group) {
                    dx = nd2.x - nd1.x;
                    dy = nd2.y - nd1.y;
                    distance = Math.sqrt(dx * dx + dy * dy) + node.rng.nextNumber() * 32;
                    if (distance)
                        link += 64 / distance;
                    else
                        link = Infinity;
                }
            }
            return link;
        }

        /**
         * 返回飞向自身的最强非己方飞船数
         * @param node 目标天体
         * @param team AI势力
         * @return 非己方队伍中飞向自身的最大飞船数量
         */
        public static function hard_getOppTransitShips(node:Node, team:int):int {
            var group:int = Globals.teamGroups[team];
            var nodeData:NodeData = node.nodeData;
            if (!nodeData.hard_ships)
                nodeData.hard_ships = [];
            while (nodeData.hard_ships.length < Globals.teamCount)
                nodeData.hard_ships.push([]);
            for each (var arr:Array in nodeData.hard_ships)
                arr.length = 0;
            for each (var ship:Ship in EntityContainer.ships) {
                if (ship.state == 0 || ship.node != node)
                    continue; // 排除未起飞的和不飞向自身的飞船
                nodeData.hard_ships[ship.team].push(ship);
            }
            var groupShips:Vector.<int> = new Vector.<int>();
            var maxShips:int = 0;
            for (var i:int = 0; i < Globals.teamCount; i++) {
                var oppGroup:int = Globals.teamGroups[i];
                if (oppGroup == group)
                    continue; // 排除己方
                if (groupShips.length < oppGroup + 1) {
                    groupShips.length = oppGroup + 1;
                    groupShips[oppGroup] = nodeData.hard_ships[i].length;
                    continue;
                }
                groupShips[oppGroup] += nodeData.hard_ships[i].length;
            }
            for each (i in groupShips)
                maxShips = Math.max(i, maxShips);
            return maxShips;
        }

        /**
         * 返回指定势力的强度
         * @param node 目标天体
         * @param team 目标势力
         * @return 指定队伍的综合强度值
         */
        public static function hard_teamStrength(node:Node, team:int):Number {
            var strength:Number = 0;
            var step:Number = Math.sqrt(Globals.teamShipAttacks[team] * Globals.teamShipDefences[team])
            for each (var ship:Ship in node.ships[team])
                if (ship.state == 0)
                    strength += step;
            return strength;
        }

        /**
         * 返回己方综合强度
         * @param node 目标天体
         * @param team AI势力
         * @return 当前天体中己方队伍组的综合强度值
         */
        public static function hard_AllStrength(node:Node, team:int):Number {
            var group:int = Globals.teamGroups[team];
            var strength:Number = 0;
            for each (var ship:Ship in EntityContainer.ships)
                if (ship.node == node && Globals.teamGroups[ship.team] == group)
                    strength += Math.sqrt(Globals.teamShipAttacks[ship.team] * Globals.teamShipDefences[ship.team]);
            return strength;
        }

        private static var TEMP_INT:Vector.<int> = new Vector.<int>();

        /**
         * 返回敌方综合强度
         * @param node 目标天体
         * @param team AI势力
         * @return 当前天体中敌对队伍组的最大综合强度值
         */
        public static function hard_oppAllStrength(node:Node, team:int):Number {
            var nodeData:NodeData = node.nodeData;
            if (nodeData.hard_oppAllStrengthCache[team] != -1)
                return nodeData.hard_oppAllStrengthCache[team];
            var group:int = Globals.teamGroups[team];
            var maxStrength:Number = 0;
            var teamGroups:Array = Globals.teamGroups;
            var globalShips:Vector.<GameEntity> = EntityContainer.ships;
            var globalShipsLength:int = globalShips.length;
            var groupStrengths:Vector.<int> = TEMP_INT;
            groupStrengths.length = Globals.teamCount;
            for (var i:int = 0; i < Globals.teamCount; i++)
                groupStrengths[i] = 0;
            for (i = 0; i < globalShipsLength; i++) {
                var ship:Ship = globalShips[i] as Ship;
                if (ship.node != node)
                    continue;
                var shipGroup:int = teamGroups[ship.team];
                var teamStrength:Number = Math.sqrt(Globals.teamShipAttacks[ship.team] * Globals.teamShipDefences[ship.team]);
                if (shipGroup == group)
                    continue;
                var newStrength:Number = groupStrengths[shipGroup] + teamStrength;
                groupStrengths[shipGroup] = newStrength;
                if (newStrength > maxStrength)
                    maxStrength = newStrength;
            }
            nodeData.hard_oppAllStrengthCache[team] = maxStrength;
            return maxStrength;
        }

        /**
         * 检查撤退时机是否合理
         * @param node 目标天体
         * @param team AI势力
         * @param attributed 是否考虑属性（攻击力×防御力的平方根），默认为 true
         * @return 如果应撤退则返回true，否则返回false
         */
        public static function hard_retreatCheck(node:Node, team:int):Boolean {
            var group:int = Globals.teamGroups[team];
            var nodeData:NodeData = node.nodeData;
            if (!nodeData.hard_ships)
                nodeData.hard_ships = [];
            while (nodeData.hard_ships.length < Globals.teamCount)
                nodeData.hard_ships.push([]);
            for each (var arr:Array in nodeData.hard_ships)
                arr.length = 0;
            for each (var ship:Ship in EntityContainer.ships) {
                if (ship.node != node || Globals.teamGroups[ship.team] == group)
                    continue; // 排除不飞向自身的飞船和己方飞船
                if (ship.targetDist / ship.jumpSpeed < 1 || ship.state == 0)
                    nodeData.hard_ships[ship.team].push(ship); // 记录一秒后抵达的和已经抵达的飞船数
            }
            var groupShips:Vector.<int> = new Vector.<int>();
            var maxShips:int = 0;
            for (var i:int = 0; i < nodeData.hard_ships.length; i++) {
                var oppGroup:int = Globals.teamGroups[i];
                if (oppGroup == group)
                    continue; // 排除己方
                if (groupShips.length < oppGroup + 1) {
                    groupShips.length = oppGroup + 1;
                    groupShips[oppGroup] = nodeData.hard_ships[i].length;
                    continue;
                }
                groupShips[oppGroup] += nodeData.hard_ships[i].length;
            }
            for each (i in groupShips)
                maxShips = Math.max(i, maxShips);
            if (maxShips > hard_AllStrength(node, team))
                return true;
            return false;
        }


    }
}