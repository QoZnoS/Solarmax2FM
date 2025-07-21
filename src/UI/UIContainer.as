package UI {
    import starling.display.Sprite;
    import starling.core.Starling;
    import starling.display.QuadBatch;
    import starling.display.Quad;

    public class UIContainer extends Sprite {

        public var entityL:EntityLayer;
        private var controlLayer:Sprite;
        public var behaviorBatch:QuadBatch;
        public var touchCL:TouchCtrlLayer;
        public var tradiCL:TraditionalCtrlLayer;
        public var btnL:BtnLayer;
        public var touchQuad:Quad;

        public var scene:SceneController;

        private var _scale:Number

        public function UIContainer(_scene:SceneController) {
            this.scene = _scene;
            touchQuad = new Quad(1024, 768, 16711680);
            entityL = new EntityLayer();
            controlLayer = new Sprite();
            behaviorBatch = new QuadBatch();
            touchCL = new TouchCtrlLayer(this);
            tradiCL = new TraditionalCtrlLayer(this);
            btnL = new BtnLayer(this);

            addChild(entityL);
            addChild(controlLayer);
            controlLayer.addChild(behaviorBatch);
            controlLayer.addChild(touchCL);
            controlLayer.addChild(tradiCL);
            addChild(touchQuad);
            addChild(btnL);

            btnL.blendMode = "add";
            touchCL.visible = tradiCL.visible = touchQuad.touchable = false;
            touchQuad.alpha = 0;

            controlLayer.x = controlLayer.pivotX = 512;
            controlLayer.y = controlLayer.pivotY = 384;
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
            touchQuad.touchable = true;

            controlLayer.alpha = 0;
            controlLayer.scaleX = controlLayer.scaleY = _scale-0.3;
            controlLayer.y = 354;
            btnL.alpha = 0;
            Starling.juggler.tween(controlLayer, Globals.transitionSpeed, {"alpha": 1,
                    "scaleX": _scale,
                    "scaleY": _scale,
                    "y": 384,
                    "transition": "easeInOut"});
            Starling.juggler.tween(btnL, Globals.transitionSpeed, {"alpha": 1,
                    "transition": "easeInOut"});
        }

        public function deinitLevel():void {
            Starling.juggler.removeTweens(controlLayer);
            Starling.juggler.removeTweens(btnL);
            Starling.juggler.tween(controlLayer, Globals.transitionSpeed, {"alpha": 0,
                    "scaleX": _scale-0.3,
                    "scaleY": _scale-0.3,
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
            touchQuad.touchable = false;
        }

        public function update():void {
            behaviorBatch.reset();
            Globals.touchControls ? touchCL.draw() : tradiCL.draw();
        }

        public function set scale(_scale:Number):void{
            this._scale = _scale;
        }
    }
}
