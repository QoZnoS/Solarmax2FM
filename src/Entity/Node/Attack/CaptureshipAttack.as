package Entity.Node.Attack {

    import Entity.Node;
    import Entity.EntityContainer;
    import Entity.Ship;
    import Entity.EntityHandler;
    import Entity.EntityContainer;

    public class CaptureshipAttack extends BasicAttack {

        private var capturing:Boolean = false;

        public function CaptureshipAttack(attackRate:Number, attackRange:Number, attackLast:Number) {
            super(attackRate, attackRange, attackLast)
        }

        override public function executeAttack(node:Node, dt:Number):void {
            capturing = (Globals.teamPops[node.nodeData.team] < Globals.teamCaps[node.nodeData.team])
            if (!updateTimer(dt))
                return;
            var ships:Vector.<Ship> = EntityContainer.findShipsInRange(node);
            if (ships.length > 0) {
                var ship:Ship = node.rng.randomIndex(ships);
                if (!capturing) {
                    EntityHandler.destroyShip(ship)
                } else {
                    ship.hp = 100; // 回满血量
                    ship.team = node.nodeData.team;
                    ship.moveTo(node, true);
                    ship.image.color = Globals.teamColors[node.nodeData.team];
                    ship.trail.color = node.moveState.image.color;
                    ship.pulse.color = node.moveState.image.color;
                }
                node.fireBeam(ship);
            }
        }

        override public function updateTimer(dt:Number):Boolean {
            var attack:Boolean = super.updateTimer(dt)
            if (attack)
                attackTimer = capturing ? attackRate : attackRate * 0.5
            return attack
        }

        override public function get attackType():String {
            return "captureship";
        }
    }
}
