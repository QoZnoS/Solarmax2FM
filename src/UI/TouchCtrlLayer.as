package UI {
    import starling.display.Sprite;
    import starling.events.TouchEvent;
    import starling.events.Touch;
    import starling.display.Quad;
    import flash.geom.Point;
    import Game.GameScene;
    import utils.Drawer;
    import Entity.Node;
    import Entity.FXHandler;
    import starling.display.QuadBatch;
    import Entity.Node.NodeStaticLogic;
    import Entity.EntityContainer;

    public class TouchCtrlLayer extends Sprite {
        private var convertQuad:Quad; // 转换触点坐标用
        private var touchQuad:Quad;
        private var displayBatch:QuadBatch;
        private var touches:Vector.<Touch>;
        private var game:GameScene;

        public function TouchCtrlLayer(ui:UIContainer) {
            this.game = ui.scene.gameScene;
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

        public function draw():void {
            const _Color:uint = 0xFFFFFF;
            var _Tx:Number = NaN; // T 表示 touch 触摸点
            var _Ty:Number = NaN;
            var _Block:Point = null;
            var dx:Number = NaN;
            var dy:Number = NaN;
            var distance:Number = NaN;
            var _Angle:Number = NaN;
            var _Nx:Number = NaN; // N 表示 node 天体
            var _Ny:Number = NaN;
            if (!touches)
                return;
            for each (var touch:Touch in touches) {
                if (touch.hoverNode) {
                    Drawer.drawCircle(displayBatch, touch.hoverNode.nodeData.x, touch.hoverNode.nodeData.y, Globals.teamColors[touch.hoverNode.nodeData.team], touch.hoverNode.nodeData.lineDist - 4, touch.hoverNode.nodeData.size * 25 * 2, true, 0.5);
                    if (touch.hoverNode.attackState.attackRate > 0)
                        Drawer.drawDashedCircle(displayBatch, touch.hoverNode.nodeData.x, touch.hoverNode.nodeData.y, Globals.teamColors[touch.hoverNode.nodeData.team], touch.hoverNode.attackState.attackRange, touch.hoverNode.attackState.attackRange - 2, false, 0.5, 1, 0, 256);
                }
                if (!(touch.downNodes && touch.downNodes.length > 0))
                    continue
                for each (var node:Node in touch.downNodes) {
                    Drawer.drawCircle(displayBatch, node.nodeData.x, node.nodeData.y, _Color, node.nodeData.lineDist - 4, node.nodeData.lineDist - 7, false, 0.8);
                    var localPoint:Point = convertQuad.globalToLocal(new Point(touch.globalX, touch.globalY));
                    _Tx = localPoint.x;
                    _Ty = localPoint.y;
                    if (touch.hoverNode) { // 绘制目标天体的定位圈
                        if (!(node.nodeData.isWarp && node.nodeData.team == Globals.playerTeam))
                            _Block = EntityContainer.nodesBlocked(node, touch.hoverNode);
                        _Tx = touch.hoverNode.nodeData.x;
                        _Ty = touch.hoverNode.nodeData.y;
                        if (_Block)
                            Drawer.drawCircle(displayBatch, _Tx, _Ty, 0xFF3333, touch.hoverNode.nodeData.lineDist - 4, touch.hoverNode.nodeData.lineDist - 7, false, 0.8);
                        else
                            Drawer.drawCircle(displayBatch, _Tx, _Ty, _Color, touch.hoverNode.nodeData.lineDist - 4, touch.hoverNode.nodeData.lineDist - 7, false, 0.8);
                    } else if (!(node.nodeData.isWarp && node.nodeData.team == Globals.playerTeam))
                        _Block = lineBlocked(node.nodeData.x, node.nodeData.y, _Tx, _Ty);
                    dx = _Tx - node.nodeData.x;
                    dy = _Ty - node.nodeData.y;
                    distance = Math.sqrt(dx * dx + dy * dy);
                    if (distance > node.nodeData.lineDist - 5) { // 鼠标移出天体定位圈时绘制
                        _Angle = Math.atan2(dy, dx);
                        _Nx = node.nodeData.x + Math.cos(_Angle) * (node.nodeData.lineDist - 5);
                        _Ny = node.nodeData.y + Math.sin(_Angle) * (node.nodeData.lineDist - 5);
                        if (touch.hoverNode) {
                            _Tx -= Math.cos(_Angle) * (touch.hoverNode.nodeData.lineDist - 5);
                            _Ty -= Math.sin(_Angle) * (touch.hoverNode.nodeData.lineDist - 5);
                        }
                        if (_Block) { // 分段绘制鼠标线
                            Drawer.drawLine(displayBatch, _Nx, _Ny, _Block.x, _Block.y, _Color, 3, 0.8);
                            Drawer.drawLine(displayBatch, _Block.x, _Block.y, _Tx, _Ty, 0xFF3333, 3, 0.8);
                        } else
                            Drawer.drawLine(displayBatch, _Nx, _Ny, _Tx, _Ty, _Color, 3, 0.8);
                    }
                }
            }
        }

        private function on_touch(touchEvent:TouchEvent):void {
            if (game.alpha < 0.5)
                return;
            touchHover(touchEvent); // 专用于选中渐变圈
            touchBegan(touchEvent); // 获取鼠标按下时选中的初始天体
            touchMoved(touchEvent); // 获取鼠标移动中选中的初始天体
            touchEnded(touchEvent); // 获取鼠标释放时选中的目标天体，并发送飞船
            touches = touchEvent.getTouches(touchQuad);
        }

        private function touchHover(touchEvent:TouchEvent):void {
            var touchArray:Vector.<Touch> = touchEvent.getTouches(touchQuad, "hover");
            if (!touchArray)
                return;
            for each (var touch:Touch in touchArray) {
                touch.hoverNode = getClosestNode(touch);
            }
        }

        private function touchBegan(touchEvent:TouchEvent):void {
            var touchArray:Vector.<Touch> = touchEvent.getTouches(touchQuad, "began");
            if (!touchArray)
                return;
            for each (var touch:Touch in touchArray) {
                if (!touch.downNodes)
                    touch.downNodes = [];
                touch.downNodes.length = 0;
                var node:Node = getClosestNode(touch);
                if (node && touch.downNodes.indexOf(node) == -1)
                    touch.downNodes.push(node);
                touch.hoverNode = null;
                if (node)
                    touch.hoverNode = node;
            }
        }

        private function touchMoved(touchEvent:TouchEvent):void {
            var touchArray:Vector.<Touch> = touchEvent.getTouches(touchQuad, "moved");
            if (!touchArray)
                return;
            for each (var touch:Touch in touchArray) {
                if (!touch.downNodes)
                    touch.downNodes = [];
                var node:Node = getClosestNode(touch);
                if (node && touch.downNodes.indexOf(node) == -1 && touch.downNodes.length == 0)
                    touch.downNodes.push(node);
                touch.hoverNode = null;
                if (node)
                    touch.hoverNode = node;
            }
        }

        private function touchEnded(touchEvent:TouchEvent):void {
            var node1:Node = null;
            var node2:Node = null;
            var touchArray:Vector.<Touch> = touchEvent.getTouches(touchQuad, "ended");
            if (!touchArray)
                return;
            for each (var touch:Touch in touchArray) {
                if (touch.hoverNode && touch.downNodes.length > 0) {
                    node1 = touch.hoverNode;
                    FXHandler.addFade(node1.nodeData.x, node1.nodeData.y, node1.nodeData.size, 0xFFFFFF, 1);
                    for each (node2 in touch.downNodes) {
                        if (node2 == node1 || !node2.nodeLinks[Globals.playerTeam].includes(node1))
                            continue;
                        NodeStaticLogic.sendShips(node2, Globals.playerTeam, node1);
                        FXHandler.addFade(node2.nodeData.x, node2.nodeData.y, node2.nodeData.size, 0xFFFFFF, 0);
                    }
                }
                touch.hoverNode = null;
                if (touch.downNodes)
                    touch.downNodes.length = 0;
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

        private function lineBlocked(x1:Number, y1:Number, x2:Number, y2:Number):Point {
            var intersection:Point = null;
            var bar1:Point = null;
            var bar2:Point = null;
            for each (var bar:Array in game.barrierLines) {
                bar1 = bar[0];
                bar2 = bar[1];
                intersection = EntityContainer.getIntersection(x1, y1, x2, y2, bar1.x, bar1.y, bar2.x, bar2.y);
                if (intersection)
                    return intersection;
            }
            return null;
        }
        //#endregion
    }
}
