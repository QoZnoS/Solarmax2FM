package Game.Entity.GameEntity.AI {

    public class BasicAI implements IEnemyAI {
        private var _type:int;

        public function update(dt:Number):void {
            throw new Error("Method not implemented.");
        }

        public function get type():int {
            return _type
        }

        public function set type(type:int):void {
            throw new Error("Method not implemented.");
        }

        public function get team():int {
            throw new Error("Method not implemented.");
        }

        public function set team(team:int):void {
            throw new Error("Method not implemented.");
        }
    }
}
