// type 0为扩散式 1为收缩式
package Entity.FX {
    import Game.GameScene;
    import Entity.GameEntity;
    import utils.Drawer;
    import UI.UIContainer;

    public class SelectFade extends GameEntity {

        public static const TYPE_GROW:int = 0;
        public static const TYPE_SHRINK:int = 1;

        private var x:Number;
        private var y:Number;
        private var size:Number;
        private var alpha:Number;
        private var color:uint;
        private var type:int;

        public function SelectFade() {
            super();
        }

        public function initSelectFade(gameScene:GameScene, x:Number, y:Number, size:Number, color:uint, type:int):void {
            super.init(gameScene);
            this.x = x;
            this.y = y;
            this.color = color;
            this.size = size;
            this.type = type;
            alpha = 1;
        }

        override public function deInit():void {
        }

        override public function update(dt:Number):void {
            if (type == 0)
                size += dt * 0.2;
            else
                size -= dt * 0.2;
            alpha -= dt * 4;
            if (alpha <= 0) {
                alpha = 0;
                active = false;
            }
            var radius:Number = 150 * size - 4;
            var voidR:Number = Math.max(0, radius - 3);
            Drawer.drawCircle(UIContainer.behaviorBatch, x, y, color, radius, voidR, false, alpha);
        }
    }
}