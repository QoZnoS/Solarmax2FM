package Entity.AI{
    import utils.Rng;
    import Entity.Node;

    public class WhiteHoleAI extends BasicAI {
        public function WhiteHoleAI(rng:Rng, actionDelay:Number, startDelay:Number) {
            super(rng, actionDelay, startDelay)
        }

        override public function update(dt:Number):void {
            if (!updateTimer(dt))
                return;
            updateWhiteHole();
        }

        public function updateWhiteHole():void {
            var node:Node = null;
            for each (node in nodeArray) {
                if(node.nodeData.team == team)
                    node.divideShips();
            }
            return;
        }
    }
}