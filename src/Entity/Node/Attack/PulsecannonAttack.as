package Entity.Node.Attack {

    import Entity.Node;
    import Entity.Utils;
    import Entity.Ship;
    import Entity.EntityHandler;
    import Entity.FXHandler;

    public class PulsecannonAttack extends BasicAttack {

        public function PulsecannonAttack(attackRate:Number, attackRange:Number, attackLast:Number) {
            super(attackRate, attackRange, attackLast)
        }

        override public function executeAttack(_Node:Node, dt:Number):void {
            if (!updateTimer(dt))
                return;
            var nodes:Array = Utils.findNodeInRange(_Node);
            var ship:Ship;
            for each (var node:Node in nodes) {
                var ships:Array = Utils.filterShipByStatic(node, 0);
                for (var i:int = 0; i < Globals.teamCount; i++) {
                    if (i == _Node.team)
                        continue
                    for (var j:int = 0; j < 5; j++) {
                        if (ships[i] == 0)
                            break;
                        ship = node.rng.randomIndex(ships[i])
                        Utils.removeElementFromArray(ships[i], ship);
                        EntityHandler.destroyShip(ship)
                    }
                }
            }
            FXHandler.addDarkPulse(_Node, Globals.teamColors[_Node.team], 3, 25, 50, 0);
        }

        override public function get attackType():String {
            return "pulsecannon";
        }
    }
}
