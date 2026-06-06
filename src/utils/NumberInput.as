package utils {
    import starling.display.Sprite;
    import flash.ui.Keyboard;
    import ui.components.OptionButton;
    import flash.events.KeyboardEvent;
    import starling.events.Event;
    import starling.utils.Align;
    import starling.text.TextFormat;

    public class NumberInput extends MoveableSprite {

        private static var _this:NumberInput;

        private static var displayer:Sprite;

        private static var inputValue:String = "0";
        private static var prevValue:String = "";
        private static var numberText:ShadowLabel; // 计算器中显示的计算值
        private static var numberPrevText:ShadowLabel; // 计算器中显示的计算过程
        private static var textPrefix:String;
        private static var outText:ShadowLabel;

        private const COLOR:uint = 0xFF9DBB;

        private static var enableDot:Boolean = false;
        private static var enableNegative:Boolean = false;
        private static var enableCoordinate:Boolean = false;

        public function NumberInput() {
            initUI();
            visible = false;
            _this = this;
        }

        private const btnText:Vector.<String> = new <String>["Xr", "CE", "C", "<-", "Yr", "+1", "-1", "/", "7", "8", "9", "*", "4", "5", "6", "-", "1", "2", "3", "+", "+/-", "0", ".", "ok"];
        private const btnArr:Array = [];

        private function initUI():void {
            setBox(320, 430); // 80*40 一格 4*6 布局 80 50
            numberPrevText = new ShadowLabel(316, 40, prevValue, new TextFormat("downlink", 18, COLOR / 2));
            numberPrevText.x = 348;
            numberPrevText.y = 171;
            numberPrevText.format.horizontalAlign = Align.RIGHT;
            numberPrevText.touchable = false;
            numberText = new ShadowLabel(316, 40, inputValue, new TextFormat("downlink", 24, COLOR / 2));
            numberText.x = 348;
            numberText.y = 221;
            numberText.format.horizontalAlign = Align.RIGHT;
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
                btn.label.format.font = "downlink";
                btn.label.format.size = 18;
                btn.quad.width = btn.labelBG.width = 80;
                btn.quad.height = btn.labelBG.height = 50;
                btn.addEventListener("clicked", on_btn);
                addChild(btn);
                btnArr.push(btn);
                if (i % 4 != 3) {
                    x += 80;
                } else {
                    x = startX;
                    y += 50;
                }
            }
        }

        /**
         * 打开数字输入法
         * @param layer 输入法应被添加到的图层
         * @param numberText 需要处理的数字
         * @param type 数字类型
         * <p> 0 - int
         * <p> 1 - uint
         * <p> 2 - Number
         * <p> 3 - Coordinate 坐标模式
         */
        public static function awake(layer:Sprite, numberText:ShadowLabel, type:int = 0):void {
            displayer = layer;
            displayer.addChild(THIS);
            THIS.enableDrag();
            THIS.visible = true;

            switch (type) {
                case 0:
                    enableIntMode();
                    break;
                case 1:
                    enableUintMode();
                    break;
                case 2:
                    enableNumberMode();
                    break;
                case 3:
                    enableCoordinateMode();
                    break;
            }

            outText = numberText;
            splitLastNumber(numberText.text);
        }

        public static function sleep():void {
            displayer.removeChild(THIS);
            THIS.disableDrag();
            THIS.visible = false;
        }

        private static function enableIntMode():void {
            enableCoordinate = false;
            enableDot = false;
            enableNegative = true;
            for each (var btn:OptionButton in THIS.btnArr) {
                btn.touchable = true;
                btn.alpha = 1;
            }
            THIS.btnArr[0].touchable = THIS.btnArr[4].touchable = THIS.btnArr[22].touchable = false;
            THIS.btnArr[0].alpha = THIS.btnArr[4].alpha = THIS.btnArr[22].alpha = 0.4;
        }

        private static function enableUintMode():void {
            enableCoordinate = false;
            enableDot = false;
            enableNegative = false;
            for each (var btn:OptionButton in THIS.btnArr) {
                btn.touchable = true;
                btn.alpha = 1;
            }
            THIS.btnArr[0].touchable = THIS.btnArr[4].touchable = THIS.btnArr[20].touchable = THIS.btnArr[22].touchable = false;
            THIS.btnArr[0].alpha = THIS.btnArr[4].alpha = THIS.btnArr[20].alpha = THIS.btnArr[22].alpha = 0.4;
        }

        private static function enableNumberMode():void {
            enableCoordinate = false;
            enableDot = true;
            enableNegative = true;
            for each (var btn:OptionButton in THIS.btnArr) {
                btn.touchable = true;
                btn.alpha = 1;
            }
            THIS.btnArr[0].touchable = THIS.btnArr[4].touchable = false;
            THIS.btnArr[0].alpha = THIS.btnArr[4].alpha = 0.4;
        }

        private static function enableCoordinateMode():void {
            enableCoordinate = true;
            enableDot = true;
            enableNegative = false; // 虽然不允许使用相反数，但通过Xr或Yr或减法运算制作负数是可行的
            for each (var btn:OptionButton in THIS.btnArr) {
                btn.touchable = true;
                btn.alpha = 1;
            }
            THIS.btnArr[20].touchable = false;
            THIS.btnArr[20].alpha = 0.4;
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

        private static const indexMap:Array = [[0, 18], [1, 13], [2, 14], [3, 12], [4, 19], [5, 16], [6, 17], [7, 23],
            [8, 7], [9, 8], [10, 9], [11, 22], [12, 4], [13, 5], [14, 6], [15, 21],
            [16, 1], [17, 2], [18, 3], [19, 20], [20, 11], [21, 0], [22, 10], [23, 15]];

        private static function on_btn(event:Event):void {
            for each (var btn:OptionButton in THIS.btnArr) {
                if (btn.toggled) {
                    btn.untoggle();
                    var index:int = THIS.btnArr.indexOf(btn);
                    updateNumber(indexMap[index][1])
                }
            }
        }

        private static var prevOp:int; // 上一次操作
        private static var lastOp:int; // 上一次按下的运算符

        /**
         * 操作数字
         * @param 操作数
         * <p>0\~9 对应数字按钮
         * <p>10 .
         * <p>11 +\/-
         * <p>12 <-
         * <p>13 14 CE C
         * <p>15 =
         * <p>16 17 +1 -1
         * <p>18 19 Xr Yr
         * <p>20\~23 +-*\/
         */
        private static function updateNumber(value:int):void {
            // ---------- 辅助函数 ----------
            // 将当前 inputValue 解析为数字，空字符串或孤立符号视为 0
            function parseCurrent():Number {
                if (inputValue == "" || inputValue == "-" || inputValue == ".")
                    return 0;
                return Number(inputValue);
            }

            // 根据当前模式将数字格式化为字符串
            function formatNumber(num:Number):String {
                if (enableDot) {
                    // 浮点数模式：直接转换，避免科学计数法（简单处理）
                    return num.toString();
                } else {
                    if (enableNegative) {
                        // int 模式：取整
                        return int(num).toString();
                    } else {
                        // uint 模式：负数归零，再取无符号整数
                        if (num < 0)
                            num = 0;
                        return uint(num).toString();
                    }
                }
            }

            // 二元运算
            function calculate(a:Number, b:Number, op:int):Number {
                switch (op) {
                    case 20:
                        return a + b; // +
                    case 21:
                        return a - b; // -
                    case 22:
                        return a * b; // *
                    case 23:
                        return (b != 0) ? a / b : Number.POSITIVE_INFINITY; // /
                    default:
                        return NaN;
                }
            }

            // 获取运算符对应的字符
            function getOpChar(opVal:int):String {
                switch (opVal) {
                    case 20:
                        return "+";
                    case 21:
                        return "-";
                    case 22:
                        return "*";
                    case 23:
                        return "/";
                    default:
                        return "";
                }
            }

            // 判断是否是二元运算符
            function isBinaryOp(v:int):Boolean {
                return v >= 20 && v <= 23;
            }

            // 判断是否是一元运算符（+1, -1, Xr, Yr）
            function isUnaryOp(v:int):Boolean {
                return v == 16 || v == 17 || v == 18 || v == 19;
            }

            // ---------- 主逻辑 ----------
            // 处理数字输入
            if (value >= 0 && value <= 9) {
                var digit:String = value.toString();
                if (prevOp >= 20) {
                    // 上一个操作是运算符，开始新数字
                    inputValue = digit;
                } else {
                    // 否则追加数字，避免前导零（但允许 "0" 后输入数字变成 "0x"）
                    if (inputValue == "0") {
                        inputValue = digit;
                    } else {
                        inputValue += digit;
                    }
                }
            }
            // 小数点
            else if (value == 10) {
                if (inputValue.indexOf(".") == -1) {
                    // 如果前一个是运算符，则开始 "0."
                    if (prevOp >= 20)
                        inputValue = "0.";
                    else
                        inputValue += ".";
                }
            }
            // 正负切换
            else if (value == 11) {
                if (enableNegative) {
                    var num:Number = parseCurrent();
                    inputValue = formatNumber(-num);
                }
            }
            // 退格
            else if (value == 12) {
                if (inputValue.length > 1) {
                    inputValue = inputValue.substr(0, inputValue.length - 1);
                } else {
                    inputValue = "0";
                }
                if (inputValue == "-")
                    inputValue = "0";
            }
            // CE：清除当前输入
            else if (value == 13) {
                inputValue = "0";
            }
            // C：全部清除
            else if (value == 14) {
                inputValue = "0";
                prevValue = "";
            }
            // 等号/确认
            else if (value == 15) {
                // 如果当前是确认模式（prevValue 为空，按钮显示 "ok"）
                if (THIS.btnArr[23].label.text == "ok") {
                    outText.text = textPrefix + inputValue;
                    sleep();
                    return;
                }
                // 否则执行计算
                else {
                    // 如果 prevValue 为空，则无计算（但按钮显示 "=" 时通常不应为空）
                    if (prevValue == "") {
                        // 此时可能直接按等号，不做处理
                    } else {
                        // 解析前一个表达式：格式为 "a op" 或 "a op b ="
                        // 简单处理：如果 prevValue 以 "=" 结尾，说明已经计算过，则重置
                        if (prevValue.charAt(prevValue.length - 1) == "=") {
                            // 已计算过，再次按等号无意义，可以忽略或重新开始
                        } else {
                            // 尝试从 prevValue 中提取第一个数和运算符
                            var parts:Array = prevValue.split(" ");
                            if (parts.length >= 2) {
                                var a:Number = Number(parts[0]);
                                var opStr:String = parts[1];
                                var b:Number = parseCurrent();
                                var opVal:int = 0;
                                switch (opStr) {
                                    case "+":
                                        opVal = 20;
                                        break;
                                    case "-":
                                        opVal = 21;
                                        break;
                                    case "*":
                                        opVal = 22;
                                        break;
                                    case "/":
                                        opVal = 23;
                                        break;
                                }
                                var result:Number = calculate(a, b, opVal);
                                inputValue = formatNumber(result);
                                prevValue = formatNumber(a) + " " + opStr + " " + formatNumber(b) + " =";
                            }
                        }
                    }
                }
            }
            // 一元运算符：+1, -1, Xr, Yr
            else if (isUnaryOp(value)) {
                var current:Number = parseCurrent();
                var newVal:Number;
                var opDisplay:String = "";
                switch (value) {
                    case 16: // +1
                        newVal = current + 1;
                        opDisplay = "+ 1";
                        break;
                    case 17: // -1
                        newVal = current - 1;
                        opDisplay = "- 1";
                        break;
                    case 18: // Xr
                        newVal = 1024 - current; // 硬编码，可根据需要调整
                        opDisplay = "Xr";
                        break;
                    case 19: // Yr
                        newVal = 768 - current;
                        opDisplay = "Yr";
                        break;
                }
                prevValue = inputValue + " " + opDisplay;
                inputValue = formatNumber(newVal);
                lastOp = value;
            }
            // 二元运算符：+ - * /
            else if (isBinaryOp(value)) {
                // 如果 prevValue 为空，则开始新表达式
                if (prevValue == "" || prevValue.charAt(prevValue.length - 1) == "=") {
                    prevValue = inputValue + " " + getOpChar(value);
                    inputValue = "0"; // 等待输入第二个数
                }
                // 如果 prevValue 非空且 inputValue 为 "0"（刚输入运算符后），则替换运算符
                else if (prevValue != "" && inputValue == "0") {
                    // 替换最后一个运算符
                    var lastSpace:int = prevValue.lastIndexOf(" ");
                    if (lastSpace != -1) {
                        prevValue = prevValue.substr(0, lastSpace + 1) + getOpChar(value);
                    } else {
                        prevValue = inputValue + " " + getOpChar(value);
                    }
                }
                // 否则，已有完整的表达式（a op b），需要先计算再应用新运算符
                else {
                    // 先模拟按等号计算当前表达式
                    if (prevValue.indexOf("=") == -1) {
                        // 解析并计算
                        var parts2:Array = prevValue.split(" ");
                        if (parts2.length >= 2) {
                            var a2:Number = Number(parts2[0]);
                            var op2:String = parts2[1];
                            var b2:Number = parseCurrent();
                            var opVal2:int = 0;
                            switch (op2) {
                                case "+":
                                    opVal2 = 20;
                                    break;
                                case "-":
                                    opVal2 = 21;
                                    break;
                                case "*":
                                    opVal2 = 22;
                                    break;
                                case "/":
                                    opVal2 = 23;
                                    break;
                            }
                            var res:Number = calculate(a2, b2, opVal2);
                            inputValue = formatNumber(res);
                            prevValue = formatNumber(a2) + " " + op2 + " " + formatNumber(b2) + " =";
                        }
                    }
                    // 然后设置新运算符
                    prevValue = inputValue + " " + getOpChar(value);
                    inputValue = "0";
                }
                lastOp = value;
            }

            // 更新显示
            prevOp = value;
            THIS.btnArr[23].label.text = (prevValue == "") ? "ok" : "=";
            numberText.text = inputValue;
            numberPrevText.text = prevValue;
        }

        private static function splitLastNumber(str:String):void {
            // 正则表达式：匹配开头任意字符（非贪婪）后跟结尾的连续数字
            var pattern:RegExp = /^(.*?)(-?\d+(?:\.\d+)?)$/;
            var result:Object = pattern.exec(str);

            if (result == null)
                throw new Error("字符串末尾没有数字");

            textPrefix = result[1];
            inputValue = result[2];
        }
    }
}
