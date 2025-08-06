package Entity.Node.Attack {

    import Entity.Node;
    import Entity.EntityContainer;
    import Entity.Ship;
    import Entity.EntityHandler;
    import Entity.EntityContainer;

    public class TowerAttack extends BasicAttack {

        public function TowerAttack(attackRate:Number, attackRange:Number, attackLast:Number) {
            super(attackRate, attackRange, attackLast)
        }

        override public function executeAttack(node:Node, dt:Number):void {
            if (!updateTimer(dt))
                return;
            var ships:Vector.<Ship> = EntityContainer.findShipsInRange(node);
            if (ships.length == 0)
                return;
            var ship:Ship = node.rng.randomIndex(ships);
            node.fireBeam(ship);
            EntityHandler.destroyShip(ship);
        }

        override public function get attackType():String {
            return "tower";
        }
    }
}
