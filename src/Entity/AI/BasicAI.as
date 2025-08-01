package Entity.AI {
    import Game.GameScene;
    import utils.Rng;
    import Entity.GameEntity;
    import Entity.Node;

    public class BasicAI extends GameEntity implements IEnemyAI {
        private var _team:int;
        private var _nodes:Vector.<Node>;
        private var _rng:Rng;

        public var targets:Array;
        public var senders:Array;

        public function BasicAI(game:GameScene, rng:Rng) {
            initAI(game, rng)
        }

        public function initAI(game:GameScene, rng:Rng):void {
            this._nodes = Vector.<Node>(game.nodes.active);
            this._rng = rng;
            targets = [];
            senders = [];
            actionDelay = 1.5;
            if (team == 6)
                actionDelay = 0.25;
        }

        private var actionDelay:Number;

        public function updateTimer(dt:Number):Boolean {
            actionDelay -= dt;
            if (actionDelay > 0)
                return false;
            if (actionDelay <= 0) {
                if (team == 6)
                    actionDelay = Math.max(0, (3 - Globals.currentDifficulty) * (0.25 + rng.nextNumber() * 0.25));
                else if (Globals.level == 33 && (team == 3 || team == 4))
                    actionDelay = Math.max(0, (3 - Globals.currentDifficulty) * (1.5 + rng.nextNumber() * 1.5));
                else
                    actionDelay = Math.max(0, (3 - Globals.currentDifficulty) * (1.5 + rng.nextNumber() * 1.5));
            }
            return true;
        }

        public function get type():String {
            return EnemyAIFactory.BASIC;
        }

        public function get team():int {
            return _team;
        }

        public function set team(team:int):void {
            this._team = team;
        }

        public function get nodeArray():Vector.<Node> {
            return _nodes;
        }

        public function get rng():Rng {
            return _rng;
        }
    }
}
