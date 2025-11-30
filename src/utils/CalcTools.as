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
            if (totalWeight == 0)
                return 0; // 防止除以零

            var avgR:uint = Math.round(totalR / totalWeight);
            var avgG:uint = Math.round(totalG / totalWeight);
            var avgB:uint = Math.round(totalB / totalWeight);

            // 组合最终颜色
            return (avgR << 16) | (avgG << 8) | avgB;
        }
    }
}
