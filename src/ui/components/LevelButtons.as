package ui.components {
    import managers.LevelData;

    import starling.display.Sprite;
    import managers.SaveManager;
    import utils.ShadowLabel;
    import starling.text.TextFormat;
    import starling.display.DisplayObject;

    public class LevelButtons extends Sprite {
        private var buttons:Vector.<Vector.<ShadowLabel>>;

        public function LevelButtons() {
            super();
            buttons = new Vector.<Vector.<ShadowLabel>>;
            var startBtn:ShadowLabel = new ShadowLabel(100, 40, "S2", new TextFormat("downlink", 16, 0xFFAAAA));
            startBtn.pivotX = 50;
            startBtn.pivotY = 20;
            startBtn.alpha = 0.6;
            startBtn.blendMode = "add";
            startBtn.x = 0;
            addChild(startBtn);
            var startVct:Vector.<ShadowLabel> = new Vector.<ShadowLabel>;
            startVct.push(startBtn);
            buttons.push(startVct);
            updateLevels();
        }

        public function updateSize():void {
            const FONT_SIZES:Array = [12, 16, 20];
            var fontSize:int = FONT_SIZES[SaveManager.textSize];
            for each (var btns:Vector.<ShadowLabel> in buttons) {
                for each (var btn:ShadowLabel in btns) {
                    btn.format.font = "downlink";
                    btn.format.size = fontSize;
                }
            }
        }

        public function update(_dt:Number, _level:int):void {
            var btn:ShadowLabel = null;
            for (var i:int = 0; i < buttons.length; i++) {
                for each (btn in buttons[i]) {
                    var distance:Number = Math.abs(this.x - 512 + btn.x);
                    btn.alpha = (1 - Math.min(distance / 600, 1)) * 0.4;
                    if (i == 0)
                        btn.alpha *= 2;
                    if (i > SaveManager.levelReached + 1)
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
            for (i = 1; i < this.numChildren; i++) {
                var child:DisplayObject = this.getChildAt(i);
                if (child is ShadowLabel) (child as ShadowLabel).dispose();
            }
            removeChildren(1);
            var levelData:Array = LevelData.level;
            // var filter:ColorMatrixFilter = new ColorMatrixFilter();
            // filter.adjustContrast(0.6); // 通过提高对比度来变相提高亮度
            for (i = 0; i < levelData.length; i++) {
                var textVector:Vector.<ShadowLabel> = new Vector.<ShadowLabel>;
                var levelText:String = levelData[i].name ? levelData[i].name : ((i + 1 < 10) ? ("0" + (i + 1).toString()) : (i + 1).toString());
                var buttonColor:uint = levelData[i].color ? levelData[i].color : 0xFFAAAA;
                var levelBtn:ShadowLabel = new ShadowLabel(100, 200, levelText, new TextFormat("downlink", 16, buttonColor));
                var levelBtn2:ShadowLabel = new ShadowLabel(100, 200, levelText, new TextFormat("downlink", 16, buttonColor));
                levelBtn.pivotX = levelBtn2.pivotX = 50;
                levelBtn.pivotY = levelBtn2.pivotY = 100;
                levelBtn.alpha = levelBtn2.alpha = 0.3;
                levelBtn.x = levelBtn2.x = (i + 1) * 120;
                levelBtn.blendMode = "add";
                levelBtn2.blendMode = "normal";
                // levelBtn.filter = levelBtn2.filter = filter;
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
