package utils {

    public class CalcTools {
        
        public function CalcTools() {
            throw new Error("静态类不允许实例化");
        }

        public static function calculateWeightedColorAverage(colors:Array, weights:Array):uint {
            // 验证数组长度是否相同
            if (colors.length != weights.length) {
                throw new ArgumentError("两个数组的项数必须相同");
            }

            var totalWeight:Number = 0;
            var totalR:Number = 0;
            var totalG:Number = 0;
            var totalB:Number = 0;

            // 计算加权总和
            for (var i:int = 0; i < colors.length; i++) {
                var color:uint = colors[i];
                var weight:Number = weights[i];

                // 提取RGB分量
                var r:uint = (color >> 16) & 0xFF;
                var g:uint = (color >> 8) & 0xFF;
                var b:uint = color & 0xFF;

                // 累加加权值
                totalR += r * weight;
                totalG += g * weight;
                totalB += b * weight;
                totalWeight += weight;
            }

            // 计算加权平均值
            if (totalWeight == 0) {
                var avgColor:uint = 0
                for (i = 0; i < colors.length; i++)
                    avgColor += color[i];
                avgColor /= colors.length;
                return avgColor;
            }

            var avgR:uint = Math.round(totalR / totalWeight);
            var avgG:uint = Math.round(totalG / totalWeight);
            var avgB:uint = Math.round(totalB / totalWeight);

            // 组合最终颜色
            return (avgR << 16) | (avgG << 8) | avgB;
        }

        public static function scaleColorToMax(color:uint):uint {
            // 如果是黑色(0)，直接返回
            if (color == 0) return 0;
            
            // 提取RGB分量
            var r:uint = (color >> 16) & 0xFF;
            var g:uint = (color >> 8) & 0xFF;
            var b:uint = color & 0xFF;
            
            // 检查是否所有分量都小于255
            if (r < 255 && g < 255 && b < 255) {
                // 找出最大的分量值
                var maxComponent:uint = Math.max(r, g, b);
                
                // 计算放大比例
                var scale:Number = 255 / maxComponent;
                
                // 按比例放大各个分量
                r = Math.round(r * scale);
                g = Math.round(g * scale);
                b = Math.round(b * scale);
                
                // 确保值在0-255范围内
                r = Math.min(255, r);
                g = Math.min(255, g);
                b = Math.min(255, b);
                
                // 重新组合RGB分量
                return (r << 16) | (g << 8) | b;
            }
            
            // 如果已经有分量等于255，直接返回原颜色
            return color;
        }
    }
}
