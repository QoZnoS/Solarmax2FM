package UI.Component {
    import starling.display.Sprite;
    import starling.text.TextField;

    public class LevelButtons extends Sprite {
        public var buttons:Array;

        public function LevelButtons() {
            super();
            buttons = [];
            var startBtn:TextField = new TextField(100, 40, "S2", "Downlink16", -1, 16755370);
            startBtn.pivotX = 50;
            startBtn.pivotY = 20;
            startBtn.alpha = 0.6;
            startBtn.blendMode = "add";
            startBtn.x = 0;
            addChild(startBtn);
            buttons.push(startBtn);
            updateLevels();
        }

        public function updateSize():void {
            const FONT_SIZES:Array = ["Downlink12", "Downlink16", "Downlink20"];
            var fontName:String = FONT_SIZES[Globals.textSize];
            for each (var btn:TextField in buttons) {
                btn.fontName = fontName;
                btn.fontSize = -1;
            }
        }

        public function update(_dt:Number, _level:int):void {
            var btn:TextField = null;
            for (var i:int = 0; i < buttons.length; i++) {
                btn = buttons[i];
                var distance:Number = Math.abs(this.x - 512 + btn.x);
                btn.alpha = (1 - Math.min(distance / 600, 1)) * 0.8;
                if (i > Globals.levelReached + 1)
                    btn.alpha *= 0.3;
                else if (i == _level)
                    btn.alpha = 1;
            }
        }

        public function updateLevels():void {
            for (var i:int = buttons.length - 1; i > 0; i--) {
                removeChild(buttons[i]);
                buttons.pop();
            }
            var levelData:Array = LevelData.level;
            for (i = 0; i < levelData.length; i++) {
                var levelText:String = levelData[i].name ? levelData[i].name : ((i + 1 < 10) ? ("0" + (i + 1).toString()) : (i + 1).toString());
                var buttonColor:uint = levelData[i].color ? levelData[i].color : 0xFFAAAA;
                var levelBtn:TextField = new TextField(100, 200, levelText, "Downlink16", -1, buttonColor);
                levelBtn.pivotX = 50;
                levelBtn.pivotY = 100;
                levelBtn.alpha = 0.6;
                buttonColor == 0 ? levelBtn.blendMode = "normal" : levelBtn.blendMode = "add";
                levelBtn.x = (i + 1) * 120;
                addChild(levelBtn);
                buttons.push(levelBtn);
            }
            updateSize();
        }
    }
}
