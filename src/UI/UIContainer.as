package UI {
    import starling.display.Sprite;
    import starling.core.Starling;

    public class UIContainer extends Sprite {

        public var touchCL:TouchCtrlLayer;
        public var traditionalCL:TraditionalCtrlLayer;
        public var btnL:BtnLayer;

        public var scene:SceneController

        public function UIContainer(_scene:SceneController) {
            this.scene = _scene;
            touchCL = new TouchCtrlLayer(scene.gameScene);
            traditionalCL = new TraditionalCtrlLayer(scene.gameScene);
            btnL = new BtnLayer(scene)

            addChild(touchCL);
            addChild(traditionalCL);
            addChild(btnL);

            btnL.blendMode = "add";
            touchCL.visible = traditionalCL.visible = false;
        }

        public function initLevel():void {
            if (Globals.touchControls) {
                touchCL.visible = true;
                touchCL.init();
            } else {
                traditionalCL.visible = true;
                traditionalCL.init();
            }
            btnL.initLevel()

            this.alpha = 0;
            Starling.juggler.tween(this, Globals.transitionSpeed, {"alpha": 1,
                    "transition": "easeInOut"});

        }

        public function deinitLevel():void {
            Starling.juggler.removeTweens(this)
            Starling.juggler.tween(this, Globals.transitionSpeed, {"alpha": 0,
                    "onComplete": function():void {
                        btnL.deinitLevel()
                    },
                    "transition": "easeInOut"});

            if (Globals.touchControls) {
                touchCL.visible = false;
                touchCL.deinit();
            } else {
                traditionalCL.visible = false;
                traditionalCL.deinit();
            }

        }

        public function update():void {
            Globals.touchControls ? touchCL.draw() : traditionalCL.draw();
        }
    }
}
