package utils
{
    public class GeneralFunctions {
        
        public function GeneralFunctions() {
            throw new Error("静态类不允许实例化");
        }

        /**
         * 从数组中随机返回一个具有最小属性值的对象（数组无需排序）
         * 使用单次遍历法提高效率
         * @param arr 任意名称的数组（可以是乱序的）
         * @param propertyName 属性名称（字符串）
         * @return 随机一个具有最小属性值的对象，如果数组为空则返回null
         */
        public static function getRandomMinByProperty(arr:Array, propertyName:String):Object {
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
            
            var randomIndex:int = Math.floor(Math.random() * minValueObjects.length);
            return minValueObjects[randomIndex];
        }  
    }
}