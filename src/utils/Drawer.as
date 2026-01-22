package utils {
    import starling.display.Image;
    import starling.display.QuadBatch;
    import starling.textures.Texture;
    import starling.events.Event;

    public class Drawer {
        private static var _quadImage:Image;
        private static var _quadImage2:Image;
        private static var _quadTexture:Texture;
        private static var _quadTexture2:Texture;

        public function Drawer() {
            throw new Error("静态类不允许实例化");
        }

        public static function init():void {
            _quadImage = new Image(Root.assets.getTexture("quad"));
            _quadImage.adjustVertices();
            _quadImage2 = new Image(Root.assets.getTexture("quad8x4"));
            _quadImage2.adjustVertices();
            _quadTexture = Root.assets.getTexture("quad");
            _quadTexture2 = Root.assets.getTexture("quad8x4");
        }

        /**绘制直线
         * @param layer 图层，关卡内请使用<code>LayerFactory.getLayer(LayerFactory.BEHAVIOR) as QuadBatch</code>，关卡外需自备图层
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
         * @param layer 图层，关卡内请使用<code>LayerFactory.getLayer(LayerFactory.BEHAVIOR) as QuadBatch</code>，关卡外需自备图层
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
         * @param layer 图层，关卡内请使用<code>LayerFactory.getLayer(LayerFactory.BEHAVIOR) as QuadBatch</code>，关卡外需自备图层
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
            var angleStep:Number = Math.PI * 2 / lineCount;
            var lineNumber:int = Math.ceil(lineCount * cycleCount);
            for (var i:int = 0; i < lineNumber; i++) {
                quadImage.x = x;
                quadImage.y = y;
                if (i == lineNumber - 1)
                    angleStep = Math.PI * 2 * cycleCount - angleStep * (lineNumber - 1);
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
         * @param layer 图层，关卡内请使用<code>LayerFactory.getLayer(LayerFactory.BEHAVIOR) as QuadBatch</code>，关卡外需自备图层
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
            var angleStep:Number = Math.PI * 2 / lineCount;
            var lineNumber:int = Math.ceil(lineCount * cycleCount) * 0.5;
            for (var i:int = 0; i < lineNumber; i++) {
                quadImage.x = x;
                quadImage.y = y;
                if (i == lineNumber - 1)
                    angle = Math.PI * 2 / lineCount - angleStep * 3;
                quadImage.setVertexPosition(0, Math.cos(angle) * R, Math.sin(angle) * R);
                quadImage.setVertexPosition(1, Math.cos(angle + angleStep) * R, Math.sin(angle + angleStep) * R);
                quadImage.setVertexPosition(2, Math.cos(angle) * voidR, Math.sin(angle) * voidR);
                quadImage.setVertexPosition(3, Math.cos(angle + angleStep) * voidR, Math.sin(angle + angleStep) * voidR);
                quadImage.vertexChanged();
                layer.addImage(quadImage);
                angle += angleStep * 2;
            }
        }

        /**
         * 绘制渐变色圆弧
         * @param layer 图层，关卡内请使用<code>LayerFactory.getLayer(LayerFactory.BEHAVIOR) as QuadBatch</code>，关卡外需自备图层
         * @param x,y 圆心坐标
         * @param colorA 起始颜色
         * @param colorB 结束颜色
         * @param R 实心半径
         * @param voidR 空心半径
         * @param blur 是否有虚化
         * @param alpha 可见度
         * @param cycleCount 绘制次数，0.25次即为1/4圆
         * @param angle 起始角度
         * @param lineCount 绘制精度（线条数）
         * @param gradientMode 渐变模式：0=径向渐变，1=顺时针渐变，2=逆时针渐变
         */
        public static function drawGradientCircle(layer:QuadBatch, x:Number, y:Number, colorA:uint, colorB:uint, R:Number, voidR:Number = 0, blur:Boolean = false, alpha:Number = 1, cycleCount:Number = 1, angle:Number = 0, lineCount:int = 64, gradientMode:int = 0):void {
            // 根据条件选择纹理
            var texture:Texture = (R - voidR <= 3) ? _quadTexture2 : _quadTexture;

            var angleStep:Number = Math.PI * 2 / lineCount;
            var lineNumber:int = Math.ceil(lineCount * cycleCount);
            var totalAngle:Number = Math.PI * 2 * cycleCount;

            for (var i:int = 0; i < lineNumber; i++) {
                // 每次循环创建新的Image实例
                var quadImage:Image = new Image(texture);
                quadImage.adjustVertices();

                quadImage.x = x;
                quadImage.y = y;

                var currentAngleStep:Number = angleStep;
                if (i == lineNumber - 1) {
                    currentAngleStep = totalAngle - angleStep * (lineNumber - 1);
                }

                // 根据渐变模式计算颜色
                var startProgress:Number, endProgress:Number;
                var startColor:uint, endColor:uint;

                switch (gradientMode) {
                    case 1: // 顺时针渐变
                        startProgress = i / lineNumber;
                        endProgress = (i + 1) / lineNumber;
                        startColor = interpolateColor(colorA, colorB, startProgress);
                        endColor = interpolateColor(colorA, colorB, endProgress);

                        setVertexColor(quadImage, 0, startColor, alpha);
                        setVertexColor(quadImage, 1, endColor, alpha);
                        setVertexColor(quadImage, 2, startColor, blur ? 0 : alpha);
                        setVertexColor(quadImage, 3, endColor, blur ? 0 : alpha);
                        break;

                    case 2: // 逆时针渐变
                        startProgress = 1 - i / lineNumber;
                        endProgress = 1 - (i + 1) / lineNumber;
                        startColor = interpolateColor(colorA, colorB, startProgress);
                        endColor = interpolateColor(colorA, colorB, endProgress);

                        setVertexColor(quadImage, 0, startColor, alpha);
                        setVertexColor(quadImage, 1, endColor, alpha);
                        setVertexColor(quadImage, 2, startColor, blur ? 0 : alpha);
                        setVertexColor(quadImage, 3, endColor, blur ? 0 : alpha);
                        break;

                    case 0: // 径向渐变
                    default:
                        var innerColor:uint = interpolateColor(colorA, colorB, voidR / R);
                        var outerColor:uint = interpolateColor(colorA, colorB, 1);

                        setVertexColor(quadImage, 0, outerColor, alpha);
                        setVertexColor(quadImage, 1, outerColor, alpha);
                        setVertexColor(quadImage, 2, innerColor, blur ? 0 : alpha);
                        setVertexColor(quadImage, 3, innerColor, blur ? 0 : alpha);
                        break;
                }

                if (blur) {
                    quadImage.setVertexAlpha(2, 0);
                    quadImage.setVertexAlpha(3, 0);
                } else {
                    quadImage.setVertexAlpha(2, 1);
                    quadImage.setVertexAlpha(3, 1);
                }

                // 设置顶点位置
                quadImage.setVertexPosition(0, Math.cos(angle) * R, Math.sin(angle) * R);
                quadImage.setVertexPosition(1, Math.cos(angle + currentAngleStep) * R, Math.sin(angle + currentAngleStep) * R);
                quadImage.setVertexPosition(2, Math.cos(angle) * voidR, Math.sin(angle) * voidR);
                quadImage.setVertexPosition(3, Math.cos(angle + currentAngleStep) * voidR, Math.sin(angle + currentAngleStep) * voidR);

                quadImage.vertexChanged();
                layer.addImage(quadImage);

                angle += currentAngleStep;
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
         * 设置顶点颜色（考虑透明度）
         */
        private static function setVertexColor(image:Image, vertexID:int, color:uint, alpha:Number):void {
            var alphaByte:int = Math.round(alpha * 255);
            var argbColor:uint = (alphaByte << 24) | (color & 0xFFFFFF);
            image.setVertexColor(vertexID, argbColor);
        }

        /**
         * 绘制多色渐变圆弧
         * @param layer 图层
         * @param x,y 圆心坐标
         * @param colors 颜色数组（至少2个颜色）例如：[0xFF0000, 0x00FF00, 0x0000FF]
         * @param R 实心半径
         * @param voidR 空心半径
         * @param blur 是否有虚化
         * @param alpha 可见度
         * @param cycleCount 绘制次数
         * @param angle 起始角度
         * @param lineCount 绘制精度
         */
        public static function drawMultiGradientCircle(layer:QuadBatch, x:Number, y:Number, colors:Array, R:Number, voidR:Number = 0, blur:Boolean = false, alpha:Number = 1, cycleCount:Number = 1, angle:Number = 0, lineCount:int = 64):void {
            if (colors.length < 2) {
                // 如果只有一个颜色，使用单色绘制
                drawCircle(layer, x, y, colors[0], R, voidR, blur, alpha, cycleCount, angle, lineCount);
                return;
            }

            // 根据条件选择纹理，创建局部Image实例
            var texture:Texture = (R - voidR <= 3) ? _quadTexture2 : _quadTexture;

            var angleStep:Number = Math.PI * 2 / lineCount;
            var lineNumber:int = Math.ceil(lineCount * cycleCount);

            // 计算总角度
            var totalAngle:Number = Math.PI * 2 * cycleCount;

            for (var i:int = 0; i < lineNumber; i++) {
                // 每次循环创建新的Image实例，避免状态污染
                var quadImage:Image = new Image(texture);
                quadImage.adjustVertices();

                quadImage.x = x;
                quadImage.y = y;

                // 计算当前角度对应的实际角度步长
                var currentAngleStep:Number = angleStep;
                if (i == lineNumber - 1) {
                    currentAngleStep = totalAngle - angleStep * (lineNumber - 1);
                }

                // 计算当前段的进度
                var progress:Number = (i / lineNumber);
                progress = progress % 1.0; // 确保在0-1范围内

                // 获取当前段的颜色
                var color:uint = getMultiGradientColor(colors, progress);
                quadImage.color = color;

                if (blur) {
                    quadImage.setVertexAlpha(2, 0);
                    quadImage.setVertexAlpha(3, 0);
                } else {
                    quadImage.setVertexAlpha(2, 1);
                    quadImage.setVertexAlpha(3, 1);
                }
                quadImage.alpha = alpha;

                // 设置顶点位置
                quadImage.setVertexPosition(0, Math.cos(angle) * R, Math.sin(angle) * R);
                quadImage.setVertexPosition(1, Math.cos(angle + currentAngleStep) * R, Math.sin(angle + currentAngleStep) * R);
                quadImage.setVertexPosition(2, Math.cos(angle) * voidR, Math.sin(angle) * voidR);
                quadImage.setVertexPosition(3, Math.cos(angle + currentAngleStep) * voidR, Math.sin(angle + currentAngleStep) * voidR);

                quadImage.vertexChanged();
                layer.addImage(quadImage);

                // 角度递增
                angle += currentAngleStep;
            }
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
        private static var _imagePoolSize:int = 0;

        public static function drawMultiGradientCircleOptimized(layer:QuadBatch, x:Number, y:Number, colors:Array, R:Number, voidR:Number = 0, blur:Boolean = false, alpha:Number = 1, cycleCount:Number = 1, angle:Number = 0, lineCount:int = 64):void {

            if (colors.length < 2) {
                drawCircle(layer, x, y, colors[0], R, voidR, blur, alpha, cycleCount, angle, lineCount);
                return;
            }

            var texture:Texture = (R - voidR <= 3) ? _quadTexture2 : _quadTexture;
            var angleStep:Number = Math.PI * 2 / lineCount;
            var lineNumber:int = Math.ceil(lineCount * cycleCount);
            var totalAngle:Number = Math.PI * 2 * cycleCount;

            for (var i:int = 0; i < lineNumber; i++) {
                var quadImage:Image;

                // 从对象池获取或创建新的Image
                if (_imagePoolSize > 0) {
                    quadImage = _imagePool[--_imagePoolSize];
                    quadImage.texture = texture;
                    quadImage.adjustVertices();
                } else {
                    quadImage = new Image(texture);
                    quadImage.adjustVertices();
                }

                quadImage.x = x;
                quadImage.y = y;

                var currentAngleStep:Number = angleStep;
                if (i == lineNumber - 1) {
                    currentAngleStep = totalAngle - angleStep * (lineNumber - 1);
                }

                var progress:Number = (i / lineNumber);
                progress = progress % 1.0;

                var color:uint = getMultiGradientColor(colors, progress);
                quadImage.color = color;

                if (blur) {
                    quadImage.setVertexAlpha(2, 0);
                    quadImage.setVertexAlpha(3, 0);
                } else {
                    quadImage.setVertexAlpha(2, 1);
                    quadImage.setVertexAlpha(3, 1);
                }
                quadImage.alpha = alpha;

                quadImage.setVertexPosition(0, Math.cos(angle) * R, Math.sin(angle) * R);
                quadImage.setVertexPosition(1, Math.cos(angle + currentAngleStep) * R, Math.sin(angle + currentAngleStep) * R);
                quadImage.setVertexPosition(2, Math.cos(angle) * voidR, Math.sin(angle) * voidR);
                quadImage.setVertexPosition(3, Math.cos(angle + currentAngleStep) * voidR, Math.sin(angle + currentAngleStep) * voidR);

                quadImage.vertexChanged();
                layer.addImage(quadImage);

                // 将Image放回对象池供下一帧使用
                quadImage.addEventListener(Event.REMOVED_FROM_STAGE, onImageRemoved);

                angle += currentAngleStep;
            }
        }

        private static function onImageRemoved(event:Event):void {
            var image:Image = event.target as Image;
            image.removeEventListener(Event.REMOVED_FROM_STAGE, onImageRemoved);

            if (_imagePoolSize < 100) { // 限制对象池大小
                _imagePool[_imagePoolSize++] = image;
            }
        }
    }
}
