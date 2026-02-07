package core.node.attacks {

    import core.entities.Node;
    import core.entities.Ship;
    import core.EntityContainer;
    import core.FXHandler;
    import managers.AudioManager;
    import core.EntityHandler;

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
            AudioManager.playLaser(node.nodeData.x); // 播放攻击音效
            EntityHandler.destroyShip(ship);
        }

        override public function get attackType():String {
            return "tower";
        }
    }
}
