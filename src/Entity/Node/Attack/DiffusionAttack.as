package Entity.Node.Attack {
    import Entity.Node;
    import Entity.EntityContainer;
    import Entity.Ship;
    import Entity.EntityHandler;
    import Entity.EntityContainer;
    import utils.GS;
    import Entity.FXHandler;

    public class DiffusionAttack extends BasicAttack {

        public function DiffusionAttack(attackRate:Number, attackRange:Number, attackLast:Number) {
            super(attackRate, attackRange, attackLast)
        }

        override public function executeAttack(node:Node, dt:Number):void {
            var nodes:Array = EntityContainer.findNodeInRange(node);
            if (nodes.length <= 1)
                return; // 范围内没有天体则跳过

            var shipNum:int = 0;
            var allyTeams:Vector.<int> = new Vector.<int>();
            var group:int = Globals.teamGroups[node.nodeData.team];
            for (var teamId:int = 0; teamId < Globals.teamCount; teamId++) {
                var oppGroup:int = Globals.teamGroups[teamId];
                if (node.ships[teamId].length > 0) {
                    if (oppGroup == group) {
                        allyTeams.push(teamId);
                        shipNum += node.ships[teamId].length;
                    } else 
                        return;
                }
            }
            if (allyTeams.length == 0 || shipNum == 0)
                return;
            var popFull:Boolean = true;
            for each (var i:int in allyTeams) {
                if (Globals.teamPops[i] < Globals.teamCaps[i]) {
                    popFull = false;
                    break;
                }
            }
            if (popFull)
                return;
            var diffuseTeam:int = 0;
            while (diffuseTeam == 0 || Globals.teamPops[diffuseTeam] >= Globals.teamCaps[diffuseTeam]) {
                var r:Number = node.rng.nextNumber(); //  根据飞船数随机选择扩散势力
                var lowerBound:Number = 0; // 随机数因子下界
                for each (var j:int in allyTeams) {
                    var upperBound:Number = lowerBound + node.ships[j].length / shipNum; // 因子上界
                    if (r >= lowerBound && r < upperBound) {
                        diffuseTeam = j;
                        break;
                    }
                    lowerBound = upperBound; // 新的因子下界
                }
            }
            updateArc(node, dt);
            var remain:int = Globals.teamCaps[diffuseTeam] - Globals.teamPops[diffuseTeam];
            var diffused:int = 0;
            if (updateTimer(dt)) {
                for each (var _node:Node in nodes) {
                    if (_node.nodeData.isBarrier)
                        continue;
                    if (_node == node) {
                        var ship:Ship = node.rng.randomIndex(node.ships[diffuseTeam]);
                        EntityHandler.removeShip(ship);
                        continue;
                    }
                    var color:uint = Globals.teamColors[diffuseTeam];
                    FXHandler.addLightning(node, _node, color); // 播放攻击特效
                    EntityHandler.addShip(_node, diffuseTeam, false);
                    diffused++;
                }
                if (diffused >= remain)
                    GS.playDiffused(node.nodeData.x)
                else
                    GS.playDiffusing(node.nodeData.x)
            }
            
        }

        private function updateArc(node:Node, dt:Number):void {
            var color:uint = Globals.teamColors[node.nodeData.team];
            var maxSize:Number = 2 * node.nodeData.size;
            FXHandler.addDarkPulse(node, color, 8, maxSize, 1, 0)
        }

        override public function get attackType():String {
            return "diffusion";
        }
    }
}
