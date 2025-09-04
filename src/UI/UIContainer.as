package UI {
    import starling.display.Sprite;
    import starling.core.Starling;
    import starling.display.QuadBatch;
    import starling.display.Quad;

    public class UIContainer extends Sprite {
        public var gameContainer:Sprite;

        private var entityL:EntityLayer;
        private var controlL:Sprite;
        private var behaviorB:QuadBatch;
        private var touchCL:TouchCtrlLayer;
        private var tradiCL:TraditionalCtrlLayer;

        public var btnL:BtnLayer;
        public var touchQuad:Quad;

        public var scene:SceneController;

        private static var ui:UIContainer;
        private var _scale:Number

        public function UIContainer(_scene:SceneController) {
            this.scene = _scene;
            ui = this;
            gameContainer = new Sprite();
            touchQuad = new Quad(1024, 768, 16711680);
            entityL = new EntityLayer();
            controlL = new Sprite();
            behaviorB = new QuadBatch();
            touchCL = new TouchCtrlLayer(this);
            tradiCL = new TraditionalCtrlLayer(this);
            btnL = new BtnLayer(this);

            gameContainer.addChild(entityL);
            gameContainer.addChild(controlL);
            controlL.addChild(behaviorB);
            controlL.addChild(touchCL);
            controlL.addChild(tradiCL);
            addChild(gameContainer)
            addChild(touchQuad);
            addChild(btnL);

            touchCL.visible = tradiCL.visible = touchQuad.touchable = gameContainer.touchable = false;
            touchQuad.alpha = 0;

            gameContainer.x = gameContainer.pivotX = 512;
            gameContainer.y = gameContainer.pivotY = 384;
        }

        public function initLevel():void {
            if (Globals.touchControls) {
                touchCL.visible = true;
                touchCL.init();
            } else {
                tradiCL.visible = true;
                tradiCL.init();
            }
            btnL.initLevel();
            entityL.init();
            touchQuad.touchable = true;

            gameContainer.alpha = 0;
            gameContainer.scaleX = gameContainer.scaleY = _scale-0.3;
            gameContainer.y = 354;
            btnL.alpha = 0;
            Starling.juggler.tween(gameContainer, Globals.transitionSpeed, {"alpha": 1,
                    "scaleX": _scale,
                    "scaleY": _scale,
                    "y": 384,
                    "transition": "easeInOut"});
            Starling.juggler.tween(btnL, Globals.transitionSpeed, {"alpha": 1,
                    "transition": "easeInOut"});
        }

        public function deinitLevel():void {
            Starling.juggler.removeTweens(gameContainer);
            Starling.juggler.removeTweens(btnL);
            Starling.juggler.tween(gameContainer, Globals.transitionSpeed, {"alpha": 0,
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
            entityL.reset();
            touchQuad.touchable = false;
        }

        public function update():void {
            behaviorB.reset();
            entityL.reset();
            Globals.touchControls ? touchCL.draw() : tradiCL.draw();
        }

        public function set scale(_scale:Number):void{
            this._scale = _scale;
        }

        public static function get behaviorBatch():QuadBatch{
            return ui.behaviorB;
        }

        public static function get entityLayer():EntityLayer{
            return ui.entityL;
        }
    }
}
