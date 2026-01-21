package UI.Component {
    import starling.animation.DelayedCall;
    import starling.core.Starling;
    import starling.display.Image;
    import starling.display.Sprite;
    import Entity.Node;
    import Entity.EntityContainer;
    import UI.BtnLayer;
    import UI.UIContainer;
    import UI.LayerFactory;

    public class TutorialSprite extends Sprite {
        public static var TYPE_END:int = 0;
        public static var TYPE_L1:int = 1;
        public static var TYPE_L2:int = 2;

        private var arrow:Image;
        private var loop:DelayedCall;
        public var type:int;

        public function TutorialSprite() {
            super();
            arrow = new Image(Root.assets.getTexture("tutorial_arrow"));
            arrow.pivotX = arrow.width;
            arrow.pivotY = arrow.height * 0.5;
            arrow.visible = false;
            arrow.alpha = 0;
            arrow.scaleY = 0.8;
            arrow.scaleX = 0.8;
            arrow.color = 0xFFAAAA;
        }

        public function init(type:int):void {
            this.type = type;
            arrow.visible = true;
            arrow.alpha = 0;
            LayerFactory.addChild(LayerFactory.BTN_ADD, arrow);
            show();
        }

        public function deInit():void {
            LayerFactory.removeChild(LayerFactory.BTN_ADD, arrow);
            Starling.juggler.removeTweens(arrow);
            if (loop)
                Starling.juggler.remove(loop);
            loop = null;
            arrow.visible = false;
            arrow.alpha = 0;
        }

        public function show():void {
            if (!Globals.touchControls)
                return;
            switch (type) {
                case TYPE_L1:
                    showL1();
                    break;
                case TYPE_L2:
                    showL2();
                    break;
                default:
                    deInit();
            }
        }

        private function showL1():void {
            var x:Number = NaN;
            var y:Number = NaN;
            var nodeArray:Vector.<Node> = EntityContainer.nodes;
            arrow.rotation = -Math.PI / 2;
            arrow.x = nodeArray[0].nodeData.x;
            arrow.y = nodeArray[0].nodeData.y + 60;
            Starling.juggler.tween(arrow, 1, {"alpha": 0.8,
                    "y": nodeArray[0].nodeData.y + 30,
                    "delay": 1,
                    "transition": "easeOut"});
            Starling.juggler.tween(arrow, 2, {"x": nodeArray[1].nodeData.x,
                    "y": nodeArray[1].nodeData.y + 10,
                    "delay": 2,
                    "transition": "easeInOut"});
            Starling.juggler.tween(arrow, 1, {"y": nodeArray[1].nodeData.y + 40,
                    "alpha": 0,
                    "delay": 4,
                    "transition": "easeIn"});
            loop = Starling.juggler.delayCall(show, 6);
        }

        private function showL2():void {
            var x:Number = NaN;
            var y:Number = NaN;
            switch (Globals.fleetSliderPosition) {
                case 0:
                    arrow.rotation = Math.PI;
                    x = UIContainer.fleetSlider.x + 50;
                    y = 384 - UIContainer.fleetSlider.box_y;
                    arrow.x = x + 20;
                    arrow.y = y;
                    Starling.juggler.tween(arrow, 1, {"alpha": 0.8,
                            "x": x,
                            "delay": 1,
                            "transition": "easeOut"});
                    Starling.juggler.tween(arrow, 2, {"y": 389,
                            "delay": 2,
                            "transition": "easeInOut"});
                    Starling.juggler.tween(arrow, 1, {"x": x + 20,
                            "alpha": 0,
                            "delay": 4,
                            "transition": "easeIn"});
                    loop = Starling.juggler.delayCall(show, 6);
                    break;
                case 2:
                    arrow.rotation = 0;
                    x = UIContainer.fleetSlider.x;
                    y = 384 - UIContainer.fleetSlider.box_y;
                    arrow.x = x - 20;
                    arrow.y = y;
                    Starling.juggler.tween(arrow, 1, {"alpha": 0.8,
                            "x": x,
                            "delay": 1,
                            "transition": "easeOut"});
                    Starling.juggler.tween(arrow, 2, {"y": 389,
                            "delay": 2,
                            "transition": "easeInOut"});
                    Starling.juggler.tween(arrow, 1, {"x": x - 20,
                            "alpha": 0,
                            "delay": 4,
                            "transition": "easeIn"});
                    loop = Starling.juggler.delayCall(show, 6);
                    break;
                case 1:
                    x = 512 + UIContainer.fleetSlider.box_x;
                    y = UIContainer.fleetSlider.y - 10;
                    arrow.rotation = 1.5707963267948966;
                    arrow.x = x;
                    arrow.y = y - 20;
                    Starling.juggler.tween(arrow, 1, {"alpha": 0.8,
                            "y": y,
                            "delay": 1,
                            "transition": "easeOut"});
                    Starling.juggler.tween(arrow, 2, {"x": 512,
                            "delay": 2,
                            "transition": "easeInOut"});
                    Starling.juggler.tween(arrow, 1, {"y": y - 20,
                            "alpha": 0,
                            "delay": 4,
                            "transition": "easeIn"});
                    loop = Starling.juggler.delayCall(show, 6);
            }
        }
    }
}
