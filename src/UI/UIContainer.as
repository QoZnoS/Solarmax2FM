package UI {
    import starling.display.Sprite;
    import starling.core.Starling;
    import starling.display.QuadBatch;

    public class UIContainer extends Sprite {

        public var entityL:EntityLayer;
        public var behaviorBatch:QuadBatch;
        public var touchCL:TouchCtrlLayer;
        public var tradiCL:TraditionalCtrlLayer;
        public var btnL:BtnLayer;

        public var scene:SceneController;

        public function UIContainer(_scene:SceneController) {
            this.scene = _scene;
            entityL = new EntityLayer();
            behaviorBatch = new QuadBatch();
            touchCL = new TouchCtrlLayer(this);
            tradiCL = new TraditionalCtrlLayer(this);
            btnL = new BtnLayer(this);

            addChild(entityL);
            addChild(behaviorBatch);
            addChild(touchCL);
            addChild(tradiCL);
            addChild(btnL);

            btnL.blendMode = "add";
            touchCL.visible = tradiCL.visible = false;

            entityL.x = entityL.pivotX = 512;
            entityL.y = entityL.pivotY = 384;
            behaviorBatch.x = behaviorBatch.pivotX = 512;
            behaviorBatch.y = behaviorBatch.pivotY = 384;
        }

        public function initLevel():void {
            if (Globals.touchControls) {
                touchCL.visible = true;
                touchCL.init();
            } else {
                tradiCL.visible = true;
                tradiCL.init();
            }
            btnL.initLevel()

            entityL.alpha = 0;
            entityL.scaleX = entityL.scaleY = 0.7;
            entityL.y = 354;
            behaviorBatch.alpha = 0;
            behaviorBatch.scaleX = behaviorBatch.scaleY = 0.7;
            behaviorBatch.y = 354
            btnL.alpha = 0;
            Starling.juggler.tween(entityL, Globals.transitionSpeed, {"alpha": 1,
                    "scaleX": 1,
                    "scaleY": 1,
                    "y": 384,
                    "transition": "easeInOut"});
            Starling.juggler.tween(behaviorBatch, Globals.transitionSpeed, {"alpha": 1,
                    "scaleX": 1,
                    "scaleY": 1,
                    "y": 384,
                    "transition": "easeInOut"});
            Starling.juggler.tween(btnL, Globals.transitionSpeed, {"alpha": 1,
                    "transition": "easeInOut"});
        }

        public function deinitLevel():void {
            Starling.juggler.removeTweens(entityL);
            Starling.juggler.removeTweens(behaviorBatch);
            Starling.juggler.removeTweens(btnL);
            Starling.juggler.tween(entityL, Globals.transitionSpeed, {"alpha": 0,
                    "scaleX": 0.7,
                    "scaleY": 0.7,
                    "y": 354,
                    "transition": "easeInOut"});
            Starling.juggler.tween(behaviorBatch, Globals.transitionSpeed, {"alpha": 0,
                    "scaleX": 0.7,
                    "scaleY": 0.7,
                    "y": 354,
                    "transition": "easeInOut"});
            Starling.juggler.tween(btnL, Globals.transitionSpeed, {"alpha": 0,
                    "onComplete": function():void {
                        btnL.deinitLevel()
                    },
                    "transition": "easeInOut"});

            if (Globals.touchControls) {
                touchCL.visible = false;
                touchCL.deinit();
            } else {
                tradiCL.visible = false;
                tradiCL.deinit();
            }
        }

        public function update():void {
            behaviorBatch.reset();
            Globals.touchControls ? touchCL.draw() : tradiCL.draw();
        }
    }
}
