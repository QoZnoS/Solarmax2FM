package Game.VictoryType {

    import UI.UIContainer;
    import starling.text.TextField;
    import starling.utils.VAlign;
    import starling.utils.HAlign;
    import starling.display.Quad;

    public class TimeVictory implements IVictoryType {

        private var time:Number;
        private var textField:TextField;
        private var background:Quad;
        //未完成，不应使用，文字应用特殊事件处理图层
        public function TimeVictory(trigger:Object) {
            time = trigger as Number;
            background = new Quad(80, 26, 0xFFFFFF);
            background.alpha = 0.2;
            textField = new TextField(80, 30, "12:00", "Downlink18", -1, 0xFF0000);
            textField.alpha = 0.8;
            background.x = textField.x = 480;
            background.y = 144;
            textField.y = 140;
            textField.hAlign = HAlign.CENTER;
            textField.vAlign = VAlign.CENTER
            UIContainer.entityLayer.addChildAt(background, 0);
            UIContainer.entityLayer.addChildAt(textField, 1);
        }

        public function update(dt:Number):int {
            time -= dt;
            var text:String = timeToString(time);
            textField.text = text;
            if (time <= 0){
                UIContainer.entityLayer.removeChild(textField);
                return Globals.playerTeam;
            }
            return -1;
        }

        private function timeToString(time:Number):String {
            var mins:int = Math.floor(time / 60);
            var sec:int = time % 60;
            return padZero(mins) + ":" + padZero(sec);
        }

        private function padZero(num:int):String {
            return (num < 10) ? "0" + num : num.toString();
        }

        public function get type():String {
            return VictoryTypeFactory.TIME_TYPE;
        }
    }
}
