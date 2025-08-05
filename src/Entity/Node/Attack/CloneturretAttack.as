package Entity.Node.Attack {

    import Entity.Node;
    import Entity.EntityContainer;
    import Entity.EntityHandler;
    import Entity.Ship;
    import Entity.EntityContainer;

    public class CloneturretAttack extends BasicAttack {

        public function CloneturretAttack(attackRate:Number, attackRange:Number, attackLast:Number) {
            super(attackRate, attackRange, attackLast);
        }

        override public function executeAttack(node:Node, dt:Number):void {
            if (!updateTimer(dt))
                return;
            if (Globals.teamPops[node.nodeData.team] >= Globals.teamCaps[node.nodeData.team])
                return;
            var ships:Array = EntityContainer.findShipsInRange(node, false);
            if (ships.length == 0)
                return;
            var ship:Ship = node.rng.randomIndex(ships);
            var shipCreate:Ship = EntityHandler.addShip(node, node.nodeData.team, false); // 产生新飞船
            shipCreate.x = node.nodeData.x;
            shipCreate.y = node.nodeData.y;
            EntityContainer.removeElementFromArray(node.ships[node.nodeData.team], shipCreate);
            shipCreate.followTo(ship); // 跟随原飞船
        }

        override public function get attackType():String {
            return "cloneturret";
        }
    }
}
