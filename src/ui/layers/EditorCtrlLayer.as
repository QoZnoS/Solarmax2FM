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

        public function EditorCtrlLayer(_ui:UIContainer) {
            this.editor = _ui.scene.editorScene;
            this.touchQuad = _ui.touchQuad;
            convertQuad = new Quad(1024, 768, 0xFF0000);
            convertQuad.alpha = 0;
            addChild(convertQuad);
        }

        public function init():void {
            touchQuad.addEventListener("touch", on_touch);
        }

        public function deinit():void {
            touchQuad.removeEventListener("touch", on_touch);
        }

        private function on_touch(touchEvent:TouchEvent):void {
            touches = touchEvent.getTouches(touchQuad);
            if (touches.length == 0)
                return;
            Debug.updateTouch(touches[0].globalX, touches[0].globalY);
        }

        public function draw():void {

        }


    }
}
