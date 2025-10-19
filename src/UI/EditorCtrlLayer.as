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
            touchQuad.addEventListener("touch", on_touch); // 按操作方式添加事件监听器
            touches = new Vector.<Touch>;
        }

        public function deinit():void {
            touchQuad.removeEventListener("touch", on_touch);
            touches = new Vector.<Touch>;
        }

        private function on_touch(touchEvent:TouchEvent):void {
            // touchHover(touchEvent);
            // touchBegan(touchEvent);
            // touchMoved(touchEvent);
            // touchEnded(touchEvent);
            touches = touchEvent.getTouches(touchQuad);
        }



        public function draw():void {
            for each (var touch:Touch in touches) {
                if (touch.hoverNode) {
                    Drawer.drawCircle(displayBatch, touch.hoverNode.nodeData.x, touch.hoverNode.nodeData.y, Globals.teamColors[touch.hoverNode.nodeData.team], touch.hoverNode.nodeData.lineDist - 4, touch.hoverNode.nodeData.size * 25 * 2, true, 0.5);
                    if (touch.hoverNode.attackState.attackRate > 0)
                        Drawer.drawDashedCircle(displayBatch, touch.hoverNode.nodeData.x, touch.hoverNode.nodeData.y, Globals.teamColors[touch.hoverNode.nodeData.team], touch.hoverNode.attackState.attackRange, touch.hoverNode.attackState.attackRange - 2, false, 0.5, 1, 0, 256);
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
