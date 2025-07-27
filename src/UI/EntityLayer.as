package UI
{
    import starling.display.QuadBatch;
    import starling.display.Sprite;
    /** 显示天体和飞船 */
    public class EntityLayer extends Sprite{

        private var blackholePulseBatch:QuadBatch;

        private var bgAddBatch:QuadBatch;
        private var shipsBGBatchs:Vector.<QuadBatch>;
        private var nodeGlow:QuadBatch;

        private var bgNormalBatch:QuadBatch;
        private var shipsBGBatchbs:Vector.<QuadBatch>;
        private var nodeBatch:QuadBatch;
        private var nodeGlowNormal:QuadBatch;

        private var fgAddBatch:QuadBatch;
        private var shipsFGBatchs:Vector.<QuadBatch>;
        private var fx:QuadBatch;

        private var fgNormalBatch:QuadBatch;
        private var shipsFGBatchbs:Vector.<QuadBatch>;
        private var labels:QuadBatch;


        public function EntityLayer(){
            blackholePulseBatch = new QuadBatch();
            bgAddBatch = new QuadBatch();
        }

        public function init():void{

        }
    }
}