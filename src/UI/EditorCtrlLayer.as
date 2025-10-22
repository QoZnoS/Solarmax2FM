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

        private const TOUCH_ON_SWITCH:String = "touch_on_switch";
        private const TOUCH_ON_SWITCH_MOVE:String = "touch_on_switch_move";
        private const TOUCH_ON_CHOOSE:String = "touch_on_choose";
        private const TOUCH_ON_CHOOSE_MOVE:String = "touch_on_choose_move";
        private const TOUCH_NONE:String = "touch_none";

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
            var localPoint:Point;
            if (!touchArray)
                return;
            for each (var touch:Touch in touchArray) {
                touch.startPoint = touch.getLocation(touchQuad);
                // 选择器状态
                if (editor.focusNode) {
                    var checkResult:Array = checkInSwitchArea(touch);
                    if (checkResult[0] != -1) {
                        touch.state = TOUCH_ON_SWITCH;
                        editor.switchInRows = (checkResult[0] == 0);
                        continue;
                    }
                }

                if (touch.hoverNode) {
                    touch.downNode = touch.hoverNode;
                    touch.state = TOUCH_ON_CHOOSE;
                } else {
                    touch.state = TOUCH_NONE;
                }

                if (touch.hoverNode) {
                    Starling.juggler.removeTweens(touch.hoverNode.moveState);
                    var pressTween:Tween = new Tween(touch.hoverNode.moveState, 0.2, Transitions.EASE_OUT);
                    pressTween.animate("scale", 0.8);
                    Starling.juggler.add(pressTween);
                }
            }
        }

        private function touchMoved(touchEvent:TouchEvent):void {
            var touchArray:Vector.<Touch> = touchEvent.getTouches(touchQuad, "moved");
            var localPoint:Point;
            if (!touchArray)
                return;
            for each (var touch:Touch in touchArray) {
                if (touch.state == TOUCH_ON_SWITCH) {
                    var checkResult:Array = checkInSwitchArea(touch);
                    editor.switchDistance = checkResult[1];
                } else if (touch.state == TOUCH_ON_CHOOSE) {
                    // 移动天体
                }

            }
        }

        private function touchEnded(touchEvent:TouchEvent):void {
            var touchArray:Vector.<Touch> = touchEvent.getTouches(touchQuad, "ended");
            var node:Node;
            var releaseTween:Tween;
            if (!touchArray)
                return;
            for each (var touch:Touch in touchArray) {
                if (touch.state == TOUCH_ON_CHOOSE) {
                    node = touch.downNode;
                    editor.focusNode = node;
                    Starling.juggler.removeTweens(node.moveState);
                    releaseTween = new Tween(node.moveState, 0.2, Transitions.EASE_OUT);
                    releaseTween.animate("scale", 1.2);
                    Starling.juggler.add(releaseTween);
                    touch.downNode = null;
                    continue;
                }

                if (touch.state == TOUCH_NONE) {
                    if (editor.focusNode) {
                        Starling.juggler.removeTweens(editor.focusNode.moveState);
                        releaseTween = new Tween(editor.focusNode.moveState, 0.2, Transitions.EASE_OUT);
                        releaseTween.animate("scale", 1);
                        Starling.juggler.add(releaseTween);
                        editor.focusNode = null;
                        continue;
                    }
                }

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

        /**
         * <p>如果触点在焦点的选择器范围内，返回轴向类型和对应距离：
         * <p>[0, dist]
         * <p>[1, dist]
         * <p>[-1, dist]
         */
        private function checkInSwitchArea(touch:Touch):Array {
            var localPoint:Point = convertQuad.globalToLocal(new Point(touch.globalX, touch.globalY));
            if (!editor.focusNode)
                return [-1, NaN];
            var fx:Number = editor.focusNode.nodeData.x;
            var fy:Number = editor.focusNode.nodeData.y;
            var dx:Number = Math.abs(localPoint.x - fx);
            var dy:Number = Math.abs(localPoint.y - fy);
            var lineDist:Number = editor.focusNode.nodeData.lineDist;
            var moveDist:Number = (dx > dy ? localPoint.x - touch.startPoint.x : localPoint.y - touch.startPoint.y);
            if (dx < lineDist || dy < lineDist) {
                if (dx > dy)
                    return [0, moveDist];
                else
                    return [1, moveDist];
            }
            return [-1, moveDist];
        }
        //#endregion


    }
}
