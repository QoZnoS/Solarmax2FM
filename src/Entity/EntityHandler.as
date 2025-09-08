// 处理实体反应

package Entity {
    import Entity.*;
    import Game.GameScene;
    import starling.errors.AbstractClassError;
    import utils.Rng;
    import utils.GS;
    import Entity.AI.EnemyAIFactory;

    public class EntityHandler {
        public static var game:GameScene;

        public function EntityHandler() {
            throw new AbstractClassError();
        }

        // #region 添加实体
        public static function addAI(team:int, type:String = EnemyAIFactory.BASIC):void {
            var enemyAI:EnemyAI = EntityContainer.getReserve(EntityContainer.INDEX_AIS) as EnemyAI;
            if (!enemyAI)
                enemyAI = new EnemyAI();
            var rng:Rng = new Rng(game.rng.nextInt(), Rng.X32)
            enemyAI.initAI(game, rng, team, type);
            EntityContainer.addEntity(EntityContainer.INDEX_AIS, enemyAI);
        }

        public static function addNodebyArr(x:Number, y:Number, type:int, size:Number, team:Number, orbit:int, orbitSpeed:Number = 0.1):Node {
            var clock:Boolean = false; // 轨道方向，true为顺时针，false为逆时针
            var node:Node = EntityContainer.getReserve(EntityContainer.INDEX_NODES) as Node; // 天体对象
            if (!node)
                node = new Node();
            var orbitNode:Node = null; // 轨道中心天体对象
            if (orbit > -1) // 轨道判断
            {
                clock = true;
                if (orbit >= 100) {
                    orbit -= 100;
                    clock = false;
                }
                orbitNode = EntityContainer.nodes[orbit] as Node;
            }
            var rng:Rng = new Rng(game.rng.nextInt(), Rng.X32)
            node.oldInitNode(game, rng, x, y, type, size, team, orbitNode, clock, orbitSpeed);
            EntityContainer.addEntity(EntityContainer.INDEX_NODES, node);
            node.tag = EntityContainer.nodes.length - 1;
            return node;
        }

        public static function addNodebyJson(data:Object):Node {
            var node:Node = EntityContainer.getReserve(EntityContainer.INDEX_NODES) as Node;
            if (!node)
                node = new Node();
            var rng:Rng = new Rng(game.rng.nextInt(), Rng.X32)
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
            var rng:Rng = new Rng(game.rng.nextInt(), Rng.X0)
            ship.initShip(game, rng, team, node, _productionEffect);
            EntityContainer.addEntity(EntityContainer.INDEX_SHIPS, ship);
            return ship;
        }
        // #endregion 

        // #region 删除实体

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
    }
}
