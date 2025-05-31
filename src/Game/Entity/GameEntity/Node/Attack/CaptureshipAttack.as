package Game.Entity.GameEntity.Node.Attack {
    import Game.Entity.GameEntity.*;
    import Game.Entity.Utils;
    import Game.Entity.EntityHandler;

    public class CaptureshipAttack extends BasicAttack {

        private var capturing:Boolean = false;

        public function CaptureshipAttack(attackRate:Number, attackRange:Number, attackLast:Number) {
            super(attackRate, attackRange, attackLast)
        }

        override public function executeAttack(node:Node, dt:Number):void {
            capturing = (Globals.teamPops[node.team] < Globals.teamCaps[node.team])
            if (!updateTimer(dt))
                return;
            var ships:Array = Utils.findShipsInRange(node);
            if (ships.length > 0) {
                var ship:Ship = Utils.random(ships)
                if (!capturing) {
                    EntityHandler.destroyShip(ship)
                } else {
                    ship.hp = 100; // 回满血量
                    ship.team = node.team;
                    ship.moveTo(node, true);
                    ship.image.color = Globals.teamColors[node.team];
                    ship.trail.color = node.image.color;
                    ship.pulse.color = node.image.color;
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
