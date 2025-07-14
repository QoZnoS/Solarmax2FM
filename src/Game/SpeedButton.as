package Game {
    import flash.geom.Point;
    import starling.display.Image;
    import starling.display.Quad;
    import starling.display.Sprite;
    import starling.events.Touch;
    import starling.events.TouchEvent;
    import utils.GS;

    public class SpeedButton extends Sprite {
        public var quad:Quad;
        public var image:Image;
        public var down:Boolean;
        public var hitPoint:Point;
        public var buttonArray:Vector.<SpeedButton>;
        public var toggled:Boolean;
        public var scene:SceneController;

        public function SpeedButton(_scene:SceneController, _Texture:String, _buttonArray:Vector.<SpeedButton>, _scale:Number = 1) {
            super();
            this.buttonArray = _buttonArray;
            this.scene = _scene;
            image = new Image(Root.assets.getTexture(_Texture));
            image.color = 16755370;
            image.alpha = 0.3;
            addChild(image);
            quad = new Quad(image.width + 20, image.height + 20, 16711680);
            quad.x = -10;
            quad.y = -10;
            quad.alpha = 0;
            addChild(quad);
            hitPoint = new Point(0, 0);
            toggled = false;
            setImage(_Texture, _scale)
        }

        public function setImage(_Texture:String, _scale:Number = 1):void {
            image.texture = Root.assets.getTexture(_Texture);
            image.readjustSize();
            image.width = image.texture.width;
            image.height = image.texture.height;
            image.scaleX = image.scaleY = _scale;
            image.alpha = 0.3;
            quad.width = image.width + 20;
            quad.height = image.height + 20;
            quad.x = -10;
            quad.y = -10;
            quad.alpha = 0;
        }

        public function init():void {
            toggled = false;
            image.alpha = 0.3;
            addEventListener("touch", on_touch);
        }

        public function deInit():void {
            removeEventListener("touch", on_touch);
        }

        public function on_touch(_touchEvent:TouchEvent):void {
            var _Touch:Touch = _touchEvent.getTouch(this);
            if (!_Touch)
                return;
            switch (_Touch.phase) {
                case "began":
                    image.alpha = 0.8;
                    down = true;
                    break;
                case "moved":
                    if (down && !hitTest(_Touch.getLocation(this, hitPoint))) {
                        image.alpha = 0.3;
                        down = false;
                    }
                    break;
                case "ended":
                    if (down) {
                        toggled = true;
                        image.alpha = 0.8;
                        for each (var _SpeedBtn:SpeedButton in buttonArray) {
                            if (_SpeedBtn == this)
                                continue;
                            _SpeedBtn.image.alpha = 0.3;
                            _SpeedBtn.toggled = false;
                        }
                        down = false;
                        this.changeSpeed();
                        GS.playClick();
                        break;
                    }
            }
        }

        public function changeSpeed():void {
            switch (buttonArray.indexOf(this)) {
                case 0:
                    if (scene.speedMult != 0.125) {
                        scene.speedMult *= 0.5;
                    }
                    break;
                case 1:
                    scene.speedMult = 1;
                    break;
                case 2:
                    if (scene.speedMult != 8) {
                        scene.speedMult *= 2;
                    }
                    break;
            }
            buttonArray[1].setImage("btn_speed" + scene.speedMult + "x", 0.75 + 0.6 * Globals.textSize);
            buttonArray[1].x = buttonArray[2].x - buttonArray[1].width * 0.8;
            buttonArray[1].image.alpha = 0.6;
            if (scene.speedMult == 1)
                buttonArray[1].x -= 9;
            else if (scene.speedMult > 1)
                buttonArray[1].x -= 7;
            if (scene.speedMult > 0.125 && scene.speedMult < 8) {
                buttonArray[0].image.alpha = 0.3;
                buttonArray[2].image.alpha = 0.3;
            } else if (scene.speedMult == 0.125) {
                buttonArray[0].image.alpha = 0.8;
                buttonArray[2].image.alpha = 0.3;
            } else if (scene.speedMult == 8) {
                buttonArray[0].image.alpha = 0.3;
                buttonArray[2].image.alpha = 0.8;
            }
        }
    }
}
