package Game.Entity.GameEntity.Node.Attack {
    import Game.Entity.GameEntity.*;
    import Game.Entity.Utils;
    import Game.Entity.EntityHandler;

    public class TowerAttack extends BasicAttack{

        public function TowerAttack(attackRate:Number, attackRange:Number, attackLast:Number) {
            super(attackRate, attackRange, attackLast)
        }

        override public function executeAttack(node:Node, dt:Number):void {
            if (!updateTimer(dt))
                return;
            var ships:Array = Utils.findShipsInRange(node);
            if (ships.length == 0)
                return;
            var ship:Ship = Utils.random(ships);
            node.fireBeam(ship);
            EntityHandler.destroyShip(ship);
        }

        override public function get attackType():String {
            return "tower";
        }
    }
}
