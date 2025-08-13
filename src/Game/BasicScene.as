package Game {

    import starling.display.Sprite;
    import Game.VictoryType.IVictoryType;
    import Game.LoseType.ILoseType;
    import starling.events.EnterFrameEvent;

    public class BasicScene extends Sprite {

        public var victoryType:IVictoryType;
        public var loseType:ILoseType;

        public function BasicScene() {

        }

        public function init(seed:uint = 0, rep:Boolean = false):void {

        }

        public function deinit():void {
            
        }

        public function update(e:EnterFrameEvent):void{

        }

        public function animateIn():void {
        }

        public function animateOut():void {
        }
    }
}
