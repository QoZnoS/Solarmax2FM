package ui.layers {
    import scenes.EditorScene;
    import starling.display.Quad;
    import starling.display.Sprite;
    import starling.events.Touch;
    import starling.events.TouchEvent;

    import ui.UIContainer;

    public class EditorCtrlLayer extends Sprite {
        private var convertQuad:Quad; // 转换触点坐标用
        private var touchQuad:Quad;
        private var touches:Vector.<Touch>;
        private var editor:EditorScene;

        private const TOUCH_ON_SWITCH:String = "touch_on_switch";
        private const TOUCH_ON_SWITCH_MOVE:String = "touch_on_switch_move";
        private const TOUCH_ON_CHOOSE:String = "touch_on_choose";
        private const TOUCH_ON_CHOOSE_MOVE:String = "touch_on_choose_move";
        private const TOUCH_NONE:String = "touch_none";

        public function EditorCtrlLayer(_ui:UIContainer) {
            this.editor = _ui.scene.editorScene;
            this.touchQuad = _ui.touchQuad;
            convertQuad = new Quad(1024, 768, 16711680);
            convertQuad.alpha = 0;
            addChild(convertQuad);
        }

        public function init():void {
            touchQuad.addEventListener("touch", on_touch);
            touches = new Vector.<Touch>;
        }

        public function deinit():void {
            touchQuad.removeEventListener("touch", on_touch);
            touches = new Vector.<Touch>;
        }

        private function on_touch(touchEvent:TouchEvent):void {
            touches = touchEvent.getTouches(touchQuad);
        }

        public function draw():void {

        }


    }
}
