package utils {
    import starling.display.Quad;
    import starling.display.Sprite;

    public class ProgressBar extends Sprite {

        private var mBar:Quad;
        private var mBackground:Quad;

        public function ProgressBar(_width:int, _height:int) {
            super();
            init(_width, _height);
        }

        private function init(_width:int, _height:int):void {
            mBackground = new Quad(_width, _height, 0xEEEEEE); // 空轴
            addChild(mBackground);
            mBar = new Quad(_width, _height, 0xAAAAAA); // 填充轴
            mBar.scaleX = 0;
            addChild(mBar);
        }

        public function get ratio():Number {
            return mBar.scaleX;
        }

        public function set ratio(_width:Number):void {
            mBar.scaleX = Math.max(0, Math.min(1, _width));
        }
    }
}
