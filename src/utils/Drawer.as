package utils {
    import starling.display.MeshBatch;
    import starling.events.Event;
    import starling.display.Quad;

    public class Drawer {
        /**绘制直线
         * @param layer 图层，关卡内请使用<code>LayerFactory.getLayer(LayerFactory.BEHAVIOR) as MeshBatch</code>，关卡外需自备图层
         * @param x1,y1 直线起点
         * @param x2,y2 直线终点
         * @param color 直线颜色
         * @param width 直线宽度
         * @param alpha 直线可见度
         */
        public static function drawLine(layer:MeshBatch, x1:Number, y1:Number, x2:Number, y2:Number, color:uint, width:Number = 2, alpha:Number = 1):void {
            var quad:Quad = getQuad();
            var dx:Number = x2 - x1;
            var dy:Number = y2 - y1;
            var angle:Number = Math.atan2(dy, dx);
            var distance:Number = Math.sqrt(dx * dx + dy * dy);
            quad.x = x1;
            quad.y = y1;
            quad.rotation = angle;
            quad.color = color;
            quad.setVertexPosition(0, 0, 0);
            quad.setVertexPosition(1, distance, 0);
            quad.setVertexPosition(2, 0, width);
            quad.setVertexPosition(3, distance, width);
            setQuadAlpha(quad, alpha, false);
            // quad.rotation = 0;
            layer.addMesh(quad);
            recycleQuad(quad);
        }

        /**绘制虚线（未使用）
         * @param layer 图层，关卡内请使用<code>LayerFactory.getLayer(LayerFactory.BEHAVIOR) as MeshBatch</code>，关卡外需自备图层
         * @param x1,y1 虚线起点
         * @param x2,y2 虚线终点
         * @param color 虚线颜色
         * @param width 虚线宽度
         * @param alpha 虚线可见度
         * @param startStep 虚线起始步长
         */
        public static function drawDashedLine(layer:MeshBatch, x1:Number, y1:Number, x2:Number, y2:Number, color:uint, width:Number = 2, alpha:Number = 1, startStep:Number = 0):void {
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
                drawLine(layer, ax, ay, dx, dy, color, width, alpha);
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
        public static function drawTweenedLine(layer:MeshBatch, x1:Number, y1:Number, x2:Number, y2:Number, color:uint, width:Number = 2, alpha:Number = 1, progress:Number = 1):void {
            var dx:Number = x2 - x1;
            var dy:Number = y2 - y1;
            var angle:Number = Math.atan2(dy, dx);
            var distance:Number = Math.sqrt(dx * dx + dy * dy) * progress;
            var xEnd:Number = x1 + Math.cos(angle) * distance;
            var yEnd:Number = y1 + Math.sin(angle) * distance;
            drawLine(layer, x1, y1, xEnd, yEnd, color, width, alpha);
        }

        /**绘制圆形
         * @param layer 图层，关卡内请使用<code>LayerFactory.getLayer(LayerFactory.BEHAVIOR) as MeshBatch</code>，关卡外需自备图层
         * @param x,y 圆心坐标
         * @param color 线条颜色
         * @param r 实心半径
         * @param voidR 空心半径
         * @param blur 是否有虚化
         * @param alpha 可见度
         * @param cycleCount 绘制次数，0.25次即为1/4圆
         * @param angle 起始角度
         * @param lineCount 绘制精度（线条数）
         */
        public static function drawCircle(layer:MeshBatch, x:Number, y:Number, color:uint, r:Number, voidR:Number = 0, blur:Boolean = false, alpha:Number = 1, cycleCount:Number = 1, angle:Number = 0, lineCount:int = 64):void {
            var angleStep:Number = Math.PI * 2 / lineCount;
            var lineNumber:int = Math.ceil(lineCount * cycleCount);
            var totalAngle:Number = Math.PI * 2 * cycleCount;
            for (var i:int = 0; i < lineNumber; i++) {
                var quad:Quad = getQuad(x, y);
                quad.color = color;
                quad.alpha = alpha;
                var currentAngle:Number = (i == lineNumber - 1) ? totalAngle - angleStep * (lineNumber - 1) : angleStep;
                setQuadVertex(quad, angle, currentAngle, r, voidR);
                setQuadAlpha(quad, alpha, blur);
                layer.addMesh(quad);
                recycleQuad(quad);
                angle += currentAngle;
            }
        }

        /**绘制虚线圆
         * @param layer 图层，关卡内请使用<code>LayerFactory.getLayer(LayerFactory.BEHAVIOR) as MeshBatch</code>，关卡外需自备图层
         * @param x,y 圆心坐标
         * @param color 线条颜色
         * @param r 实心半径
         * @param voidR 空心半径
         * @param blur 是否有虚化
         * @param alpha 可见度
         * @param cycleCount 绘制次数，0.25次即为1/4圆
         * @param angle 起始角度
         * @param lineCount 绘制精度（线条数）
         */
        public static function drawDashedCircle(layer:MeshBatch, x:Number, y:Number, color:uint, r:Number, voidR:Number = 0, blur:Boolean = false, alpha:Number = 1, cycleCount:Number = 1, angle:Number = 0, lineCount:int = 64):void {
            var totalSegments:int = Math.ceil(lineCount * cycleCount);
            var angleStep:Number = (Math.PI * 2 * cycleCount) / totalSegments;
            var startAngle:Number = angle;

            for (var i:int = 0; i < totalSegments; i++) {
                // 只绘制偶数段（或奇数段），实现虚线效果
                if (i % 2 == 0) {
                    var quad:Quad = getQuad(x, y);
                    quad.color = color;
                    quad.alpha = alpha;
                    var segStart:Number = startAngle + i * angleStep;
                    var segEnd:Number = segStart + angleStep;
                    setQuadVertex(quad, segStart, segEnd - segStart, r, voidR);
                    setQuadAlpha(quad, alpha, blur);
                    layer.addMesh(quad);
                    recycleQuad(quad);
                }
            }
        }

        /**
         * 插值颜色（线性插值）
         * @param colorA 颜色A
         * @param colorB 颜色B
         * @param progress 插值进度（0-1）
         * @return 插值后的颜色
         */
        private static function interpolateColor(colorA:uint, colorB:uint, progress:Number):uint {
            var aR:Number = (colorA >> 16) & 0xFF;
            var aG:Number = (colorA >> 8) & 0xFF;
            var aB:Number = colorA & 0xFF;
            var bR:Number = (colorB >> 16) & 0xFF;
            var bG:Number = (colorB >> 8) & 0xFF;
            var bB:Number = colorB & 0xFF;

            var r:Number = aR + (bR - aR) * progress;
            var g:Number = aG + (bG - aG) * progress;
            var b:Number = aB + (bB - aB) * progress;

            return (Math.round(r) << 16) | (Math.round(g) << 8) | Math.round(b);
        }

        /**
         * 获取多色渐变中的颜色
         */
        private static function getMultiGradientColor(colors:Array, progress:Number):uint {
            if (colors == null || colors.length == 0)
                return 0x000000;
            if (progress <= 0)
                return colors[0];
            if (progress >= 1)
                return colors[colors.length - 1];

            var segment:Number = 1 / (colors.length - 1);
            var segmentIndex:int = Math.floor(progress / segment);

            // 确保索引不越界
            if (segmentIndex >= colors.length - 1) {
                return colors[colors.length - 1];
            }

            var segmentProgress:Number = (progress % segment) / segment;
            return interpolateColor(colors[segmentIndex], colors[segmentIndex + 1], segmentProgress);
        }

        /**
         * 绘制多色渐变圆弧 - 优化性能版本（使用对象池）
         * 如果在同一帧内需要大量调用，可以使用这个版本
         */
        private static var _imagePool:Array = [];
        private static var _quadPoolSize:int = 0;

        public static function drawMultiGradientCircleOptimized(layer:MeshBatch, x:Number, y:Number, colors:Array, r:Number, voidR:Number = 0, blur:Boolean = false, alpha:Number = 1, cycleCount:Number = 1, angle:Number = 0, lineCount:int = 64):void {
            if (colors.length < 2) {
                drawCircle(layer, x, y, colors[0], r, voidR, blur, alpha, cycleCount, angle, lineCount);
                return;
            }
            var angleStep:Number = Math.PI * 2 / lineCount;
            var lineNumber:int = Math.ceil(lineCount * cycleCount);
            var totalAngle:Number = Math.PI * 2 * cycleCount;
            for (var i:int = 0; i < lineNumber; i++) {
                var quad:Quad = getQuad(x, y);
                var currentAngle:Number = angleStep;
                if (i == lineNumber - 1)
                    currentAngle = totalAngle - angleStep * (lineNumber - 1);
                var progress:Number = (i / lineNumber);
                progress = progress % 1.0;
                var color:uint = getMultiGradientColor(colors, progress);
                quad.color = color;
                setQuadAlpha(quad, alpha, blur);
                setQuadVertex(quad, angle, currentAngle, r, voidR);
                layer.addMesh(quad);
                recycleQuad(quad);
                angle += currentAngle;
            }
        }

        private static function setQuadAlpha(quad:Quad, alpha:Number, blur:Boolean):void {
            if (blur) {
                quad.setVertexAlpha(0, 0.5);
                quad.setVertexAlpha(1, 0.5);
                quad.setVertexAlpha(2, 0);
                quad.setVertexAlpha(3, 0);
            } else {
                quad.setVertexAlpha(0, alpha);
                quad.setVertexAlpha(1, alpha);
                quad.setVertexAlpha(2, alpha);
                quad.setVertexAlpha(3, alpha);
            }
            // quad.alpha = alpha;
        }

        private static function setQuadVertex(quad:Quad, angle:Number, currentAngle:Number, r:Number, voidR:Number):void {
            // 计算四个顶点位置（梯形）
            var x0:Number = Math.cos(angle) * r;
            var y0:Number = Math.sin(angle) * r;
            var x1:Number = Math.cos(angle + currentAngle) * r;
            var y1:Number = Math.sin(angle + currentAngle) * r;
            var x2:Number = Math.cos(angle) * voidR;
            var y2:Number = Math.sin(angle) * voidR;
            var x3:Number = Math.cos(angle + currentAngle) * voidR;
            var y3:Number = Math.sin(angle + currentAngle) * voidR;
            // 设置顶点位置（Quad 的顶点顺序：0-左下，1-右下，2-左上，3-右上？实际为 0-左上，1-右上，2-左下，3-右下）
            quad.setVertexPosition(0, x0, y0);
            quad.setVertexPosition(1, x1, y1);
            quad.setVertexPosition(2, x2, y2);
            quad.setVertexPosition(3, x3, y3);
        }

        private static function recycleQuad(quad:Quad):void {
            if (_quadPoolSize < 300)
                _imagePool[_quadPoolSize++] = quad;
            else
                quad.dispose(); // 池满时释放，避免内存泄漏
        }

        private static function getQuad(x:Number = 0, y:Number = 0):Quad {
            var quad:Quad;
            if (_quadPoolSize > 0)
                quad = _imagePool[--_quadPoolSize];
            else
                quad = new Quad(4, 4);
            setQuadAlpha(quad, 1, false);
            quad.texture = null;
            quad.x = x;
            quad.y = y;
            quad.rotation = 0; // 确保旋转重置
            quad.scaleX = quad.scaleY = 1;
            quad.color = 0xFFFFFF; // 重置颜色
            return quad;
        }

    }
}
