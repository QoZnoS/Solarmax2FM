// 处理实体反应

package Entity {
    import Entity.*;
    import Game.GameScene;
    import starling.errors.AbstractClassError;
    import utils.Rng;
    import utils.GS;
    import Game.ReplayScene;

    public class EntityHandler {
        public static var game:GameScene;
        public static var replay:ReplayScene;

        public function EntityHandler() {
            throw new AbstractClassError();
        }

        // #region 添加实体
        public static function addAI(data:Object):void {
            var enemyAI:EnemyAI = EntityContainer.getReserve(EntityContainer.INDEX_AIS) as EnemyAI;
            if (!enemyAI)
                enemyAI = new EnemyAI();
            var rng:Rng;
            if (game.visible)
                rng = new Rng(game.rng.nextInt(), Rng.X32);
            else if (replay.visible)
                rng = new Rng(replay.rng.nextInt(), Rng.X32);
            var actionDelay:Number = ("actionDelay" in data) ? data.actionDelay : -1;
            var startDelay:Number = ("startDelay" in data) ? data.startDelay : -1;
            enemyAI.initAI(game, rng, data.team, data.type, actionDelay);
            EntityContainer.addEntity(EntityContainer.INDEX_AIS, enemyAI);
        }

        public static function addNode(data:Object):Node {
            var node:Node = EntityContainer.getReserve(EntityContainer.INDEX_NODES) as Node;
            if (!node)
                node = new Node();
            var rng:Rng;
            if (game.visible)
                rng = new Rng(game.rng.nextInt(), Rng.X32);
            else if (replay.visible)
                rng = new Rng(replay.rng.nextInt(), Rng.X32);
            node.initNode(game, rng, data);
            EntityContainer.addEntity(EntityContainer.INDEX_NODES, node);
            node.tag = EntityContainer.nodes.length - 1;
            return node;
        }

        public static function addShips(node:Node, team:int, number:int):void {
            for (var i:int = 0; i < number; i++)
                addShip(node, team, false);
        }

        public static function addShip(node:Node, team:int, _productionEffect:Boolean = true):Ship {
            var ship:Ship = EntityContainer.getReserve(EntityContainer.INDEX_SHIPS) as Ship;
            if (!ship)
                ship = new Ship();
            var rng:Rng;
            if (game.visible)
                rng = new Rng(game.rng.nextInt(), Rng.X32);
            else if (replay.visible)
                rng = new Rng(replay.rng.nextInt(), Rng.X32);
            ship.initShip(game, rng, team, node, _productionEffect);
            EntityContainer.addEntity(EntityContainer.INDEX_SHIPS, ship);
            return ship;
        }

        // #endregion 

        // #region 删除实体

        public static function removeNode(node:Node):void {
            for (var i:int = 0; i < Globals.teamCount; i++) {
                for each (var ship:Ship in node.ships[i]) {
                    ship.hp = 0;
                    ship.active = false;
                }
            }
            node.moveState.image.visible = false;
            node.moveState.halo.visible = false;
            node.moveState.glow.visible = false;
            node.active = false;
        }

        /** 移除飞船，不带特效
         * @param ship
         */
        public static function removeShip(ship:Ship):void {
            EntityContainer.removeShipFromVector(ship.node.ships[ship.team], ship)
            EntityContainer.removeShipFromVector(ship.preNode.ships[ship.team], ship)
            ship.hp = 0;
            ship.active = false;
        }

        /** 摧毁飞船，内部调用removeShip，外加特效
         * @param ship
         */
        public static function destroyShip(ship:Ship):void {
            removeShip(ship);
            var foreground:Boolean = false;
            if (ship.orbitAngle > 0 && ship.orbitAngle < 3.141592653589793)
                foreground = true;
            GS.playExplosion(ship.x);
            if (Globals.exOptimization > 1)
                return;
            FXHandler.addFlash(ship.x, ship.y, Globals.teamColors[ship.team], foreground);
            FXHandler.addExplosion(ship.x, ship.y, Globals.teamColors[ship.team], foreground);
        }

        // #endregion

        /** 检查是否已有该势力的AI
         * @param team 势力编号
         * @return Boolean 是否已有该势力AI
         */
        public static function hadAI(team:int):Boolean {
            for each (var ai:EnemyAI in EntityContainer.ais)
                if (ai.team == team)
                    return true;
            return false;
        }

        public static function removeAllAI():void {
            for each (var ai:EnemyAI in EntityContainer.ais)
                ai.active = false;
            EntityContainer.ais.length = 0;
        }
    }
}
