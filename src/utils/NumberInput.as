package utils {
    import starling.display.Sprite;
    import starling.text.TextField;
    import flash.ui.Keyboard;
    import starling.utils.VAlign;
    import starling.utils.HAlign;
    import ui.components.OptionButton;
    import flash.events.KeyboardEvent;
    import starling.events.Event;

    public class NumberInput extends MoveableSprite {

        private static var _this:NumberInput;

        private static var displayer:Sprite;

        private static var intValue:int = 0;
        private static var uintValue:uint = 0;
        private static var numberValue:Number = 0;
        private static var textPrefix:String;
        private static var numberText:TextField; // 计算器中显示的计算值
        private static var intPrevValue:int = 0;
        private static var uintPrevValue:uint = 0;
        private static var numberPrevValue:Number = 0;
        private static var numberPrevText:TextField; // 计算器中显示的计算过程

        private const COLOR:uint = 0xFF9DBB;

        public static var enableDot:Boolean = false;
        public static var enableNegative:Boolean = false;
        public static var enableCoordinate:Boolean = false;

        public function NumberInput() {
            initUI();
            visible = false;
            _this = this;
        }

        private const btnText:Vector.<String> = new <String>["Xr", "CE", "C", "<-", "Yr", "+1", "-1", "/", "7", "8", "9", "*", "4", "5", "6", "-", "1", "2", "3", "+", "+/-", "0", ".", "="];
        private const btnArr:Array = [];

        private function initUI():void {
            setBox(320, 430); // 80*40 一格 4*6 布局 80 50
            numberPrevText = new TextField(316, 40, "Test", "Downlink18", -1, COLOR / 2);
            numberPrevText.x = 348;
            numberPrevText.y = 171;
            numberPrevText.hAlign = HAlign.RIGHT;
            numberPrevText.touchable = false;
            numberText = new TextField(316, 40, "0", "Downlink24", -1, COLOR);
            numberText.x = 348;
            numberText.y = 221;
            numberText.hAlign = HAlign.RIGHT;
            numberText.touchable = false;
            addChild(numberText);
            addChild(numberPrevText);

            const startX:int = 358;
            const startY:int = 301;
            var x:int = startX;
            var y:int = startY;
            for (var i:int = 0; i < 24; i++) {
                var btn:OptionButton = new OptionButton(btnText[i], COLOR, btnArr);
                btn.x = x;
                btn.y = y;
                btn.label.fontName = "Downlink18";
                btn.quad.width = btn.labelBG.width = 80;
                btn.quad.height = btn.labelBG.height = 50;
                btn.addEventListener("clicked", on_btn);
                addChild(btn);
                btnArr.push(btn);
                if (i % 4 != 3){
                    x += 80;
                } else {
                    x = startX;
                    y += 50;
                }
            }

        }

        public static function awake(layer:Sprite, numberText:TextField):void {
            displayer = layer;
            displayer.addChild(THIS);
            THIS.enableDrag();
            THIS.visible = true;

            numberText = numberText;
            splitLastNumber(numberText.text);
        }

        public static function sleep():void {
            displayer.removeChild(THIS);
            THIS.disableDrag();
            THIS.visible = false;
        }

        public static function get THIS():NumberInput {
            return _this;
        }

        public static function get visible():Boolean {
            return THIS.visible;
        }

        public static function on_key_down(event:KeyboardEvent):void {
            switch (event.keyCode) {
                case Keyboard.NUMBER_0:
                case Keyboard.NUMBER_1:
                case Keyboard.NUMBER_2:
                case Keyboard.NUMBER_3:
                case Keyboard.NUMBER_4:
                case Keyboard.NUMBER_5:
                case Keyboard.NUMBER_6:
                case Keyboard.NUMBER_7:
                case Keyboard.NUMBER_8:
                case Keyboard.NUMBER_9:
                    updateNumber(event.keyCode - Keyboard.NUMBER_0);
                    break;
                case Keyboard.NUMPAD_0:
                case Keyboard.NUMPAD_1:
                case Keyboard.NUMPAD_2:
                case Keyboard.NUMPAD_3:
                case Keyboard.NUMPAD_4:
                case Keyboard.NUMPAD_5:
                case Keyboard.NUMPAD_6:
                case Keyboard.NUMPAD_7:
                case Keyboard.NUMPAD_8:
                case Keyboard.NUMPAD_9:
                    updateNumber(event.keyCode - Keyboard.NUMPAD_0);
                    break;
                default:
                    break;
            }
        }
        
        private static const indexMap:Array = [
            [0, 18], [1, 20], [2, 21], [3, 22], [4, 19], [5, 16], [6, 17], [7, 13],
            [8, 7], [9, 8], [10, 9], [11, 12], [12, 4], [13, 5], [14, 6], [15, 11],
            [16, 1], [17, 2], [18, 3], [19, 10], [20, 14], [21, 0], [22, 15], [23, 23]
        ];
        private static function on_btn(event:Event):void {
            for each(var btn:OptionButton in THIS.btnArr) {
                if (btn.toggled) {
                    btn.untoggle();
                    var index:int = THIS.btnArr.indexOf(btn);
                    updateNumber(indexMap[index][1])
                }
            }
        }

        /**
         * 操作数字
         * @param 操作数
         * <p>0\~9 对应数字按钮
         * <p>10\~13 +-*\/
         * <p>14 +\/-
         * <p>15 .
         * <p>16 17 +1 -1
         * <p>18 19 Xr Yr
         * <p>20 21 CE C
         * <p>22 <-
         * <p>23 =
         */
        private static function updateNumber(value:int):void {
            if (!enableDot && enableNegative) {
                // int
            } else if (!enableDot && !enableNegative) {
                // uint
            } else {
                // Number
            }
        }

        private static function splitLastNumber(str:String):void {
            // 正则表达式：匹配开头任意字符（非贪婪）后跟结尾的连续数字
            var pattern:RegExp = /^(.*?)(-?\d+(?:\.\d+)?)$/;
            var result:Object = pattern.exec(str);

            if (result == null)
                throw new Error("字符串末尾没有数字");

            textPrefix = result[0];

            if (!enableDot && enableNegative)
                intValue = int(result[1]);
            else if (!enableDot && !enableNegative)
                uintValue = uint(result[1]);
            else
                numberValue = Number(result[1]);
        }
    }
}
