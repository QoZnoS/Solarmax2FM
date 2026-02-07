package core.node.attacks {
    import core.entities.Node;
    import core.entities.Ship;
    import managers.AudioManager;
    import core.FXHandler;
    import core.EntityHandler;
    import core.EntityContainer;
    import managers.Globals;

    public class ElectromagneticAttack extends BasicAttack {
        public function ElectromagneticAttack(attackRate:Number, attackRange:Number, attackLast:Number) {
            super(attackRate, attackRange, attackLast);
        }

        private static const START:Number = 100;
        private static const ATTENUATION:Number = 0.7;
        private static const DEADLINE:Number = 7.7;

        // 存储链式攻击的状态
        private var chainAttacks:Vector.<ChainAttack> = new Vector.<ChainAttack>();
        private var chainTimer:Number = 0;
        // 链式攻击的状态类
        override public function executeAttack(node:Node, dt:Number):void {
            processChainAttacks(node, dt);
            if (!updateTimer(dt))
                return;
            var ships:Vector.<Ship> = findNearestShips(node.nodeData.x, node.nodeData.y, null, node);
            if (ships.length == 0)
                return;
            var targetShip:Ship = node.rng.randomIndex(ships);
            if (!targetShip)
                return;
            var initialDamage:Number = START;
            targetShip.hp -= initialDamage;
            FXHandler.addBeam(node, targetShip);
            AudioManager.playLaser(node.nodeData.x);
            if (targetShip.hp <= 0)
                EntityHandler.destroyShip(targetShip);
            var nextDamage:Number = initialDamage * ATTENUATION;
            if (nextDamage >= DEADLINE) {
                var chainAttack:ChainAttack = new ChainAttack(targetShip.x, targetShip.y, nextDamage);
                var nearestShips:Vector.<Ship> = findNearestShips(targetShip.x, targetShip.y, targetShip, node);
                chainAttack.targets = nearestShips;
                chainAttacks.push(chainAttack);
            }
        }

        /**
         * 处理链式攻击
         */
        private function processChainAttacks(node:Node, dt:Number):void {
            chainTimer = Math.max(0, chainTimer - dt);
            if (chainTimer == 0)
                chainTimer = 0.03;
            else
                return;
            var nextChainAttacks:Vector.<ChainAttack> = new Vector.<ChainAttack>();
            for each (var chainAttack:ChainAttack in chainAttacks) {
                if (chainAttack.processed)
                    continue;
                for each (var targetShip:Ship in chainAttack.targets) {
                    if (!targetShip || targetShip.hp <= 0)
                        continue;
                    targetShip.hp -= chainAttack.damage;
                    AudioManager.playLaser(targetShip.x);
                    FXHandler.addBeamLine(chainAttack.startX, chainAttack.startY, targetShip.x, targetShip.y, node.nodeData.team);
                    if (targetShip.hp <= 0)
                        EntityHandler.destroyShip(targetShip);
                    var nextDamage:Number = chainAttack.damage * ATTENUATION;
                    if (nextDamage >= DEADLINE) {
                        var nearestShips:Vector.<Ship> = findNearestShips(targetShip.x, targetShip.y, targetShip, node);
                        if (nearestShips.length > 0) {
                            var newChainAttack:ChainAttack = new ChainAttack(targetShip.x, targetShip.y, nextDamage);
                            newChainAttack.targets = nearestShips;
                            nextChainAttacks.push(newChainAttack);
                        }
                    }
                }
                chainAttack.processed = true;
            }
            chainAttacks = nextChainAttacks;
        }

        /**
         * 寻找距离指定位置最近的两个飞船
         */
        private static const RNGFACTOR:Number = 50;
        private function findNearestShips(x:Number, y:Number, excludeShip:Ship, node:Node):Vector.<Ship> {
            var result:Vector.<Ship> = new Vector.<Ship>();
            var allShips:Vector.<Ship> = EntityContainer.ships;
            // 用于存储距离和飞船的映射
            var distances:Array = [];
            var nodeTeamGroup:int = Globals.teamGroups[node.nodeData.team];
            for each (var ship:Ship in allShips) {
                if (ship == excludeShip || ship.hp <= 0 || Globals.teamGroups[ship.team] == nodeTeamGroup)
                    continue;
                var dx:Number = ship.x - x + node.rng.nextRange(-RNGFACTOR, RNGFACTOR);
                var dy:Number = ship.y - y + node.rng.nextRange(-RNGFACTOR, RNGFACTOR);
                var distanceSq:Number = dx * dx + dy * dy;
                distances.push({ship: ship, distanceSq: distanceSq});
            }
            distances.sortOn("distanceSq", Array.NUMERIC);
            for (var i:int = 0; i < Math.min(2, distances.length); i++)
                result.push(distances[i].ship);
            return result;
        }

        override public function get attackType():String {
            return "electromagnetic";
        }
    }
}

import core.entities.Ship;

class ChainAttack {


    public var startX:Number;
    public var startY:Number;
    public var damage:Number;
    public var processed:Boolean = false;
    public var targets:Vector.<Ship> = new Vector.<Ship>();

    public function ChainAttack(startX:Number, startY:Number, damage:Number) {
        this.startX = startX;
        this.startY = startY;
        this.damage = damage;
    }
}

