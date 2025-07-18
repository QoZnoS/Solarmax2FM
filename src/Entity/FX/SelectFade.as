// type 0为扩散式 1为收缩式
package Entity.FX {
    import Game.GameScene;
    import Entity.GameEntity;
    import utils.Drawer;

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

        public function initSelectFade(_GameScene:GameScene, _x:Number, _y:Number, _size:Number, _Color:uint, _type:int):void {
            super.init(_GameScene);
            this.x = _x;
            this.y = _y;
            this.color = _Color;
            this.size = _size;
            this.type = _type;
            alpha = 1;
        }

        override public function deInit():void {
        }

        override public function update(_dt:Number):void {
            if (type == 0)
                size += _dt * 0.2;
            else
                size -= _dt * 0.2;
            alpha -= _dt * 4;
            if (alpha <= 0) {
                alpha = 0;
                active = false;
            }
            var _R:Number = 150 * size - 4;
            var _voidR:Number = Math.max(0, _R - 3);
            Drawer.drawCircle(game.scene.ui.behaviorBatch, x, y, color, _R, _voidR, false, alpha);
        }
    }
}