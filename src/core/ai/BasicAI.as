package core.ai {
    import core.EntityContainer;
    import core.entities.GameEntity;
    import core.entities.Node;
    import core.factories.EnemyAIFactory;

    import managers.Globals;

    import utils.Rng;

    public class BasicAI extends GameEntity implements IEnemyAI {
        private var _team:int;
        private var _nodes:Vector.<Node>;
        private var _rng:Rng;

        public var targets:Array;
        public var senders:Array;

        public function BasicAI(rng:Rng, actionDelay:Number, startDelay:Number) {
            initAI(rng, actionDelay, startDelay)
        }

        public function initAI(rng:Rng, actionDelay:Number, startDelay:Number):void {
            this._nodes = Vector.<Node>(EntityContainer.nodes);
            this._rng = rng;
            this.maxActionDelay = actionDelay;
            this.actionDelay = startDelay;
            targets = [];
            senders = [];
        }

        private var maxActionDelay:Number;
        private var actionDelay:Number;

        public function updateTimer(dt:Number):Boolean {
            actionDelay -= dt;
            if (actionDelay > 0)
                return false;
            if (actionDelay <= 0)
                actionDelay = Math.max(0, maxActionDelay * (0.25 + rng.nextNumber() * 0.25));
            return true;
        }

        public function get type():String {
            return EnemyAIFactory.BASIC;
        }

        public function get team():int {
            return _team;
        }

        public function get group():int {
            return Globals.teamGroups[_team];
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
