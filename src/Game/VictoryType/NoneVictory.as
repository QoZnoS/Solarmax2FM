package Game.VictoryType {
    public class NoneVictory implements IVictoryType {
        public function NoneVictory() {
        }

        public function update(dt:Number):Boolean {
            return false;
        }
    }
}
