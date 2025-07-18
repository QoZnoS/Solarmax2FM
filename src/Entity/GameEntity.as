package Entity {
    import Game.GameScene;

    public class GameEntity {

        public var game:GameScene;
        public var active:Boolean;

        public function GameEntity() {
            super();
        }

        public function init(_GameScene:GameScene):void {
            this.game = _GameScene;
            active = true;
        }

        public function deInit():void {
        }

        public function update(_dt:Number):void {
        }
    }
}
