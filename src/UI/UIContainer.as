package UI {
    import starling.display.Sprite;

    public class UIContainer extends Sprite {

        public var touchCL:TouchCtrlLayer;
        public var traditionalCL:TraditionalCtrlLayer;

        public var scene:SceneController

        public function UIContainer(_scene:SceneController) {
            this.scene = _scene;
            touchCL = new TouchCtrlLayer(scene.gameScene);
            traditionalCL = new TraditionalCtrlLayer(scene.gameScene);

            addChild(touchCL);
            addChild(traditionalCL);

            touchCL.visible = traditionalCL.visible = false;
        }

        public function initLevel():void {
            if (Globals.touchControls) {
                touchCL.visible = true;
                touchCL.init();
            }else{
                traditionalCL.visible = true;
                traditionalCL.init();
            }
        }

        public function deinitLevel():void {
            if (Globals.touchControls) {
                touchCL.visible = false;
                touchCL.deinit();
            }else{
                traditionalCL.visible = false;
                traditionalCL.deinit();
            }
        }

        public function update():void{
            Globals.touchControls? touchCL.draw():traditionalCL.draw();
        }
    }
}
