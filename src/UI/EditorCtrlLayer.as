package UI {
    import starling.display.Sprite;
    import starling.display.Quad;
    import starling.display.QuadBatch;
    import starling.events.Touch;
    import Game.EditorScene;
    import starling.events.TouchEvent;
    import Entity.EntityContainer;
    import Entity.Node;
    import flash.geom.Point;
    import utils.Drawer;
    import starling.core.Starling;
    import starling.animation.Tween;
    import starling.animation.Transitions;

    public class EditorCtrlLayer extends Sprite {

        private var convertQuad:Quad; // 转换触点坐标用
        private var touchQuad:Quad;
        private var displayBatch:QuadBatch;
        private var touches:Vector.<Touch>;
        private var editor:EditorScene;

        public function EditorCtrlLayer(ui:UIContainer) {
            this.editor = ui.scene.editorScene;
            this.displayBatch = UIContainer.behaviorBatch;
            this.touchQuad = ui.touchQuad;
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
            touchHover(touchEvent);
            touchBegan(touchEvent);
            touchMoved(touchEvent);
            touchEnded(touchEvent);
            touches = touchEvent.getTouches(touchQuad);
        }

        private function touchHover(touchEvent:TouchEvent):void {
            var touchArray:Vector.<Touch> = touchEvent.getTouches(touchQuad, "hover");
            if (!touchArray)
                return;
            for each (var touch:Touch in touchArray)
                touch.hoverNode = getClosestNode(touch);
        }

        private function touchBegan(touchEvent:TouchEvent):void {
            var touchArray:Vector.<Touch> = touchEvent.getTouches(touchQuad, "began");
            if (!touchArray)
                return;
            for each (var touch:Touch in touchArray) {
                var node:Node = getClosestNode(touch);
                if (node && !touch.downNode)
                    touch.downNode = node;
                touch.hoverNode = null;
                if (!node)
                    continue;
                touch.hoverNode = node;
                Starling.juggler.removeTweens(node.moveState);
                var pressTween:Tween = new Tween(node.moveState, 0.1, Transitions.EASE_OUT);
                pressTween.animate("scale", 0.95);
                Starling.juggler.add(pressTween);
            }
        }

        private function touchMoved(touchEvent:TouchEvent):void {
            var touchArray:Vector.<Touch> = touchEvent.getTouches(touchQuad, "moved");
            if (!touchArray)
                return;
            for each (var touch:Touch in touchArray) {
                if (!touch.downNode)
                    continue;

            }
        }

        private function touchEnded(touchEvent:TouchEvent):void {
            var touchArray:Vector.<Touch> = touchEvent.getTouches(touchQuad, "ended");
            if (!touchArray)
                return;
            for each (var touch:Touch in touchArray) {
                if (!touch.downNode)
                    continue;
                var node:Node = touch.downNode;
                Starling.juggler.removeTweens(node.moveState);
                var releaseTween:Tween = new Tween(node.moveState, 0.15, Transitions.EASE_OUT);
                releaseTween.animate("scale", 1);
                Starling.juggler.add(releaseTween);
            }
        }


        public function draw():void {
            const color:uint = 0xFFFFFF;
            var node:Node;
            for each (var touch:Touch in touches) {
                if (touch.hoverNode) {
                    Drawer.drawCircle(displayBatch, touch.hoverNode.nodeData.x, touch.hoverNode.nodeData.y, Globals.teamColors[touch.hoverNode.nodeData.team], touch.hoverNode.nodeData.lineDist - 4, touch.hoverNode.nodeData.size * 25 * 2, true, 0.5);
                    if (touch.hoverNode.attackState.attackRate > 0)
                        Drawer.drawDashedCircle(displayBatch, touch.hoverNode.nodeData.x, touch.hoverNode.nodeData.y, Globals.teamColors[touch.hoverNode.nodeData.team], touch.hoverNode.attackState.attackRange, touch.hoverNode.attackState.attackRange - 2, false, 0.5, 1, 0, 256);
                }
                if (touch.downNode) {
                    node = touch.downNode;
                    Drawer.drawCircle(displayBatch, node.nodeData.x, node.nodeData.y, color, node.nodeData.lineDist - 4, node.nodeData.lineDist - 7, false, 0.8);
                }

            }
        }

        //#region 计算工具
        private function getClosestNode(touch:Touch):Node {
            var localPoint:Point = convertQuad.globalToLocal(new Point(touch.globalX, touch.globalY));
            var closestNode:Node = null;
            var dx:Number = NaN;
            var dy:Number = NaN;
            var distance:Number = NaN;
            var lineDist:Number = NaN;
            var closestDist:Number = 200;
            for each (var node:Node in EntityContainer.nodes) {
                if (node.nodeData.isUntouchable)
                    continue;
                dx = node.nodeData.x - localPoint.x;
                dy = node.nodeData.y - localPoint.y;
                distance = Math.sqrt(dx * dx + dy * dy);
                lineDist = node.nodeData.lineDist;
                if (distance < lineDist && distance < closestDist) {
                    closestDist = distance;
                    closestNode = node;
                }
            }
            return closestNode;
        }
        //#endregion


    }
}
