package utils {
    import utils.Rng;

    public class GeneralFunctions {
        /**
         * 从数组中随机选取一个具有最小属性值的对象
         * 使用单次遍历算法，数组无需预先排序
         * @param rng 随机数生成器，用于产生随机选择
         * @param arr 要处理的数组
         * @param propertyName 用于比较的属性名称
         * @return 随机选取的最小属性值对象，数组为空时返回null
         */
        public static function getRandomMinByProperty(rng:Rng, arr:Array, propertyName:String):Object {
            if (arr == null || arr.length == 0) {
                return null;
            }

            var minValueObjects:Array = [];
            var minValue:Number;

            for (var i:int = 0; i < arr.length; i++) {
                var currentValue:Number = arr[i][propertyName];

                if (i == 0) {
                    minValue = currentValue;
                    minValueObjects.push(arr[i]);
                } else if (currentValue < minValue) {
                    minValue = currentValue;
                    minValueObjects = [arr[i]];
                } else if (currentValue == minValue) {
                    minValueObjects.push(arr[i]);
                }
            }

            var randomIndex:int = Math.floor(rng.nextNumber() * minValueObjects.length);
            return minValueObjects[randomIndex];
        }

        /**
         * 获取数组中指定属性最小值的对象数量
         * @param arr 要处理的数组
         * @param propertyName 用于比较的属性名
         * @return 具有最小属性值的对象数量，数组为空或null时返回0
         */
        public static function getMinCount(arr:Array, propertyName:String):int {
            if (arr == null || arr.length == 0) {
                return 0;
            }
            var minValue:Number;
            var count:int = 0;
            for (var i:int = 0; i < arr.length; i++) {
                var currentValue:Number = arr[i][propertyName];

                if (i == 0) {
                    minValue = currentValue;
                    count++;
                } else if (currentValue < minValue) {
                    minValue = currentValue;
                    count = 1;
                } else if (currentValue == minValue) {
                    count++;
                }
            }

            return count;
        }

        /**
         * 获取数组中所有具有最小属性值的对象
         * @param arr 要处理的数组
         * @param propertyName 用于比较的属性名称
         * @return 包含所有最小属性值对象的数组，数组为空时返回空数组
         */
        public static function getMins(arr:Array, propertyName:String):Array {
            if (arr == null || arr.length == 0) {
                return [];
            }

            var minValueObjects:Array = [];
            var minValue:Number;

            for (var i:int = 0; i < arr.length; i++) {
                var currentValue:Number = arr[i][propertyName];

                if (i == 0) {
                    minValue = currentValue;
                    minValueObjects.push(arr[i]);
                } else if (currentValue < minValue) {
                    minValue = currentValue;
                    minValueObjects = [arr[i]];
                } else if (currentValue == minValue) {
                    minValueObjects.push(arr[i]);
                }
            }
            return minValueObjects;
        }

        /**
         * @param arr 要处理的数组
         * @param property 用于比较的属性名
         * @param n 要删除的最小值对象的数量，默认为1
         * @return 修改后的原数组
         */
        public static function popMinValues(arr:Array, property:String, n:int = 1):Array {
            if (!arr || arr.length == 0 || n <= 0)
                return arr;

            var minValue:Number = Number.MAX_VALUE;
            var minIndices:Array = [];

            for (var i:int = 0; i < arr.length; i++) {
                var val:Number = arr[i][property];
                if (val < minValue) {
                    minValue = val;
                    minIndices = [i];
                } else if (val == minValue) {
                    minIndices.push(i);
                }
            }
            var toRemove:int = Math.min(n, minIndices.length);
            for (i = toRemove - 1; i >= 0; i--)
                removeAt(arr, minIndices[i]);
            return arr;
        }

        /**
         * 移除指定位置元素，低性能
         * @param arr
         * @param index
         */
        public static function removeAt(arr:Array, index:int):void {
            for (var i:int = index; i < arr.length - 1; i++)
                arr[i] = arr[i + 1];
            arr.length = arr.length - 1; // 缩短 Vector
        }

        /**
         * 移除指定位置元素，高性能但破坏顺序
         * @param arr
         * @param index
         */
        public static function removeAtUnordered(arr:Array, index:int):void {
            arr[index] = arr[arr.length - 1];
            arr.pop();
        }

        /**
         * 移除数组中的指定元素
         * @param arr 目标数组
         * @param element 目标元素
         */
        public static function removeElementFromArray(arr:Array, element:*):void {
            var writeIndex:int = 0;
            for (var i:int = 0; i < arr.length; i++) {
                if (arr[i] == element)
                    continue;
                if (writeIndex != i)
                    arr[writeIndex] = arr[i];
                writeIndex++;
            }
            arr.length = writeIndex; // 释放尾部元素
        }

        /**
         * 静态比较函数，用于比较两个对象在指定字段上的值。
         * 支持 CASEINSENSITIVE(1)、DESCENDING(2)、NUMERIC(16) 标志。
         * 字段缺失（undefined）和 NaN 被视为最小值。
         */
        private static function compareByField(a:Object, b:Object, field:String, flags:int):int {
            var valA:* = a[field];
            var valB:* = b[field];

            // 数值转换
            if (flags & 16) {
                valA = Number(valA);
                valB = Number(valB);
            }

            // 大小写不敏感
            if (flags & 1) {
                if (valA is String)
                    valA = String(valA).toLowerCase();
                if (valB is String)
                    valB = String(valB).toLowerCase();
            }

            // undefined 处理
            var aUndef:Boolean = (valA === undefined);
            var bUndef:Boolean = (valB === undefined);
            if (aUndef && bUndef)
                return 0;
            if (aUndef)
                return -1;
            if (bUndef)
                return 1;

            // NaN 处理
            var aNaN:Boolean = (typeof valA === 'number' && isNaN(valA));
            var bNaN:Boolean = (typeof valB === 'number' && isNaN(valB));
            if (aNaN && bNaN)
                return 0;
            if (aNaN)
                return -1;
            if (bNaN)
                return 1;

            // 正常比较
            var cmp:int = 0;
            if (valA < valB)
                cmp = -1;
            else if (valA > valB)
                cmp = 1;

            // 降序
            if (flags & 2)
                cmp = -cmp;
            return cmp;
        }

        /**
         * 快速排序递归段，仅对数组的一部分进行排序。
         */
        private static function quickSortSegment(arr:Array, left:int, right:int, field:String, flags:int):void {
            if (left >= right)
                return;

            // 选择中间元素作为基准（避免最坏情况）
            var pivotIdx:int = int((left + right) / 2);
            var tmp:Object = arr[pivotIdx];
            arr[pivotIdx] = arr[right];
            arr[right] = tmp;

            var storeIdx:int = left;
            for (var i:int = left; i < right; i++) {
                if (compareByField(arr[i], arr[right], field, flags) <= 0) {
                    tmp = arr[i];
                    arr[i] = arr[storeIdx];
                    arr[storeIdx] = tmp;
                    storeIdx++;
                }
            }
            // 基准归位
            tmp = arr[storeIdx];
            arr[storeIdx] = arr[right];
            arr[right] = tmp;

            // 递归排序左右子段
            quickSortSegment(arr, left, storeIdx - 1, field, flags);
            quickSortSegment(arr, storeIdx + 1, right, field, flags);
        }

        /**
         * 原地排序数组，根据单个字段和选项。
         * 与原生 sortOn 的单字段版本行为一致，但忽略 UNIQUESORT(4) 和 RETURNINDEXEDARRAY(8) 选项。
         * @param arr       要排序的数组（元素应为对象）
         * @param field     用于排序的字段名（字符串）
         * @param flags     排序选项（数值，可组合：1=大小写不敏感，2=降序，16=数值比较）
         */
        public static function sortOnField(arr:Array, field:String, flags:int = 0):void {
            if (arr.length <= 1)
                return;
            // 屏蔽无关选项
            flags &= ~(4 | 8);
            quickSortSegment(arr, 0, arr.length - 1, field, flags);
        }

        /**
         * 汉字提取，过率字符串中Unicode码为4E00~9FFF的字符
         * 用于导入关卡
         * @param input 
         * @return 
         */
        public static function extractChinese(input:String):String {
            var result:String = "";
            for (var i:int = 0; i < input.length; i++) {
                var charCode:uint = input.charCodeAt(i);
                if (charCode >= 0x4E00 && charCode <= 0x9FFF)
                    result += input.charAt(i);
            }
            return result;
        }


    }
}
