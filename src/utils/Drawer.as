package utils
{
    import starling.display.Image;
    import starling.display.QuadBatch;
    public class Drawer{
        private static var _quadImage:Image;
        private static var _quadImage2:Image;
        
        public function Drawer(){
            throw new Error("静态类不允许实例化");
        }

        public static function init():void{
            _quadImage = new Image(Root.assets.getTexture("quad"));
            _quadImage.adjustVertices();
            _quadImage2 = new Image(Root.assets.getTexture("quad8x4"));
            _quadImage2.adjustVertices();
        }

        /**绘制直线
         * @param layer 图层，关卡内请使用<code>UIContainer.behaviorBatch</code>，关卡外需自备图层
         * @param x1,y1 直线起点
         * @param x2,y2 直线终点
         * @param color 直线颜色
         * @param width 直线宽度
         * @param alpha 直线可见度
         */
        public static function drawLine(layer:QuadBatch, x1:Number, y1:Number, x2:Number, y2:Number, color:uint, width:Number = 2, alpha:Number = 1):void {
            var quadImage:Image = _quadImage;
            if (width <= 3)
                quadImage = _quadImage2;
            quadImage.color = color;
            quadImage.setVertexAlpha(2, 1);
            quadImage.setVertexAlpha(3, 1);
            quadImage.alpha = alpha;
            quadImage.rotation = 0;
            var dx:Number = x2 - x1;
            var dy:Number = y2 - y1;
            var angle:Number = Math.atan2(dy, dx);
            var distance:Number = Math.sqrt(dx * dx + dy * dy);
            quadImage.x = x1;
            quadImage.y = y1;
            quadImage.setVertexPosition(0, 0, 0);
            quadImage.setVertexPosition(1, distance, 0);
            quadImage.setVertexPosition(2, 0, width);
            quadImage.setVertexPosition(3, distance, width);
            quadImage.rotation = angle;
            layer.addImage(quadImage);
        }

        /**绘制虚线（未使用）
         * @param layer 图层，关卡内请使用<code>UIContainer.behaviorBatch</code>，关卡外需自备图层
         * @param x1,y1 虚线起点
         * @param x2,y2 虚线终点
         * @param color 虚线颜色
         * @param width 虚线宽度
         * @param alpha 虚线可见度
         * @param startStep 虚线起始步长
         */
        public static function drawDashedLine(layer:QuadBatch, x1:Number, y1:Number, x2:Number, y2:Number, color:uint, width:Number = 2, alpha:Number = 1, startStep:Number = 0):void {
            var step:int = 0;
            var dx:Number = x2 - x1;
            var dy:Number = y2 - y1;
            var angle:Number = Math.atan2(dy, dx);
            var distance:Number = Math.sqrt(dx * dx + dy * dy);
            var start:Number = 12 + 12 * startStep;
            var ax:Number = x1 + Math.cos(angle) * start;
            var ay:Number = y1 + Math.sin(angle) * start;
            step = start;
            while (step < distance - 12) {
                ax = x1 + Math.cos(angle) * step;
                ay = y1 + Math.sin(angle) * step;
                dx = ax + Math.cos(angle) * 12 * 0.5;
                dy = ay + Math.sin(angle) * 12 * 0.5;
                drawLine(layer,ax, ay, dx, dy, color, width, alpha);
                step += 12;
            }
        }

        /**
         * @param layer 
         * @param x1 
         * @param y1 
         * @param x2 
         * @param y2 
         * @param color 
         * @param width 
         * @param alpha 
         * @param progress 
         */
        public static function drawTweenedLine(layer:QuadBatch, x1:Number, y1:Number, x2:Number, y2:Number, color:uint, width:Number = 2, alpha:Number = 1, progress:Number = 1):void {
            var dx:Number = x2 - x1;
            var dy:Number = y2 - y1;
            var angle:Number = Math.atan2(dy, dx);
            var distance:Number = Math.sqrt(dx * dx + dy * dy) * progress;
            var xEnd:Number = x1 + Math.cos(angle) * distance;
            var yEnd:Number = y1 + Math.sin(angle) * distance;
            drawLine(layer, x1, y1, xEnd, yEnd, color, width, alpha);
        }

        /**绘制圆形
         * @param layer 图层，关卡内请使用<code>UIContainer.behaviorBatch</code>，关卡外需自备图层
         * @param x,y 圆心坐标
         * @param color 线条颜色
         * @param R 实心半径
         * @param voidR 空心半径
         * @param blur 是否有虚化
         * @param alpha 可见度
         * @param cycleCount 绘制次数，0.25次即为1/4圆
         * @param angle 起始角度
         * @param lineCount 绘制精度（线条数）
         */
        public static function drawCircle(layer:QuadBatch, x:Number, y:Number, color:uint, R:Number, voidR:Number = 0, blur:Boolean = false, alpha:Number = 1, cycleCount:Number = 1, angle:Number = 0, lineCount:int = 64):void {
            var quadImage:Image = _quadImage;
            if (R - voidR <= 3)
                quadImage = _quadImage2;
            quadImage.color = color;
            if (blur) {
                quadImage.setVertexAlpha(2, 0);
                quadImage.setVertexAlpha(3, 0);
            } else {
                quadImage.setVertexAlpha(2, 1);
                quadImage.setVertexAlpha(3, 1);
            }
            quadImage.alpha = alpha;
            quadImage.rotation = 0;
            var angleStep:Number = Math.PI*2 / lineCount;
            var lineNumber:int = Math.ceil(lineCount * cycleCount);
            for (var i:int = 0; i < lineNumber; i++) {
                quadImage.x = x;
                quadImage.y = y;
                if (i == lineNumber - 1)
                    angleStep = Math.PI*2 * cycleCount - angleStep * (lineNumber - 1);
                quadImage.setVertexPosition(0, Math.cos(angle) * R, Math.sin(angle) * R);
                quadImage.setVertexPosition(1, Math.cos(angle + angleStep) * R, Math.sin(angle + angleStep) * R);
                quadImage.setVertexPosition(2, Math.cos(angle) * voidR, Math.sin(angle) * voidR);
                quadImage.setVertexPosition(3, Math.cos(angle + angleStep) * voidR, Math.sin(angle + angleStep) * voidR);
                quadImage.vertexChanged();
                layer.addImage(quadImage);
                angle += angleStep;
            }
        }

        /**绘制虚线圆
         * @param layer 图层，关卡内请使用<code>UIContainer.behaviorBatch</code>，关卡外需自备图层
         * @param x,y 圆心坐标
         * @param color 线条颜色
         * @param R 实心半径
         * @param voidR 空心半径
         * @param blur 是否有虚化
         * @param alpha 可见度
         * @param cycleCount 绘制次数，0.25次即为1/4圆
         * @param angle 起始角度
         * @param lineCount 绘制精度（线条数）
         */
        public static function drawDashedCircle(layer:QuadBatch, x:Number, y:Number, color:uint, R:Number, voidR:Number = 0, blur:Boolean = false, alpha:Number = 1, cycleCount:Number = 1, angle:Number = 0, lineCount:int = 64):void {
            var quadImage:Image = _quadImage;
            if (R - voidR <= 3)
                quadImage = _quadImage2;
            quadImage.color = color;
            if (blur) {
                quadImage.setVertexAlpha(2, 0);
                quadImage.setVertexAlpha(3, 0);
            } else {
                quadImage.setVertexAlpha(2, 1);
                quadImage.setVertexAlpha(3, 1);
            }
            quadImage.alpha = alpha;
            quadImage.rotation = 0;
            var angleStep:Number = Math.PI*2 / lineCount;
            var lineNumber:int = Math.ceil(lineCount * cycleCount) * 0.5;
            for (var i:int = 0; i < lineNumber; i++) {
                quadImage.x = x;
                quadImage.y = y;
                if (i == lineNumber - 1)
                    angle = Math.PI*2 / lineCount - angleStep * 3;
                quadImage.setVertexPosition(0, Math.cos(angle) * R, Math.sin(angle) * R);
                quadImage.setVertexPosition(1, Math.cos(angle + angleStep) * R, Math.sin(angle + angleStep) * R);
                quadImage.setVertexPosition(2, Math.cos(angle) * voidR, Math.sin(angle) * voidR);
                quadImage.setVertexPosition(3, Math.cos(angle + angleStep) * voidR, Math.sin(angle + angleStep) * voidR);
                quadImage.vertexChanged();
                layer.addImage(quadImage);
                angle += angleStep * 2;
            }
        }
    }
}