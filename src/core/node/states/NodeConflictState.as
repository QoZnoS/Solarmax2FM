package core.node.states {
    import core.EntityHandler;
    import core.entities.Node;
    import core.entities.Ship;
    import core.factories.NodeStateFactory;
    import core.node.NodeData;

    import managers.Globals;

    public class NodeConflictState implements INodeState {
        private var node:Node;
        private var nodeData:NodeData;
        private var ships:Vector.<Vector.<Ship>>;
        private var activeTeams:Vector.<int>;
        private var activeGroups:Vector.<int>;
        private var attackForces:Vector.<Number>;
        private var totalShips:int;
        private static const BASE_ATTACK_FACTOR:Number = 10; // 攻击力基础系数

        public function NodeConflictState(node:Node) {
            this.node = node;
            activeTeams = new Vector.<int>();
            activeGroups = new Vector.<int>();
            attackForces = new Vector.<Number>();
        }

        public function init():void {
            this.nodeData = node.nodeData;
            this.ships = node.ships;
        }

        public function deinit():void {
            activeTeams.length = 0;
            activeGroups.length = 0;
            totalShips = 0;
        }

        public function update(dt:Number):void {
            calcAttackForce(dt);
            processCombatDamage(attackForces);
            node.moveState.updateConflictLabels(activeTeams, totalShips);
        }

        private function statTeam():Boolean {
            activeTeams.length = 0;
            activeGroups.length = 0;
            totalShips = 0;
            for (var teamId:int = 0; teamId < ships.length; teamId++) {
                if (ships[teamId].length > 0) {
                    activeTeams.push(teamId);
                    totalShips += ships[teamId].length;
                    if (activeGroups.indexOf(Globals.teamGroups[teamId]) == -1)
                        activeGroups.push(Globals.teamGroups[teamId])
                }
            }
            return (activeGroups.length > 1);
        }

        private function calcAttackForce(dt:Number):void {
            attackForces.length = 0;
            for each (var attackingTeamId:int in activeTeams) {
                var activeShips:int = 0;
                for each (var ship:Ship in ships[attackingTeamId])
                    if (ship.state == 0)
                        activeShips++;
                var attackMultiplier:Number = Globals.teamShipAttacks[attackingTeamId];
                var group:int = Globals.teamGroups[attackingTeamId];
                var allyTeamsNum:int = 0;
                for each (var teamId:int in activeTeams) {
                    if (Globals.teamGroups[teamId] == group)
                        allyTeamsNum++;
                }
                var attackForce:Number = (BASE_ATTACK_FACTOR * activeShips * attackMultiplier * dt) / (activeTeams.length - allyTeamsNum);
                attackForces.push(attackForce);
            }
        }

        private function processCombatDamage(attackForces:Vector.<Number>):void {
            for (var defenderIndex:int = 0; defenderIndex < activeTeams.length; defenderIndex++) {
                var defendingTeamId:int = activeTeams[defenderIndex];
                var defendingGroupId:int = Globals.teamGroups[defendingTeamId];
                var defendingShips:Vector.<Ship> = ships[defendingTeamId];
                var defenseMultiplier:Number = Globals.teamShipDefences[defendingTeamId];
                for (var attackerIndex:int = 0; attackerIndex < activeTeams.length; attackerIndex++) {
                    var attackingTeamId:int = activeTeams[attackerIndex];
                    var attackingGroupId:int = Globals.teamGroups[attackingTeamId];
                    if (attackingGroupId == defendingGroupId)
                        continue;
                    var damage:Number = attackForces[attackerIndex] / defenseMultiplier;
                    while (damage > 0 && defendingShips.length > 0) {
                        var lastShip:Ship = defendingShips[defendingShips.length - 1];
                        if (lastShip.hp > damage) {
                            lastShip.hp -= damage;
                            break;
                        }
                        damage -= lastShip.hp;
                        defendingShips.pop();
                        EntityHandler.destroyShip(lastShip);
                    }
                }
            }
        }

        public function toJSON(k:String):* {
            return {
                activeTeams:activeTeams,
                totalShips:totalShips,
                attackForces:attackForces
            };
        }

        public function get enable():Boolean {
            node.conflict = statTeam();
            if (!node.conflict)
                node.moveState.hideConflictLabels();
            return node.conflict;
        }

        public function get stateType():String {
            return NodeStateFactory.CONFLICT;
        }

        public function deserialize(obj:Object):void {
        }
    }
}
