package Entity {
    import Game.GameScene;
    import UI.EntityLayer;
    import starling.display.QuadBatch;

    public class GameEntity {

        public var game:GameScene;
        public var active:Boolean;
        public var entityL:EntityLayer;
        public var behaviorB:QuadBatch;

        public function GameEntity() {
            super();
        }

        public function init(_GameScene:GameScene):void {
            this.game = _GameScene;
            this.entityL = _GameScene.ui.entityL;
            this.behaviorB = _GameScene.ui.behaviorBatch;
            active = true;
        }

        public function deInit():void {
        }

        public function update(_dt:Number):void {
        }
    }
}
