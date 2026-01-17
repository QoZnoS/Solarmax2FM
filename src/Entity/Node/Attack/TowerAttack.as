package Entity.Node.Attack {

    import Entity.Node;
    import Entity.EntityContainer;
    import Entity.Ship;
    import Entity.EntityHandler;
    import Entity.EntityContainer;
    import Entity.FXHandler;
    import utils.GS;

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
            FXHandler.addBeam(node, ship); // 播放攻击特效
            GS.playLaser(node.nodeData.x); // 播放攻击音效
            EntityHandler.destroyShip(ship);
        }

        override public function get attackType():String {
            return "tower";
        }
    }
}
