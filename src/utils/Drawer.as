package utils
{
    import starling.display.Image;
    import starling.display.QuadBatch;
    /**唯一实例，辅助绘图工具 */
    public class Drawer{
        private var _quadImage:Image;
        private var _quadImage2:Image;
        
        public function Drawer(){
            _quadImage = new Image(Root.assets.getTexture("quad"));
            _quadImage.adjustVertices();
            _quadImage2 = new Image(Root.assets.getTexture("quad8x4"));
            _quadImage2.adjustVertices();
        }

        public function drawLine(layer:QuadBatch, x1:Number, y1:Number, x2:Number, y2:Number, Color:uint, Width:Number = 2, alpha:Number = 1):void {
            var quadImage:Image = _quadImage;
            if (Width <= 3)
                quadImage = _quadImage2;
            quadImage.color = Color;
            quadImage.setVertexAlpha(2, 1);
            quadImage.setVertexAlpha(3, 1);
            quadImage.alpha = alpha;
            quadImage.rotation = 0;
            var dx:Number = x2 - x1;
            var dy:Number = y2 - y1;
            var angle:Number = Math.atan2(dy, dx);
            var Distance:Number = Math.sqrt(dx * dx + dy * dy);
            quadImage.x = x1;
            quadImage.y = y1;
            quadImage.setVertexPosition(0, 0, 0);
            quadImage.setVertexPosition(1, Distance, 0);
            quadImage.setVertexPosition(2, 0, Width);
            quadImage.setVertexPosition(3, Distance, Width);
            quadImage.rotation = angle;
            layer.addImage(quadImage);
        }

        public function drawDashedLine(layer:QuadBatch, x1:Number, y1:Number, x2:Number, y2:Number, Color:uint, Width:Number = 2, alpha:Number = 1, StartStep:Number = 0):void {
            var Step:int = 0;
            var dx:Number = x2 - x1;
            var dy:Number = y2 - y1;
            var angle:Number = Math.atan2(dy, dx);
            var Distance:Number = Math.sqrt(dx * dx + dy * dy);
            var Start:Number = 12 + 12 * StartStep;
            var Ax:Number = x1 + Math.cos(angle) * Start;
            var Ay:Number = y1 + Math.sin(angle) * Start;
            Step = Start;
            while (Step < Distance - 12) {
                Ax = x1 + Math.cos(angle) * Step;
                Ay = y1 + Math.sin(angle) * Step;
                dx = Ax + Math.cos(angle) * 12 * 0.5;
                dy = Ay + Math.sin(angle) * 12 * 0.5;
                drawLine(layer,Ax, Ay, dx, dy, Color, Width, alpha);
                Step += 12;
            }
        }

        public function drawCircle(layer:QuadBatch, x:Number, y:Number, Color:uint, R:Number, voidR:Number = 0, blur:Boolean = false, alpha:Number = 1, cycleCount:Number = 1, angle:Number = 0, lineCount:int = 64):void {
            var quadImage:Image = _quadImage;
            if (R - voidR <= 3)
                quadImage = _quadImage2;
            quadImage.color = Color;
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

        public function drawDashedCircle(layer:QuadBatch, x:Number, y:Number, Color:uint, R:Number, voidR:Number = 0, blur:Boolean = false, alpha:Number = 1, cycleCount:Number = 1, angle:Number = 0, lineCount:int = 64):void {
            var quadImage:Image = _quadImage;
            if (R - voidR <= 3)
                quadImage = _quadImage2;
            quadImage.color = Color;
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