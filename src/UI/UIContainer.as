package UI {
    import starling.display.Sprite;
    import starling.core.Starling;
    import starling.display.QuadBatch;
    import starling.display.Quad;

    public class UIContainer extends Sprite {
        private var _gameContainer:Sprite;
        private var _entityL:EntityLayer;
        private var _controlL:Sprite;
        private var _behaviorB:QuadBatch;
        private var _touchCL:TouchCtrlLayer;
        private var _tradiCL:TraditionalCtrlLayer;
        private var _editorCL:EditorCtrlLayer;
        private var _btnL:BtnLayer;

        public var touchQuad:Quad;

        public var scene:SceneController;

        private static var _ui:UIContainer;
        private var _scale:Number

        public function UIContainer(scene:SceneController) {
            this.scene = scene;
            _ui = this;
            _gameContainer = new Sprite();
            touchQuad = new Quad(1024, 768, 16711680);
            _entityL = new EntityLayer();
            _controlL = new Sprite();
            _behaviorB = new QuadBatch();
            _touchCL = new TouchCtrlLayer(this);
            _tradiCL = new TraditionalCtrlLayer(this);
            _editorCL = new EditorCtrlLayer(this);
            _btnL = new BtnLayer(this);

            _gameContainer.addChild(_entityL);
            _gameContainer.addChild(_controlL);
            _controlL.addChild(_behaviorB);
            _controlL.addChild(_touchCL);
            _controlL.addChild(_tradiCL);
            _controlL.addChild(_editorCL);
            addChild(_gameContainer)
            addChild(touchQuad);
            addChild(_btnL);

            _touchCL.visible = _tradiCL.visible = _editorCL.visible = touchQuad.touchable = _gameContainer.touchable = false;
            touchQuad.alpha = 0;

            _gameContainer.x = _gameContainer.pivotX = 512;
            _gameContainer.y = _gameContainer.pivotY = 384;
        }

        public function initLevel(scale:Number = 1):void {
            if (scale)
                _scale = scale;
            else
                _scale = 1;
            if (Globals.touchControls) {
                _touchCL.visible = true;
                _touchCL.init();
            } else {
                _tradiCL.visible = true;
                _tradiCL.init();
            }
            _btnL.initLevel();
            _entityL.init();
            touchQuad.touchable = true;

            _gameContainer.alpha = 0;
            _gameContainer.scaleX = _gameContainer.scaleY = _scale * 0.7;
            _gameContainer.y = 354;
            _btnL.alpha = 0;
            Starling.juggler.tween(_gameContainer, Globals.transitionSpeed, {"alpha": 1,
                    "scaleX": _scale,
                    "scaleY": _scale,
                    "y": 384,
                    "transition": "easeInOut"});
            Starling.juggler.tween(_btnL, Globals.transitionSpeed, {"alpha": 1,
                    "transition": "easeInOut"});
        }

        public function deinitLevel():void {
            if (Globals.touchControls) {
                _touchCL.visible = false;
                _touchCL.deinit();
            } else {
                _tradiCL.visible = false;
                _tradiCL.deinit();
            }
            touchQuad.touchable = false;

            Starling.juggler.removeTweens(_gameContainer);
            Starling.juggler.removeTweens(_btnL);
            Starling.juggler.tween(_gameContainer, Globals.transitionSpeed, {"alpha": 0,
                    "scaleX": _scale * 0.7,
                    "scaleY": _scale * 0.7,
                    "y": 354,
                    "transition": "easeInOut"});
            Starling.juggler.tween(_btnL, Globals.transitionSpeed, {"alpha": 0,
                    "onComplete": function():void {
                        _btnL.deinitLevel();
                        _entityL.deinit();
                    },
                    "transition": "easeInOut"});
        }

        public function restartLevel():void {
            Starling.juggler.removeTweens(_gameContainer);
            Starling.juggler.tween(_gameContainer, Globals.transitionSpeed / 5, {"alpha": 0,
                    "scaleX": _scale - 0.15,
                    "scaleY": _scale - 0.15,
                    "y": 354,
                    "transition": "easeIn"});
            Starling.juggler.tween(_gameContainer, Globals.transitionSpeed / 5 * 4, {"delay": Globals.transitionSpeed / 5,
                    "alpha": 1,
                    "scaleX": _scale,
                    "scaleY": _scale,
                    "y": 384,
                    "transition": "easeInOut"});
            _entityL.reset();
        }

        public function initEditor():void {
            _editorCL.visible = true;
            _editorCL.init();
            _entityL.init();
            _btnL.initEditor();
            touchQuad.touchable = true;

            _gameContainer.alpha = 0;
            _gameContainer.scaleX = _gameContainer.scaleY = _scale * 0.7;
            _gameContainer.y = 354;
            _btnL.alpha = 0;
            Starling.juggler.tween(_gameContainer, Globals.transitionSpeed, {"alpha": 1,
                    "scaleX": _scale,
                    "scaleY": _scale,
                    "y": 384,
                    "transition": "easeInOut"});
            Starling.juggler.tween(_btnL, Globals.transitionSpeed, {"alpha": 1,
                    "transition": "easeInOut"});
        }

        public function deinitEditor():void {
            _editorCL.visible = false;
            _editorCL.deinit();
            touchQuad.touchable = false;

            Starling.juggler.removeTweens(_gameContainer);
            Starling.juggler.removeTweens(_btnL);
            Starling.juggler.tween(_gameContainer, Globals.transitionSpeed, {"alpha": 0,
                    "scaleX": _scale * 0.7,
                    "scaleY": _scale * 0.7,
                    "y": 354,
                    "transition": "easeInOut"});
            Starling.juggler.tween(_btnL, Globals.transitionSpeed, {"alpha": 0,
                    "onComplete": function():void {
                        _btnL.deinitEditor();
                        _entityL.deinit();
                    },
                    "transition": "easeInOut"});
        }

        public function update():void {
            _behaviorB.reset();
            _entityL.reset();
            Globals.touchControls ? _touchCL.draw() : _tradiCL.draw();
            if (_editorCL.visible)
                _editorCL.draw();
        }

        public function set scale(scale:Number):void {
            this._scale = scale;
        }

        public static function get scale():Number {
            return _ui._scale;
        }

        public static function get behaviorBatch():QuadBatch {
            return _ui._behaviorB;
        }

        public static function get entityLayer():EntityLayer {
            return _ui._entityL;
        }

        public static function get btnLayer():BtnLayer {
            return _ui._btnL;
        }

        public static function get gameContainer():Sprite {
            return _ui._gameContainer;
        }

        public static function invisibleMode():void {
            _ui._entityL.invisibleMode();
            Starling.juggler.tween(_ui._btnL, 5, {"alpha": 0,
                    "delay": 120});
        }

        public static function set touchable(value:Boolean):void {
            _ui.touchable = value;
        }
    }
}
