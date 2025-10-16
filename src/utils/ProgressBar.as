package utils {
    import starling.display.Quad;
    import starling.display.Sprite;

    public class ProgressBar extends Sprite {

        private var mBar:Quad;
        private var mBackground:Quad;

        public function ProgressBar(width:int, height:int) {
            super();
            init(width, height);
        }

        private function init(width:int, height:int):void {
            mBackground = new Quad(width, height, 0xEEEEEE); // 空轴
            addChild(mBackground);
            mBar = new Quad(width, height, 0xAAAAAA); // 填充轴
            mBar.scaleX = 0;
            addChild(mBar);
        }

        public function get ratio():Number {
            return mBar.scaleX;
        }

        public function set ratio(width:Number):void {
            mBar.scaleX = Math.max(0, Math.min(1, width));
        }
    }
}
