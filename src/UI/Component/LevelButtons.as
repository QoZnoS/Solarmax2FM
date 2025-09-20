package UI.Component {
    import starling.display.Sprite;
    import starling.text.TextField;

    public class LevelButtons extends Sprite {
        public var buttons:Array;

        public function LevelButtons() {
            super();
            buttons = [];
            var _startBtn:TextField = new TextField(100, 40, "S2", "Downlink16", -1, 16755370);
            _startBtn.pivotX = 50;
            _startBtn.pivotY = 20;
            _startBtn.alpha = 0.6;
            _startBtn.blendMode = "add";
            _startBtn.x = 0;
            addChild(_startBtn);
            buttons.push(_startBtn);
            updateLevels();
        }

        public function updateSize():void {
            const _FONT_SIZES:Array = ["Downlink12", "Downlink16", "Downlink20"];
            var _fontName:String = _FONT_SIZES[Globals.textSize];
            for each (var _btn:TextField in buttons) {
                _btn.fontName = _fontName;
                _btn.fontSize = -1;
            }
        }

        public function update(_dt:Number, _level:int):void {
            var _btn:TextField = null;
            for (var i:int = 0; i < buttons.length; i++) {
                _btn = buttons[i];
                var _distance:Number = Math.abs(this.x - 512 + _btn.x);
                _btn.alpha = (1 - Math.min(_distance / 600, 1)) * 0.8;
                if (i > Globals.levelReached + 1)
                    _btn.alpha *= 0.3;
                else if (i == _level)
                    _btn.alpha = 1;
            }
        }

        public function updateLevels():void {
            for (var i:int = buttons.length - 1; i > 0; i--) {
                removeChild(buttons[i]);
                buttons.pop();
            }
            var levelData:Object = LevelData.level.data[Globals.currentData].level;
            for (i = 0; i < levelData.length; i++) {
                var _levelText:String = levelData[i].name ? levelData[i].name : ((i + 1 < 10) ? ("0" + (i + 1).toString()) : (i + 1).toString());
                var _buttonColor:uint = levelData[i].color ? levelData[i].color : 0xFFAAAA;
                var _levelBtn:TextField = new TextField(100, 200, _levelText, "Downlink16", -1, _buttonColor);
                _levelBtn.pivotX = 50;
                _levelBtn.pivotY = 100;
                _levelBtn.alpha = 0.6;
                _buttonColor == 0 ? _levelBtn.blendMode = "normal" : _levelBtn.blendMode = "add";
                _levelBtn.x = (i + 1) * 120;
                addChild(_levelBtn);
                buttons.push(_levelBtn);
            }
            updateSize();
        }
    }
}
