package Game.VictoryType {

    public class NoneVictory implements IVictoryType {
        public function NoneVictory(trigger:Object) {
        }

        public function update(dt:Number):int {
            return -1;
        }

        public function get type():String {
            return VictoryTypeFactory.NONE_TYPE;
        }
    }
}
