package Entity.Node.States {
    import Entity.Node;
    import Entity.Node.NodeData;
    import Entity.EntityHandler;
    import Entity.Ship;

    public class NodeConflictState implements INodeState {

        private var node:Node;
        private var nodeData:NodeData;
        private var ships:Vector.<Vector.<Ship>>;
        private var activeTeams:Vector.<int>;
        private var totalShips:int;
        private static const BASE_ATTACK_FACTOR:Number = 10; // 攻击力基础系数

        public function NodeConflictState(node:Node) {
            this.node = node;
        }

        public function init():void {
            this.nodeData = node.nodeData;
            this.ships = node.ships;
        }

        public function deinit():void {
        }

        public function update(dt:Number):void {
            var attackForces:Vector.<Number> = calcAttackForce(dt);
            processCombatDamage(attackForces);
            node.moveState.updateConflictLabels(activeTeams, totalShips);
        }

        private function statTeam():Boolean {
            activeTeams = new Vector.<int>();
            totalShips = 0;
            for (var teamId:int = 0; teamId < ships.length; teamId++) {
                if (ships[teamId].length > 0) {
                    activeTeams.push(teamId);
                    totalShips += ships[teamId].length;
                }
            }
            return (activeTeams.length > 1);
        }

        private function calcAttackForce(dt:Number):Vector.<Number> {
            var attackForces:Vector.<Number> = new Vector.<Number>();
            for each (var attackingTeamId:int in activeTeams) {
                var activeShips:int = 0;
                for each (var ship:Ship in ships[attackingTeamId])
                    if (ship.state == 0)
                        activeShips++;
                var attackMultiplier:Number = Globals.teamShipAttacks[attackingTeamId];
                var attackForce:Number = (BASE_ATTACK_FACTOR * activeShips * attackMultiplier * dt) / (activeTeams.length - 1);
                attackForces.push(attackForce);
            }
            return attackForces;
        }

        private function processCombatDamage(attackForces:Vector.<Number>):void {
            for (var defenderIndex:int = 0; defenderIndex < activeTeams.length; defenderIndex++) {
                var defendingTeamId:int = activeTeams[defenderIndex];
                var defendingShips:Vector.<Ship> = ships[defendingTeamId];
                var defenseMultiplier:Number = Globals.teamShipDefences[defendingTeamId];
                for (var attackerIndex:int = 0; attackerIndex < activeTeams.length; attackerIndex++) {
                    if (attackerIndex == defenderIndex)
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
            return null;
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
    }
}
