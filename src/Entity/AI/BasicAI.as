package Entity.AI {

    public class BasicAI implements IEnemyAI {
        private var _team:int;

        public function update(dt:Number):void {
            throw new Error("Method not implemented.");
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
    }
}
