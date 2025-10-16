package Entity {
    import Game.GameScene;
    import UI.EntityLayer;
    import starling.display.QuadBatch;

    public class GameEntity {

        public var game:GameScene;
        public var active:Boolean;

        public function GameEntity() {
            super();
        }

        public function init(gameScene:GameScene):void {
            this.game = gameScene;
            active = true;
        }

        public function deInit():void {
        }

        public function update(_dt:Number):void {
        }
    }
}
