package utils {

    import flash.utils.ByteArray;

    public class CalcTools {
        

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
                var avgColor:uint = 0;
                for (i = 0; i < colors.length; i++)
                    avgColor += colors[i];
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
            // 如果是黑色(0)，直接返回白色
            if (color == 0) return (255 << 16) | (255 << 8) | 255;
            
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

        // #region 汉字编解码
        /**
         * 将字节数组映射为 U+4E00~U+9FFF 范围内的汉字，实现高压缩率。
         * 编码规则：
         *   1. 用4个汉字表示原始数据长度（低位在前）。
         *   2. 将原始数据按7字节分组，最后一组不足7字节时在末尾补0。
         *   3. 每组7字节转换为4个汉字（低位在前）。
         *   4. 拼接长度汉字和所有数据组汉字。
         * 解码为逆向过程。
         */
        private static const BASE:int = 0x4E00;               // 汉字起始码点
        private static const RADIX:int = 0x9FFF - 0x4E00 + 1; // 20992，可用汉字个数
        private static const GROUP_SIZE:int = 7;              // 每组字节数
        private static const DIGITS_PER_GROUP:int = 4;        // 每组输出汉字数

        /**
         * 用于存储原始数据长度的汉字个数。
         * 可自行修改（例如改为4以支持更长的数据），但必须保证编码与解码时一致。
         * 默认值为1，可表示最大长度 20991 字节（约20KB）。
         * 若数据可能超过此值，请适当增大该数值。
         */
        public static var LENGTH_DIGITS:int = 1;

        /**
         * 将字节数组编码为汉字字符串
         * @param data 原始字节数组（大端顺序）
         * @return 汉字字符串
         * @throws Error 若数据长度超出 LENGTH_DIGITS 所能表示的范围
         */
        public static function chineseEncode(data:ByteArray):String {
            // 处理空数据：返回 LENGTH_DIGITS 个表示0的汉字
            if (data.length == 0) {
                var emptyStr:String = "";
                for (var k:int = 0; k < LENGTH_DIGITS; k++) {
                    emptyStr += String.fromCharCode(BASE);
                }
                return emptyStr;
            }

            var len:int = data.length;
            var result:String = "";

            // ---------- 1. 编码长度（LENGTH_DIGITS 个汉字，低位在前） ----------
            var lenDigits:Array = lengthToDigits(len, LENGTH_DIGITS);
            for each (var d:int in lenDigits) {
                result += String.fromCharCode(d + BASE);
            }

            // ---------- 2. 准备原始数据数组（转为无符号） ----------
            var bytes:Array = [];
            data.position = 0;
            for (var i:int = 0; i < len; i++) {
                bytes.push(data.readByte() & 0xFF); // 将 -128~127 转为 0~255
            }

            // ---------- 3. 按7字节分组处理 ----------
            var totalGroups:int = Math.ceil(len / GROUP_SIZE);
            for (var g:int = 0; g < totalGroups; g++) {
                var start:int = g * GROUP_SIZE;
                var end:int = Math.min(start + GROUP_SIZE, len);
                var group:Array = [];

                // 取出当前组的字节
                for (i = start; i < end; i++) {
                    group.push(bytes[i]);
                }
                // 不足7字节时在高位补0（即在数组前面插入0）
                while (group.length < GROUP_SIZE) {
                    group.unshift(0); // 关键修正：在高位补0
                }

                // 将7字节大端数组转换为4个汉字数字（低位在前）
                var groupDigits:Array = sevenBytesToFourDigits(group);
                for each (var d2:int in groupDigits) {
                    result += String.fromCharCode(d2 + BASE);
                }
            }

            return result;
        }

        /**
         * 将汉字字符串解码为原始字节数组
         * @param str 汉字字符串
         * @return 原始字节数组
         * @throws Error 若字符串长度不足或格式无效
         */
        public static function chineseDecode(str:String):ByteArray {
            if (str.length == 0) {
                return new ByteArray();
            }
            if (str.length < LENGTH_DIGITS) {
                throw new Error("无效的编码字符串：长度不足" + LENGTH_DIGITS);
            }

            // ---------- 1. 解析长度（前 LENGTH_DIGITS 个汉字） ----------
            var lenChars:Array = [];
            for (var i:int = 0; i < LENGTH_DIGITS; i++) {
                lenChars.push(str.charCodeAt(i) - BASE);
            }
            var dataLen:int = digitsToLength(lenChars); // 原始数据长度

            // ---------- 2. 准备结果数组 ----------
            var result:ByteArray = new ByteArray();
            var pos:int = LENGTH_DIGITS; // 当前字符位置
            var totalGroups:int = Math.ceil(dataLen / GROUP_SIZE);

            for (var g:int = 0; g < totalGroups; g++) {
                if (pos + DIGITS_PER_GROUP > str.length) {
                    throw new Error("无效的编码字符串：字符不足");
                }

                // 取出当前组的4个汉字数字（低位在前）
                var groupDigits:Array = [];
                for (i = 0; i < DIGITS_PER_GROUP; i++) {
                    groupDigits.push(str.charCodeAt(pos + i) - BASE);
                }
                pos += DIGITS_PER_GROUP;

                // 将4个数字还原为7字节大端数组（高位在前，低位在后）
                var groupBytes:Array = fourDigitsToSevenBytes(groupDigits); // 长度为7，索引0为最高位

                // 确定当前组实际有效的字节数（最后一组可能不足7）
                var start:int = g * GROUP_SIZE;
                var end:int = Math.min(start + GROUP_SIZE, dataLen);
                var validBytes:int = end - start;

                // 有效字节位于低位部分（即数组的后几个元素）
                var startIdx:int = GROUP_SIZE - validBytes;
                for (i = 0; i < validBytes; i++) {
                    var b:int = groupBytes[startIdx + i]; // 无符号值 0~255
                    // 转换为有符号字节写入（ByteArray.writeByte 期望 -128~127）
                    if (b > 127) {
                        b = b - 256;
                    }
                    result.writeByte(b);
                }
            }

            result.position = 0;
            return result;
        }

        // ------------------ 私有辅助函数 ------------------

        /**
         * 将长度值转换为指定个数的数字数组（低位在前）
         * @param length 原始长度
         * @param digitsCount 需要的数字个数
         * @return 低位在前的数字数组
         * @throws Error 若长度超出 digitsCount 所能表示的最大值
         */
        private static function lengthToDigits(length:int, digitsCount:int):Array {
            var maxLength:Number = Math.pow(RADIX, digitsCount) - 1;
            if (length > maxLength) {
                throw new Error("数据长度 " + length + " 超出 " + digitsCount + " 个汉字所能表示的最大值 " + maxLength + "，请增大 LENGTH_DIGITS");
            }

            var digits:Array = [];
            var temp:Number = length;
            for (var i:int = 0; i < digitsCount; i++) {
                digits.push(temp % RADIX);
                temp = Math.floor(temp / RADIX);
            }
            return digits; // [低位, ..., 高位]
        }

        /**
         * 将数字数组（低位在前）还原为长度值
         */
        private static function digitsToLength(digits:Array):int {
            var value:Number = 0;
            for (var i:int = digits.length - 1; i >= 0; i--) {
                value = value * RADIX + digits[i];
            }
            return int(value);
        }

        /**
         * 将7字节大端数组转换为4个数字（低位在前）
         */
        private static function sevenBytesToFourDigits(bytes7:Array):Array {
            // 转换为小端表示（索引0为最低位）
            var little:Array = [];
            for (var i:int = 6; i >= 0; i--) {
                little.push(bytes7[i] & 0xFF);
            }

            var digits:Array = [];
            for (var j:int = 0; j < 4; j++) {
                var res:Object = divideByRadix(little, RADIX);
                digits.push(res.remainder);
                little = res.quotient;
                if (little.length == 1 && little[0] == 0) {
                    // 剩余位补0
                    while (digits.length < 4) digits.push(0);
                    break;
                }
            }
            while (digits.length < 4) digits.push(0);
            return digits; // 低位在前
        }

        /**
         * 将4个数字（低位在前）还原为7字节大端数组
         */
        private static function fourDigitsToSevenBytes(digits:Array):Array {
            var little:Array = [0]; // 小端表示
            // 关键修复：从高位向低位乘加
            for (var i:int = digits.length - 1; i >= 0; i--) {
                multiplyAdd(little, RADIX, digits[i]);
            }
            // 补足7字节（小端高位补0 → 大端低位补0）
            while (little.length < 7) {
                little.push(0);
            }
            // 转为大端
            var result:Array = [];
            for (i = little.length - 1; i >= 0; i--) {
                result.push(little[i]);
            }
            return result; // 大端，长度7
        }

        /**
         * 大数除法：littleBytes ÷ divisor
         * littleBytes: 小端数组（索引0为最低位）
         * 返回 { quotient: 小端数组, remainder: 余数 }
         */
        private static function divideByRadix(littleBytes:Array, divisor:int):Object {
            var remainder:int = 0;
            var quotientHighFirst:Array = []; // 临时从高位到低位

            for (var i:int = littleBytes.length - 1; i >= 0; i--) {
                var current:int = remainder * 256 + littleBytes[i];
                var q:int = Math.floor(current / divisor);
                remainder = current % divisor;
                quotientHighFirst.push(q);
            }

            // 反转得到小端
            var quotient:Array = quotientHighFirst.reverse();

            // 去除高位0（小端数组末尾的0）
            while (quotient.length > 1 && quotient[quotient.length - 1] == 0) {
                quotient.pop();
            }

            return { quotient: quotient, remainder: remainder };
        }

        /**
         * 大数乘加：littleBytes = littleBytes * multiplier + addend
         * littleBytes: 小端数组（原地修改）
         * 注意：使用 Number 防止溢出（7字节最大值远超过 int 范围）
         */
        private static function multiplyAdd(littleBytes:Array, multiplier:int, addend:int):void {
            var carry:Number = addend; // 使用 Number 避免溢出
            for (var i:int = 0; i < littleBytes.length; i++) {
                var temp:Number = littleBytes[i] * multiplier + carry;
                littleBytes[i] = int(temp) & 0xFF; // 取低8位（0~255）
                carry = Math.floor(temp / 256);
            }
            while (carry > 0) {
                littleBytes.push(int(carry) & 0xFF);
                carry = Math.floor(carry / 256);
            }
        }
        // #endregion










    }
}
