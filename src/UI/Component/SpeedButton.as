package UI.Component {
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
        public var scene:SceneController; // 速度变量在scene中修改

        public function SpeedButton(scene:SceneController, texture:String, buttonArray:Vector.<SpeedButton>, scale:Number = 1) {
            super();
            this.buttonArray = buttonArray;
            this.scene = scene;
            image = new Image(Root.assets.getTexture(texture));
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
            setImage(texture, scale)
        }

        public function setImage(texture:String, scale:Number = 1):void {
            image.texture = Root.assets.getTexture(texture);
            image.readjustSize();
            image.width = image.texture.width;
            image.height = image.texture.height;
            image.scaleX = image.scaleY = scale;
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

        public function on_touch(touchEvent:TouchEvent):void {
            var touch:Touch = touchEvent.getTouch(this);
            if (!touch)
                return;
            switch (touch.phase) {
                case "began":
                    image.alpha = 0.8;
                    down = true;
                    break;
                case "moved":
                    if (down && !hitTest(touch.getLocation(this, hitPoint))) {
                        image.alpha = 0.3;
                        down = false;
                    }
                    break;
                case "ended":
                    if (down) {
                        toggled = true;
                        image.alpha = 0.8;
                        for each (var speedBtn:SpeedButton in buttonArray) {
                            if (speedBtn == this)
                                continue;
                            speedBtn.image.alpha = 0.3;
                            speedBtn.toggled = false;
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
                    if (scene.speedMult > 0.125)
                        scene.speedMult *= 0.5;
                    break;
                case 1:
                    scene.speedMult = 1;
                    break;
                case 2:
                    if (scene.speedMult < 8)
                        scene.speedMult *= 2;
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

        public function set color(value:uint):void{
            image.color = value;
        }
    }
}
