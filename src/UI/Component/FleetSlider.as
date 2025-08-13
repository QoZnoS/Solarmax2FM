package UI.Component {
    import starling.display.Quad;
    import starling.display.Sprite;
    import starling.events.Touch;
    import starling.events.TouchEvent;
    import starling.text.TextField;

    public class FleetSlider extends Sprite {

        private var _quad1:Quad;
        private var _quad2:Quad;
        private var _touchQuad:Quad;
        private var _label:TextField;
        private var _total:Number;
        private var _box:Sprite;
        private var _boxQuad1:Quad;
        private var _boxQuad2:Quad;
        private var _boxQuad3:Quad;
        private var _boxQuad4:Quad;
        private var _touchWidth:Number;
        private var _touchHeight:Number;
        private var _boxWidth:Number;
        private var _boxHeight:Number;
        private var _thickness:Number;
        private var _type:int;

        public function FleetSlider(_type:int) {
            var _font:String = null;
            super();
            switch (_type) {
                case 0:
                case 1:
                    _touchWidth = 512;
                    _touchHeight = 40;
                    _boxWidth = 50;
                    _boxHeight = 20;
                    _thickness = 2;
                    _font = "Downlink12";
                    break;
                case 2:
                    _touchWidth = 640;
                    _touchHeight = 60;
                    _boxWidth = 80;
                    _boxHeight = 30;
                    _thickness = 2;
                    _font = "Downlink18";
                    break;
                case 3:
                    _touchWidth = 40;
                    _touchHeight = 360;
                    _boxWidth = 50;
                    _boxHeight = 20;
                    _thickness = 2;
                    _font = "Downlink12";
                    break;
            }
            this._type = _type;
            if (_type == 3) {
                _label = new TextField(_boxWidth * 2, _boxHeight, "100%", _font, -1, 16755370);
                _label.pivotX = _boxWidth;
                _label.pivotY = _label.y = _boxHeight * 0.5;
                _label.x = _boxWidth * 0.5;
                _quad1 = new Quad(_thickness, _touchHeight, 16755370);
                _quad1.x = _boxWidth * 0.5 - _thickness * 0.5;
                _quad2 = new Quad(_thickness, _touchHeight, 16755370);
                _quad2.pivotY = _quad2.y = _touchHeight;
                _quad2.x = _boxWidth * 0.5 - _thickness * 0.5;
            } else {
                _label = new TextField(_boxWidth, _boxHeight * 2, "100%", _font, -1, 16755370);
                _label.pivotX = _label.x = _boxWidth * 0.5;
                _label.pivotY = _boxHeight;
                _label.y = _boxHeight * 0.5;
                _quad1 = new Quad(_touchWidth, _thickness, 16755370);
                _quad1.y = _boxHeight * 0.5 - _thickness * 0.5;
                _quad2 = new Quad(_touchWidth, _thickness, 16755370);
                _quad2.pivotX = _quad2.x = _touchWidth;
                _quad2.y = _boxHeight * 0.5 - _thickness * 0.5;
            }
            _label.alpha = 0.6;
            _label.pivotX -= 2;
            addChild(_label);
            _quad1.alpha = 0.5;
            addChild(_quad1);
            _quad2.alpha = 0.25;
            addChild(_quad2);
            _box = new Sprite();
            _boxQuad1 = new Quad(_boxWidth, _thickness, 16755370);
            _boxQuad1.x = -_boxWidth * 0.5;
            _boxQuad1.y = -_boxHeight * 0.5 - _thickness;
            _box.addChild(_boxQuad1);
            _boxQuad2 = new Quad(_boxWidth, _thickness, 16755370);
            _boxQuad2.x = -_boxWidth * 0.5;
            _boxQuad2.y = _boxHeight * 0.5;
            _box.addChild(_boxQuad2);
            _boxQuad3 = new Quad(_thickness, _boxHeight, 16755370);
            _boxQuad3.x = -_boxWidth * 0.5;
            _boxQuad3.y = -_boxHeight * 0.5;
            _box.addChild(_boxQuad3);
            _boxQuad4 = new Quad(_thickness, _boxHeight, 16755370);
            _boxQuad4.x = _boxWidth * 0.5 - _thickness;
            _boxQuad4.y = -_boxHeight * 0.5;
            _box.addChild(_boxQuad4);
            _box.alpha = 0.5;
            _box.x = _label.x;
            _box.y = _label.y;
            addChild(_box);
            _touchQuad = new Quad(_touchWidth + _boxWidth, _touchHeight, 16711680);
            _touchQuad.x = -_boxWidth * 0.5;
            _touchQuad.y = -_boxHeight * 0.5;
            _touchQuad.alpha = 0;
            addChild(_touchQuad);
        }

        public function init():void {
            _total = 1;
            _touchQuad.addEventListener("touch", on_touch);
            update()
        }

        public function deInit():void {
            _touchQuad.removeEventListener("touch", on_touch);
        }

        private function on_touch(_touch:TouchEvent):void {
            var _TouchArray:Vector.<Touch> = _touch.getTouches(_touchQuad);
            if (!_TouchArray)
                return;
            if (_TouchArray.length == 1) // 确保只有一个触点
            {
                var _Touch:Touch = _TouchArray[0];
                switch (_Touch.phase) {
                    case "began":
                    case "moved":
                    case "ended":
                        _type == 3 ? _total = 1 - (_Touch.getLocation(this).y - _boxHeight * 0.5) / (_touchHeight - _boxHeight) : _total = (_Touch.getLocation(this).x - _boxWidth * 0.5) / (_touchWidth - _boxWidth);
                        _total = Math.max(0.0001, Math.min(_total, 1));
                        break;
                }
                update();
            }
        }

        private function update():void {
            if (_type == 3) {
                _label.y = _box.y = _boxHeight * 0.5 + (1 - _total) * (_touchHeight - _boxHeight);
                _label.text = int(_total * 100).toString() + "%";
                _quad1.setVertexPosition(1, _thickness, _label.y + _boxHeight * 0.5);
                _quad1.setVertexPosition(0, 0, _label.y + _boxHeight * 0.5);
                _quad2.setVertexPosition(3, _thickness, _label.y - _boxHeight * 0.5);
                _quad2.setVertexPosition(2, 0, _label.y - _boxHeight * 0.5);
            } else {
                _label.x = _box.x = _boxWidth * 0.5 + _total * (_touchWidth - _boxWidth);
                _label.text = int(_total * 100).toString() + "%";
                _quad1.setVertexPosition(1, _label.x - _boxWidth * 0.5, 0);
                _quad1.setVertexPosition(3, _label.x - _boxWidth * 0.5, _thickness);
                _quad2.setVertexPosition(0, _label.x + _boxWidth * 0.5, 0);
                _quad2.setVertexPosition(2, _label.x + _boxWidth * 0.5, _thickness);
            }
        }

        public function get perc():Number{
            return this._total;
        }

        public function set perc(_total:Number):void{
            this._total = _total;
            update();
        }

        public function get box_y():Number{
            return _touchHeight * 0.5 - _boxHeight + 5;
        }

        public function get box_x():Number{
            return _touchWidth * 0.5 - _boxWidth * 0.5;
        }

        public function set color(value:uint):void{
            _boxQuad1.color = _boxQuad2.color = _boxQuad3.color = _boxQuad4.color = value;
            _quad1.color = _quad2.color = _label.color = value;
        }
    }
}
