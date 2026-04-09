package core.ai
{
    import core.entities.Node;
    import core.entities.GameEntity;
    import core.EntityContainer;
    import core.node.NodeStaticLogic;
    import managers.Globals;

    public class SituationAssessor
    {

        // #region AI工具及相关计算工具函数
        // 返回飞船数最多的敌对队伍的总飞船数（无属性差分）
        public function oppShipCount(team:int):int {
            var strength:int = 0;
            var group:int = Globals.teamGroups[team];
            var groupShips:Vector.<int> = new Vector.<int>(Globals.teamCount);
            for (var i:int = 0; i < ships.length; i++) {
                var oppGroup:int = Globals.teamGroups[i];
                if (oppGroup == group)
                    continue;
                groupShips[oppGroup] += ships[i].length;
            }
            for each (i in groupShips)
                strength = Math.max(i, strength);
            return strength;
        }

        // 返回飞船数最多的敌对队伍的总飞船数（考虑属性）
        public function oppStrength(team:int):int {
            var strength:int = 0;
            var group:int = Globals.teamGroups[team];
            var groupStrengths:Vector.<int> = new Vector.<int>(Globals.teamCount);
            for (var i:int = 0; i < ships.length; i++) {
                var oppGroup:Number = Globals.teamGroups[i];
                if (oppGroup == group)
                    continue;
                groupStrengths[oppGroup] += ships[i].length * Math.sqrt(Globals.teamShipAttacks[i] * Globals.teamShipDefences[i]);
            }
            for each (i in groupStrengths)
                strength = Math.max(i, strength);
            return strength;
        }

        // 估算后续可能面对的非指定势力方最快占领速度（考虑属性）
        public function predictedOppCaptureRisk(team:int):Number {
            var risk:Number = 0;
            var group:int = Globals.teamGroups[team];
            var groupRisks:Vector.<int> = new Vector.<int>(Globals.teamCount);
            for (var i:int = 0; i < ships.length; i++) {
                var oppGroup:int = Globals.teamGroups[i];
                if (oppGroup == group)
                    continue;
                var addRisk:Number = (ships[i].length + transitShips[i]) * Globals.teamDestroyingSpeeds[i];
                groupRisks[oppGroup] += addRisk;
            }
            for each (i in groupRisks)
                risk = Math.max(i, risk);
            return risk;
        }

        // 估算后续可能面对的非指定势力方最强飞船强度（无属性差分）
        public function predictedOppShipCount(team:int):int {
            var strength:int = 0;
            var group:int = Globals.teamGroups[team];
            var groupShips:Vector.<int> = new Vector.<int>(Globals.teamCount);
            for (var i:int = 0; i < ships.length; i++) {
                var oppGroup:int = Globals.teamGroups[i];
                if (oppGroup == group)
                    continue;
                var addStrength:int = ships[i].length + transitShips[i];
                if (buildState.buildRate > 0 && (Globals.teamGroups[nodeData.team] == Globals.teamGroups[i]))
                    addStrength *= 1.25;
                groupShips[oppGroup] += addStrength;
            }
            for each (i in groupShips)
                strength = Math.max(i, strength);
            return strength;
        }

        // 估算后续可能面对的非指定势力方最强飞船强度（考虑属性）
        public function predictedOppStrength(team:int):int {
            var strength:int = 0;
            var group:int = Globals.teamGroups[team];
            var groupStrengths:Vector.<int> = new Vector.<int>(Globals.teamCount);
            for (var i:int = 0; i < ships.length; i++) {
                var oppGroup:int = Globals.teamGroups[i];
                if (oppGroup == group)
                    continue;
                var addStrength:Number = Number(ships[i].length + transitShips[i]) * Math.sqrt(Globals.teamShipAttacks[i] * Globals.teamShipDefences[i]);
                if (buildState.buildRate > 0 && (Globals.teamGroups[nodeData.team] == Globals.teamGroups[i]))
                    addStrength *= 1.25;
                groupStrengths[oppGroup] += addStrength;
            }
            for each (i in groupStrengths)
                strength = Math.max(i, strength);
            return strength;
        }

        // 返回该势力飞船数（无属性差分）
        public function teamShipCount(team:int):int {
            return Number(ships[team].length);
        }

        // 返回该势力飞船数（考虑属性）
        public function teamStrength(team:int):int {
            return Number(ships[team].length) * Math.sqrt(Globals.teamShipAttacks[team] * Globals.teamShipDefences[team]);
        }

        // 返回该队伍飞船数（无属性差分）
        public function groupShipCount(team:int):int {
            var strength:int = 0;
            var group:int = Globals.teamGroups[team];
            for (var i:int = 0; i < ships.length; i++)
                if (Globals.teamGroups[i] == group)
                    strength += Number(ships[i].length);
            return strength;
        }

        // 返回该队伍飞船数（考虑属性）
        public function groupStrength(team:int):int {
            var strength:int = 0;
            var group:int = Globals.teamGroups[team];
            for (var i:int = 0; i < ships.length; i++)
                if (Globals.teamGroups[i] == group)
                    strength += Number(ships[i].length) * Math.sqrt(Globals.teamShipAttacks[i] * Globals.teamShipDefences[i]);
            return strength;
        }

        // 预测该势力可能的强度（无属性差分）
        public function predictedTeamShipCount(team:int):int {
            var group:int = Globals.teamGroups[team];
            var strength:Number = ships[team].length + transitGroupShips[group];
            if (buildState.buildRate > 0 && team == nodeData.team)
                strength *= 1.25;
            return strength;
        }

        // 预测该势力可能的强度（考虑属性）
        public function predictedTeamStrength(team:int):int {
            var group:int = Globals.teamGroups[team];
            var strength:Number = Number(ships[team].length + transitGroupShips[group]) * Math.sqrt(Globals.teamShipAttacks[team] * Globals.teamShipDefences[team]);
            if (buildState.buildRate > 0 && team == nodeData.team)
                strength *= 1.25;
            return strength;
        }

        // 预测该队伍可能的强度（无属性差分）
        public function predictedGroupShipCount(team:int):int {
            var strength:int = 0;
            var group:int = Globals.teamGroups[team];
            for (var i:int = 0; i < ships.length; i++)
                if (Globals.teamGroups[i] == group)
                    strength += Number(ships[i].length + transitShips[i]);
            if (buildState.buildRate > 0 && group == Globals.teamGroups[nodeData.team])
                strength *= 1.25;
            return strength;
        }

        // 预测该队伍可能的强度（考虑属性）
        public function predictedGroupStrength(team:int):int {
            var strength:int = 0;
            var group:int = Globals.teamGroups[team];
            for (var i:int = 0; i < ships.length; i++)
                if (Globals.teamGroups[i] == group)
                    strength += Number(ships[i].length + transitShips[i]) * Math.sqrt(Globals.teamShipAttacks[i] * Globals.teamShipDefences[i]);
            if (buildState.buildRate > 0 && group == Globals.teamGroups[nodeData.team])
                strength *= 1.25;
            return strength;
        }

        // 计算可到达的有前往价值的天体
        public function getOppLinks(team:int):void {
            var group:int = Globals.teamGroups[team];
            oppNodeLinks.length = 0;
            for each (var node:Node in nodeLinks[team]) {
                if (node == this)
                    continue;
                if (node.nodeData.team == 0 || Globals.teamGroups[node.nodeData.team] != group || node.predictedOppShipCount(team) > 0)
                    oppNodeLinks.push(node);
            }
        }

        // 返回值越大，天体离作战前线越近
        public function getOppCloseLinks(team:int):Number {
            var group:int = Globals.teamGroups[team];
            var link:Number = 0;
            var dx:Number = 0;
            var dy:Number = 0;
            var distance:Number = 0;
            if (this.nodeData.isWarp) {
                return Infinity;
            }
            for each (var node:Node in nodeLinks[team]) {
                if (node == this)
                    continue;
                if (Globals.teamGroups[node.nodeData.team] != group) {
                    dx = node.nodeData.x - this.nodeData.x;
                    dy = node.nodeData.y - this.nodeData.y;
                    distance = Math.sqrt(dx * dx + dy * dy) + rng.nextNumber() * 32;
                    if (distance)
                        link += 64 / distance;
                    else
                        link = Infinity;
                }
            }
            return link;
        }

        // #endregion
        // #region hardAI 特制工具函数
        // 返回飞向自身的最强非己方飞船数
        public function hard_getOppTransitShips(team:int):int {
            var group:int = Globals.teamGroups[team];
            if (!nodeData.hard_ships)
                nodeData.hard_ships = [];
            while (nodeData.hard_ships.length < Globals.teamCount)
                nodeData.hard_ships.push([]);
            for each (var arr:Array in nodeData.hard_ships)
                arr.length = 0;
            for each (var ship:Ship in EntityContainer.ships) {
                if (ship.state == 0 || ship.node != this)
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

        // 返回指定势力的强度
        public function hard_teamStrength(team:int):Number {
            var strength:Number = 0;
            var step:Number = Math.sqrt(Globals.teamShipAttacks[team] * Globals.teamShipDefences[team])
            for each (var ship:Ship in ships[team])
                if (ship.state == 0)
                    strength += step;
            return strength;
        }

        // 返回己方综合强度
        public function hard_AllStrength(team:int):Number {
            var group:int = Globals.teamGroups[team];
            var strength:Number = 0;
            for each (var ship:Ship in EntityContainer.ships)
                if (ship.node == this && Globals.teamGroups[ship.team] == group)
                    strength += Math.sqrt(Globals.teamShipAttacks[ship.team] * Globals.teamShipDefences[ship.team]);
            return strength;
        }
        private var TEMP_INT:Vector.<int> = new Vector.<int>();

        // 返回敌方综合强度
        public function hard_oppAllStrength(team:int):Number {
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
                if (ship.node != this)
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

        // 检查撤退时机是否合理
        public function hard_retreatCheck(team:int):Boolean {
            var group:int = Globals.teamGroups[team];
            if (!nodeData.hard_ships)
                nodeData.hard_ships = [];
            while (nodeData.hard_ships.length < Globals.teamCount)
                nodeData.hard_ships.push([]);
            for each (var arr:Array in nodeData.hard_ships)
                arr.length = 0;
            for each (var ship:Ship in EntityContainer.ships) {
                if (ship.node != this || Globals.teamGroups[ship.team] == group)
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
            if (maxShips > hard_AllStrength(team))
                return true;
            return false;
        }

        // #endregion

    }
}