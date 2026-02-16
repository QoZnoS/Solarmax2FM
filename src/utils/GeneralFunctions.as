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

    }
}
