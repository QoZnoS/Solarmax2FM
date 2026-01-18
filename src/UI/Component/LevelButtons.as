package UI.Component {
    import starling.display.Sprite;
    import starling.text.TextField;
    import starling.filters.ColorMatrixFilter;

    public class LevelButtons extends Sprite {
        private var buttons:Vector.<Vector.<TextField>>;

        public function LevelButtons() {
            super();
            buttons = new Vector.<Vector.<TextField>>;
            var startBtn:TextField = new TextField(100, 40, "S2", "Downlink16", -1, 16755370);
            startBtn.pivotX = 50;
            startBtn.pivotY = 20;
            startBtn.alpha = 0.6;
            startBtn.blendMode = "add";
            startBtn.x = 0;
            addChild(startBtn);
            var startVct:Vector.<TextField> = new Vector.<TextField>;
            startVct.push(startBtn);
            buttons.push(startVct);
            updateLevels();
        }

        public function updateSize():void {
            const FONT_SIZES:Array = ["Downlink12", "Downlink16", "Downlink20"];
            var fontName:String = FONT_SIZES[Globals.textSize];
            for each(var btns:Vector.<TextField> in buttons) {
                for each(var btn:TextField in btns) {
                    btn.fontName = fontName;
                    btn.fontSize = -1;
                }
            }
        }

        public function update(_dt:Number, _level:int):void {
            var btn:TextField = null;
            for (var i:int = 0; i < buttons.length; i++) {
                for each(btn in buttons[i]){
                    var distance:Number = Math.abs(this.x - 512 + btn.x);
                    btn.alpha = (1 - Math.min(distance / 600, 1)) * 0.4;
                    if (i == 0)
                        btn.alpha *= 2;
                    if (i > Globals.levelReached + 1)
                        btn.alpha *= 0.3;
                    else if (i == _level)
                        btn.alpha = 0.5;
                }
            }
        }

        public function updateLevels():void {
            for (var i:int = buttons.length - 1; i > 0; i--) {
                for (var j:int = buttons[i].length - 1; j >= 0; j--)
                    buttons[i].pop();
                buttons.pop();
            }
            removeChildren(1);
            var levelData:Array = LevelData.level;
            var filter:ColorMatrixFilter = new ColorMatrixFilter();
            filter.adjustContrast(0.6); // 通过提高对比度来变相提高亮度
            for (i = 0; i < levelData.length; i++) {
                var textVector:Vector.<TextField> = new Vector.<TextField>;
                var levelText:String = levelData[i].name ? levelData[i].name : ((i + 1 < 10) ? ("0" + (i + 1).toString()) : (i + 1).toString());
                var buttonColor:uint = levelData[i].color ? levelData[i].color : 0xFFAAAA;
                var levelBtn:TextField = new TextField(100, 200, levelText, "Downlink16", -1, buttonColor);
                var levelBtn2:TextField = new TextField(100, 200, levelText, "Downlink16", -1, buttonColor);
                levelBtn.pivotX = levelBtn2.pivotX = 50;
                levelBtn.pivotY = levelBtn2.pivotY = 100;
                levelBtn.alpha = levelBtn2.alpha = 0.3;
                levelBtn.x = levelBtn2.x = (i + 1) * 120;
                levelBtn.blendMode = "add";
                levelBtn2.blendMode = "normal";
                levelBtn.filter = levelBtn2.filter = filter;
                addChild(levelBtn2);
                addChild(levelBtn);
                textVector.push(levelBtn);
                textVector.push(levelBtn2);
                buttons.push(textVector);
            }
            updateSize();
        }
    }
}
