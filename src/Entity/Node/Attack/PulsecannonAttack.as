package Entity.Node.Attack {

    import Entity.Node;
    import Entity.EntityContainer;
    import Entity.Ship;
    import Entity.EntityHandler;
    import Entity.FXHandler;
    import Entity.EntityContainer;

    public class PulsecannonAttack extends BasicAttack {

        

        public function PulsecannonAttack(attackRate:Number, attackRange:Number, attackLast:Number) {
            super(attackRate, attackRange, attackLast)
        }

        override public function executeAttack(_Node:Node, dt:Number):void {
            var group:int = Globals.teamGroups[_Node.nodeData.team];
            if (!updateTimer(dt))
                return;
            var nodes:Array = EntityContainer.findNodeInRange(_Node);
            var ship:Ship;
            for each (var node:Node in nodes) {
                if (node == _Node)
                    continue
                var ships:Vector.<Vector.<Ship>> = EntityContainer.filterShipByStatic(node, 0);
                for (var i:int = 0; i < Globals.teamCount; i++) {
                    var iGroup:int = Globals.teamGroups[i];
                    if (iGroup == group)
                        continue
                    for (var j:int = 0; j < 5; j++) {
                        if (ships[i].length == 0)
                            break;
                        ship = node.rng.randomIndex(ships[i])
                        EntityContainer.removeShipFromVector(ships[i], ship);
                        EntityHandler.destroyShip(ship)
                    }
                }
            }
            FXHandler.addDarkPulse(_Node, Globals.teamColors[_Node.nodeData.team], 3, 25, 50, 0);
        }

        override public function get attackType():String {
            return "pulsecannon";
        }
    }
}
