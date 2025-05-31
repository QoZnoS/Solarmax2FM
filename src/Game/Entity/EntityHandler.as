// 处理实体反应

package Game.Entity {
    import Game.Entity.GameEntity.*;
    import Game.GameScene;
    import starling.errors.AbstractClassError;

    public class EntityHandler {
        public static var game:GameScene;

        public function EntityHandler() {
            throw new AbstractClassError();
        }

        // #region 添加实体
        public static function addAI(_team:int, _type:int = 1):void {
            var _EnemyAI:EnemyAI = game.ais.getReserve() as EnemyAI;
            if (!_EnemyAI)
                _EnemyAI = new EnemyAI();
            _EnemyAI.initAI(game, _team, _type);
            game.ais.addEntity(_EnemyAI);
        }

        public static function addNode(_x:Number, _y:Number, _type:int, _size:Number, _team:Number, _orbit:int, _orbitSpeed:Number = 0.1):Node {
            var _clock:Boolean = false; // 轨道方向，true为顺时针，false为逆时针
            var _Node:Node = game.nodes.getReserve() as Node; // 天体对象
            if (!_Node)
                _Node = new Node();
            var _orbitNode:Node = null; // 轨道中心天体对象
            if (_orbit > -1) // 轨道判断
            {
                _clock = true;
                if (_orbit >= 100) {
                    _orbit -= 100;
                    _clock = false;
                }
                _orbitNode = game.nodes.active[_orbit];
            }
            _Node.initNode(game, _x, _y, _type, _size, _team, _orbitNode, _clock, _orbitSpeed);
            game.nodes.addEntity(_Node);
            _Node.tag = game.nodes.active.length - 1;
            return _Node;
        }

        public static function addShips(_Node:Node, _team:int, _Number:int):void {
            for (var i:int = 0; i < _Number; i++)
                addShip(_Node, _team, false);
        }

        public static function addShip(_Node:Node, _team:int, _productionEffect:Boolean = true):Ship {
            var _Ship:Ship = game.ships.getReserve() as Ship;
            if (!_Ship)
                _Ship = new Ship();
            _Ship.initShip(game, _team, _Node, _productionEffect);
            game.ships.addEntity(_Ship);
            return _Ship;
        }
        // #endregion 

        // #region 删除实体
        /** 移除飞船，不带特效
         * @param ship 
         */
        public static function removeShip(ship:Ship):void {
            Utils.removeElementFromArray(ship.node.ships[ship.team], ship)
            Utils.removeElementFromArray(ship.preNode.ships[ship.team], ship)
            ship.hp = 0;
            ship.active = false;
        }
        /** 摧毁飞船，带特效
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
