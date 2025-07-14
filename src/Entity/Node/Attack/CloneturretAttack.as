package Entity.Node.Attack {

    import Entity.Node;
    import Entity.Utils;
    import Entity.EntityHandler;
    import Entity.Ship;

    public class CloneturretAttack extends BasicAttack {

        public function CloneturretAttack(attackRate:Number, attackRange:Number, attackLast:Number) {
            super(attackRate, attackRange, attackLast);
        }

        override public function executeAttack(node:Node, dt:Number):void {
            if (!updateTimer(dt))
                return;
            if (Globals.teamPops[node.team] >= Globals.teamCaps[node.team])
                return;
            var ships:Array = Utils.findShipsInRange(node, false);
            if (ships.length == 0)
                return;
            var ship:Ship = node.rng.randomIndex(ships);
            var shipCreate:Ship = EntityHandler.addShip(node, node.team, false); // 产生新飞船
            shipCreate.x = node.x;
            shipCreate.y = node.y;
            Utils.removeElementFromArray(node.ships[node.team], shipCreate);
            shipCreate.followTo(ship); // 跟随原飞船
        }

        override public function get attackType():String {
            return "cloneturret";
        }
    }
}
