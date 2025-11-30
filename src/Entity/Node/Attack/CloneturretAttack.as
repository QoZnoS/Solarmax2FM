package Entity.Node.Attack {

    import Entity.Node;
    import Entity.EntityContainer;
    import Entity.EntityHandler;
    import Entity.Ship;
    import Entity.EntityContainer;
    import avmplus.factoryXml;

    public class CloneturretAttack extends BasicAttack {

        public function CloneturretAttack(attackRate:Number, attackRange:Number, attackLast:Number) {
            super(attackRate, attackRange, attackLast);
        }

        // private function isPopFull(team:int):Boolean {
        //     var group:int = Globals.teamGroups[team];
        //     for (var teamId:int = 0; teamId < Globals.teamCount; teamId++) {
        //         if (Globals.teamGroups[teamId] == group && Globals.teamPops[teamId] < Globals.teamCaps[teamId]) 
        //             return false;
        //     }
        //     return true;
        // }

        override public function executeAttack(node:Node, dt:Number):void {
            if (!updateTimer(dt))
                return;
            var ships:Vector.<Ship> = EntityContainer.findShipsInRange(node, false);
            if (ships.length == 0)
                return;
            var teams:Vector.<int> = new Vector.<int>();
            for each(var _ship:Ship in ships){
                if (Globals.teamPops[_ship.team] < Globals.teamCaps[_ship.team])
                    teams.push(_ship.team);
            }
            if (teams.length == 0)
                return;            
            var ship:Ship = node.rng.randomIndex(ships);
            while (teams.indexOf(ship.team) == -1)
                ship = node.rng.randomIndex(ships);
            var shipCreate:Ship = EntityHandler.addShip(node, ship.team, false); // 产生新飞船
            shipCreate.x = node.nodeData.x;
            shipCreate.y = node.nodeData.y;
            EntityContainer.removeShipFromVector(node.ships[node.nodeData.team], shipCreate);
            shipCreate.followTo(ship); // 跟随原飞船
        }

        override public function get attackType():String {
            return "cloneturret";
        }
    }
}
