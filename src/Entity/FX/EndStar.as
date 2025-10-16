// 在EndScene中被调用
package Entity.FX {
    import Menus.EndScene;
    import starling.display.Image;
    import Entity.GameEntity;

    public class EndStar extends GameEntity {
        public static const STATE_GROW:int = 0;
        public static const STATE_SHRINK:int = 1;
        public static const STATE_BLINK:int = 2;

        public var x:Number;
        public var y:Number;
        public var mult:Number;
        public var delay:Number;

        private var image:Image;
        private var glare1:Image;
        private var glare2:Image;
        private var glare3:Image;
        private var glare4:Image;
        private var size:Number;
        private var endScene:EndScene;
        private var state:int;

        public function EndStar() {
            super();
            image = new Image(Root.assets.getTexture("spot_glow"));
            image.pivotX = image.pivotY = image.width * 0.5;
            image.color = Globals.teamColors[1];
            image.blendMode = "add";
            glare1 = new Image(Root.assets.getTexture("warp_glare"));
            glare1.pivotX = glare1.width * 0.5;
            glare1.pivotY = glare1.height * 0.5;
            glare1.color = Globals.teamColors[1];
            glare1.alpha = 0.6;
            glare1.blendMode = "add";
            glare2 = new Image(Root.assets.getTexture("warp_glare"));
            glare2.pivotX = glare2.width * 0.5;
            glare2.pivotY = glare2.height * 0.5;
            glare2.color = Globals.teamColors[1];
            glare2.alpha = 0.6;
            glare2.blendMode = "add";
            glare2.rotation = 1.5707963267948966;
            glare3 = new Image(Root.assets.getTexture("warp_glare"));
            glare3.pivotX = glare3.width * 0.5;
            glare3.pivotY = glare3.height * 0.5;
            glare3.color = Globals.teamColors[1];
            glare3.alpha = 0.4;
            glare3.blendMode = "add";
            glare3.rotation = 0.7853981633974483;
            glare4 = new Image(Root.assets.getTexture("warp_glare"));
            glare4.pivotX = glare4.width * 0.5;
            glare4.pivotY = glare4.height * 0.5;
            glare4.color = Globals.teamColors[1];
            glare4.alpha = 0.4;
            glare4.blendMode = "add";
            glare4.rotation = -0.7853981633974483;
        }

        public function initStar(endScene:EndScene, x:Number, y:Number, delay:Number):void {
            init(null);
            this.endScene = endScene;
            this.x = x;
            this.y = y;
            this.delay = delay;
            size = 0;
            mult = 0.3 + Math.random() * 0.5;
            image.x = glare1.x = glare2.x = glare3.x = glare4.x = x;
            image.y = glare1.y = glare2.y = glare3.y = glare4.y = y;
            image.scaleX = image.scaleY = glare1.scaleX = glare1.scaleY = glare2.scaleX = glare2.scaleY = glare3.scaleX = glare3.scaleY = glare4.scaleX = glare4.scaleY = 0;
            Globals.teamColors[1] == 0 ? image.blendMode = glare1.blendMode = glare2.blendMode = glare3.blendMode = glare4.blendMode = "normal" : image.blendMode = glare1.blendMode = glare2.blendMode = glare3.blendMode = glare4.blendMode = "add";
            endScene.addChildAt(glare1, 0);
            endScene.addChildAt(glare2, 0);
            endScene.addChildAt(glare3, 0);
            endScene.addChildAt(glare4, 0);
            endScene.addChildAt(image, 0);
            state = STATE_GROW;
        }

        override public function deInit():void {
            endScene.removeChild(glare1);
            endScene.removeChild(glare2);
            endScene.removeChild(glare3);
            endScene.removeChild(glare4);
            endScene.removeChild(image);
        }

        override public function update(dt:Number):void {
            image.x = glare1.x = glare2.x = glare3.x = glare4.x = x;
            image.y = glare1.y = glare2.y = glare3.y = glare4.y = y;
            if (delay > 0) {
                delay -= dt;
                return;
            }
            switch (state) {
                case STATE_GROW:
                    size += dt * 3;
                    if (size > 1.5) {
                        size = 1.5;
                        state = STATE_SHRINK;
                    }
                    image.scaleX = image.scaleY = size * 0.3 * mult;
                    break;
                case STATE_SHRINK:
                    size -= dt * 0.5;
                    if (size <= 1) {
                        size = 1;
                        state = STATE_BLINK;
                    }
                    image.scaleX = image.scaleY = size * 0.3 * mult;
                    break;
                case STATE_BLINK:
                default:
                    break;
            }
            var scale:Number = size * mult * (0.8 + Math.random() * 0.2);
            glare1.scaleX = glare2.scaleX = scale * 1;
            glare1.scaleY = glare2.scaleY = scale * 0.3;
            glare3.scaleX = glare4.scaleX = scale * 0.75;
            glare3.scaleY = glare4.scaleY = scale * 0.3;
        }
    }
}
