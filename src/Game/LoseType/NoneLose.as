package Game.LoseType {

    public class NoneLose implements ILoseType {
        public function NoneLose(trigger:Object) {
        }

        public function update(dt:Number):int {
            return -1;
        }

        public function get type():String {
            return LoseTypeFactory.NONE_TYPE;
        }
    }
}
