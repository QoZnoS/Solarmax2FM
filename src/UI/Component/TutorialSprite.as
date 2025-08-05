package UI.Component {
    import starling.animation.DelayedCall;
    import starling.core.Starling;
    import starling.display.Image;
    import starling.display.Sprite;
    import Game.GameScene;
    import Entity.GameEntity;
    import Entity.Node;
    import Entity.EntityContainer;

    public class TutorialSprite extends Sprite {
        public static var TYPE_L1:int = 0;
        public static var TYPE_L2:int = 1;

        private var game:GameScene;
        private var arrow:Image;
        private var loop:DelayedCall;
        private var layer:Sprite;
        private var type:int;

        public function TutorialSprite() {
            super();
            arrow = new Image(Root.assets.getTexture("tutorial_arrow"));
            arrow.pivotX = arrow.width;
            arrow.pivotY = arrow.height * 0.5;
            arrow.visible = false;
            arrow.alpha = 0;
            arrow.blendMode = "add";
            arrow.scaleY = 0.8;
            arrow.scaleX = 0.8;
            arrow.color = 16755370;
        }

        public function init(_game:GameScene, type:int):void {
            this.game = _game;
            this.layer = game.ui.btnL;
            this.type = type;
            arrow.visible = true;
            arrow.alpha = 0;
            layer.addChild(arrow);
            show();
        }

        public function deInit():void {
            if (!game)
                return;
            layer.removeChild(arrow);
            Starling.juggler.removeTweens(arrow);
            if (loop)
                Starling.juggler.remove(loop);
            loop = null;
            arrow.visible = false;
            arrow.alpha = 0;
        }

        public function show():void {
            var _x:Number = NaN;
            var _y:Number = NaN;
            var _NodeArray:Vector.<Node> = EntityContainer.nodes;
            if (game.triggers[0])
                return;
            if (!Globals.touchControls)
                return;
            switch (type) {
                case TYPE_L1:
                    arrow.rotation = -1.5707963267948966;
                    arrow.x = _NodeArray[0].nodeData.x;
                    arrow.y = _NodeArray[0].nodeData.y + 60;
                    Starling.juggler.tween(arrow, 1, {"alpha": 0.8,
                            "y": _NodeArray[0].nodeData.y + 30,
                            "delay": 1,
                            "transition": "easeOut"});
                    Starling.juggler.tween(arrow, 2, {"x": _NodeArray[1].nodeData.x,
                            "y": _NodeArray[1].nodeData.y + 10,
                            "delay": 2,
                            "transition": "easeInOut"});
                    Starling.juggler.tween(arrow, 1, {"y": _NodeArray[1].nodeData.y + 40,
                            "alpha": 0,
                            "delay": 4,
                            "transition": "easeIn"});
                    loop = Starling.juggler.delayCall(show, 6);
                    break;
                case TYPE_L2:
                    switch (Globals.fleetSliderPosition) {
                        case 0:
                            arrow.rotation = Math.PI;
                            _x = game.ui.btnL.fleetSlider.x + 50;
                            _y = 384 - game.ui.btnL.fleetSlider.box_y;
                            arrow.x = _x + 20;
                            arrow.y = _y;
                            Starling.juggler.tween(arrow, 1, {"alpha": 0.8,
                                    "x": _x,
                                    "delay": 1,
                                    "transition": "easeOut"});
                            Starling.juggler.tween(arrow, 2, {"y": 389,
                                    "delay": 2,
                                    "transition": "easeInOut"});
                            Starling.juggler.tween(arrow, 1, {"x": _x + 20,
                                    "alpha": 0,
                                    "delay": 4,
                                    "transition": "easeIn"});
                            loop = Starling.juggler.delayCall(show, 6);
                            break;
                        case 2:
                            arrow.rotation = 0;
                            _x = game.ui.btnL.fleetSlider.x;
                            _y = 384 - game.ui.btnL.fleetSlider.box_y;
                            arrow.x = _x - 20;
                            arrow.y = _y;
                            Starling.juggler.tween(arrow, 1, {"alpha": 0.8,
                                    "x": _x,
                                    "delay": 1,
                                    "transition": "easeOut"});
                            Starling.juggler.tween(arrow, 2, {"y": 389,
                                    "delay": 2,
                                    "transition": "easeInOut"});
                            Starling.juggler.tween(arrow, 1, {"x": _x - 20,
                                    "alpha": 0,
                                    "delay": 4,
                                    "transition": "easeIn"});
                            loop = Starling.juggler.delayCall(show, 6);
                            break;
                        case 1:
                            _x = 512 + game.ui.btnL.fleetSlider.box_x;
                            _y = game.ui.btnL.fleetSlider.y - 10;
                            arrow.rotation = 1.5707963267948966;
                            arrow.x = _x;
                            arrow.y = _y - 20;
                            Starling.juggler.tween(arrow, 1, {"alpha": 0.8,
                                    "y": _y,
                                    "delay": 1,
                                    "transition": "easeOut"});
                            Starling.juggler.tween(arrow, 2, {"x": 512,
                                    "delay": 2,
                                    "transition": "easeInOut"});
                            Starling.juggler.tween(arrow, 1, {"y": _y - 20,
                                    "alpha": 0,
                                    "delay": 4,
                                    "transition": "easeIn"});
                            loop = Starling.juggler.delayCall(show, 6);
                    }
            }
        }
     }
}
