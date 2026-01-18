package UI {
    import starling.display.Sprite;
    import flash.events.MouseEvent;
    import starling.core.Starling;
    import flash.geom.Point;
    import Game.GameScene;
    import utils.Drawer;
    import starling.display.Quad;
    import Entity.Node;
    import Entity.FXHandler;
    import starling.display.QuadBatch;
    import Entity.Node.NodeStaticLogic;
    import Entity.EntityContainer;

    public class TraditionalCtrlLayer extends Sprite {

        private var selectedNodes:Array;
        private var downx:Number;
        private var downy:Number;
        private var dragx:Number;
        private var dragy:Number;
        private var mouseDown:Boolean;
        private var dragging:Boolean;
        private var rightDown:Boolean;
        private var game:GameScene;
        private var displayBatch:QuadBatch;
        private var mouseBatch:QuadBatch;
        private var dragQuad:Quad;
        private var dragLine:Quad;
        private var convertQuad:Quad;

        public function TraditionalCtrlLayer(ui:UIContainer) {
            this.game = ui.scene.gameScene;
            this.displayBatch = UIContainer.behaviorBatch;
            dragQuad = new Quad(10, 10, Globals.teamColors[1]);
            dragLine = new Quad(2, 2, Globals.teamColors[1]);
            selectedNodes = [];
            mouseBatch = new QuadBatch();
            addChild(mouseBatch);
            convertQuad = new Quad(1024, 768, 16711680);
            convertQuad.alpha = 0;
            addChild(convertQuad);
        }


        public function init():void {
            Starling.current.nativeStage.addEventListener("mouseDown", on_mouseDown);
            Starling.current.nativeStage.addEventListener("mouseMove", on_mouseMove);
            Starling.current.nativeStage.addEventListener("mouseUp", on_mouseUp);
            Starling.current.nativeStage.addEventListener("rightMouseDown", on_rightDown);
            Starling.current.nativeStage.addEventListener("rightMouseUp", on_rightUp);
        }

        public function deinit():void {
            Starling.current.nativeStage.removeEventListener("mouseDown", on_mouseDown);
            Starling.current.nativeStage.removeEventListener("mouseMove", on_mouseMove);
            Starling.current.nativeStage.removeEventListener("mouseUp", on_mouseUp);
            Starling.current.nativeStage.removeEventListener("rightMouseDown", on_rightDown);
            Starling.current.nativeStage.removeEventListener("rightMouseUp", on_rightUp);
        }

        public function draw():void {
            mouseBatch.reset();
            var quadtypeX:Number = NaN;
            var quadtypeY:Number = NaN;
            var i:int = 0;
            var node1:Node = null;
            var mouseX:Number = NaN;
            var mouseY:Number = NaN;
            var node2:Node = null;
            var block:Point = null;
            var x:Number = NaN;
            var y:Number = NaN;
            var dx:Number = NaN;
            var dy:Number = NaN;
            var angle:Number = NaN;
            var lx:Number = NaN;
            var ly:Number = NaN;
            if (mouseDown && dragging) {
                dragQuad.x = downx;
                dragQuad.y = downy;
                dragQuad.width = dragx - downx;
                dragQuad.height = dragy - downy;
                dragQuad.alpha = 0.2;
                mouseBatch.addQuad(dragQuad);
                quadtypeX = dragx - downx > 0 ? 1 : -1;
                quadtypeY = dragy - downy > 0 ? 1 : -1;
                dragLine.alpha = 0.5;
                dragLine.width = (dragQuad.width + 2) * quadtypeX;
                dragLine.height = quadtypeY;
                dragLine.x = downx - quadtypeX;
                dragLine.y = downy - quadtypeY;
                mouseBatch.addQuad(dragLine);
                dragLine.x = downx - quadtypeX;
                dragLine.y = downy + dragQuad.height * quadtypeY;
                mouseBatch.addQuad(dragLine);
                dragLine.width = quadtypeX;
                dragLine.height = dragQuad.height * quadtypeY;
                dragLine.x = downx - quadtypeX;
                dragLine.y = downy;
                mouseBatch.addQuad(dragLine);
                dragLine.x = downx + dragQuad.width * quadtypeX;
                dragLine.y = downy;
                mouseBatch.addQuad(dragLine);
                if (dragQuad.color != 0x000000)
                    mouseBatch.blendMode = "add";
                for each (node1 in EntityContainer.nodes) {
                    if (node1.ships[1].length == 0 && node1.nodeData.team != 1)
                        continue;
                    if (selectedNodes.indexOf(node1) != -1)
                        continue;
                    if (quadtypeX > 0 && quadtypeY > 0) {
                        if (node1.nodeData.x > downx && node1.nodeData.x < dragx && node1.nodeData.y > downy && node1.nodeData.y < dragy)
                            selectedNodes.push(node1);
                    } else if (quadtypeX > 0 && quadtypeY < 0) {
                        if (node1.nodeData.x > downx && node1.nodeData.x < dragx && node1.nodeData.y > dragy && node1.nodeData.y < downy)
                            selectedNodes.push(node1);
                    } else if (quadtypeX < 0 && quadtypeY > 0) {
                        if (node1.nodeData.x > dragx && node1.nodeData.x < downx && node1.nodeData.y > downy && node1.nodeData.y < dragy)
                            selectedNodes.push(node1);
                    } else if (quadtypeX < 0 && quadtypeY < 0) {
                        if (node1.nodeData.x > dragx && node1.nodeData.x < downx && node1.nodeData.y > dragy && node1.nodeData.y < downy)
                            selectedNodes.push(node1);
                    }
                }
            } else {
                mouseX = (Starling.current.nativeStage.mouseX - Starling.current.viewPort.x) / Starling.contentScaleFactor;
                mouseY = (Starling.current.nativeStage.mouseY - Starling.current.viewPort.y) / Starling.contentScaleFactor;
                node2 = getClosestNode(mouseX, mouseY);
                if (node2) {
                    Drawer.drawCircle(displayBatch, node2.nodeData.x, node2.nodeData.y, Globals.teamColors[node2.nodeData.team], node2.nodeData.lineDist - 4, node2.nodeData.size * 25 * 2, true, 0.5);
                    if (node2.attackState.attackRate > 0 && node2.attackState.attackRange > 0)
                        Drawer.drawDashedCircle(displayBatch, node2.nodeData.x, node2.nodeData.y, Globals.teamColors[node2.nodeData.team], node2.attackState.attackRange, node2.attackState.attackRange - 2, false, 0.5, 1, 0, 256);
                    if (rightDown && selectedNodes.length > 0) {
                        for each (node1 in selectedNodes) {
                            if (!node1.nodeLinks[Globals.playerTeam].includes(node2))
                                block = EntityContainer.nodesBlocked(node1, node2);
                            x = node2.nodeData.x;
                            y = node2.nodeData.y;
                            dx = x - node1.nodeData.x;
                            dy = y - node1.nodeData.y;
                            if (Math.sqrt(dx * dx + dy * dy) > node1.nodeData.lineDist - 5) {
                                angle = Math.atan2(dy, dx);
                                lx = node1.nodeData.x + Math.cos(angle) * (node1.nodeData.lineDist - 5);
                                ly = node1.nodeData.y + Math.sin(angle) * (node1.nodeData.lineDist - 5);
                                x -= Math.cos(angle) * (node2.nodeData.lineDist - 5);
                                y -= Math.sin(angle) * (node2.nodeData.lineDist - 5);
                                if (block) {
                                    Drawer.drawLine(displayBatch, lx, ly, block.x, block.y, 0xFFFFFF, 3, 0.8);
                                    Drawer.drawLine(displayBatch, block.x, block.y, x, y, 0xFF3333, 3, 0.8);
                                } else
                                    Drawer.drawLine(displayBatch, lx, ly, x, y, 0xFFFFFF, 3, 0.8);
                            }
                        }
                        if (block)
                            Drawer.drawCircle(displayBatch, node2.nodeData.x, node2.nodeData.y, 0xFF3333, node2.nodeData.lineDist - 4, node2.nodeData.lineDist - 7, false, 0.8);
                        else
                            Drawer.drawCircle(displayBatch, node2.nodeData.x, node2.nodeData.y, 0xFFFFFF, node2.nodeData.lineDist - 4, node2.nodeData.lineDist - 7, false, 0.8);
                    }
                }
            }
            for each (node1 in selectedNodes)
                Drawer.drawCircle(displayBatch, node1.nodeData.x, node1.nodeData.y, 0xFFFFFF, node1.nodeData.lineDist - 4, node1.nodeData.lineDist - 7, false, 0.8);
        }

        // 鼠标左键按下
        public function on_mouseDown(mouse:MouseEvent):void {
            if (game.alpha < 0.5)
                return;
            downx = (mouse.stageX - Starling.current.viewPort.x) / Starling.contentScaleFactor;
            downy = (mouse.stageY - Starling.current.viewPort.y) / Starling.contentScaleFactor;
            var localPoint:Point = convertQuad.globalToLocal(new Point(downx, downy));
            downx = localPoint.x;
            downy = localPoint.y;
            mouseDown = true;
            dragging = false;
        }

        // 鼠标左键拖动（框选天体）
        public function on_mouseMove(mouse:MouseEvent):void {
            var dx:Number = NaN;
            var dy:Number = NaN;
            if (game.alpha < 0.5)
                return;
            if (!mouseDown)
                return;
            dragx = (mouse.stageX - Starling.current.viewPort.x) / Starling.contentScaleFactor;
            dragy = (mouse.stageY - Starling.current.viewPort.y) / Starling.contentScaleFactor;
            var localPoint:Point = convertQuad.globalToLocal(new Point(dragx, dragy));
            dragx = localPoint.x;
            dragy = localPoint.y;
            if (dragging)
                return;
            dx = dragx - downx;
            dy = dragy - downy;
            if (Math.sqrt(dx * dx + dy * dy) > 5) {
                dragging = true;
                if (!mouse.shiftKey)
                    selectedNodes.length = 0;
            }
        }

        // 鼠标左键抬起（选中天体）
        public function on_mouseUp(mouse:MouseEvent):void {
            var x:Number = NaN;
            var y:Number = NaN;
            var node:Node = null;
            mouseDown = false;
            if (game.alpha < 0.5)
                return;
            if (dragging)
                return;
            x = (mouse.stageX - Starling.current.viewPort.x) / Starling.contentScaleFactor;
            y = (mouse.stageY - Starling.current.viewPort.y) / Starling.contentScaleFactor;
            node = getClosestNode(x, y);
            if (mouse.shiftKey) {
                if (node && selectedNodes.indexOf(node) == -1)
                    selectedNodes.push(node);
                else if (node && selectedNodes.indexOf(node) != -1)
                    selectedNodes.splice(selectedNodes.indexOf(node), 1);
            } else {
                selectedNodes.length = 0;
                if (node)
                    selectedNodes.push(node);
            }
        }

        // 鼠标右键按下
        public function on_rightDown(mouse:MouseEvent):void {
            if (game.alpha < 0.5)
                return;
            rightDown = true;
        }

        // 鼠标右键抬起（发送飞船）
        public function on_rightUp(mouse:MouseEvent):void {
            rightDown = false;
            if (game.alpha < 0.5)
                return;
            var x:Number = (mouse.stageX - Starling.current.viewPort.x) / Starling.contentScaleFactor;
            var y:Number = (mouse.stageY - Starling.current.viewPort.y) / Starling.contentScaleFactor;
            var currentNode:Node = getClosestNode(x, y);
            if (!currentNode)
                return;
            FXHandler.addFade(currentNode.nodeData.x, currentNode.nodeData.y, currentNode.nodeData.size, 0xFFFFFF, 1, false);
            for each (var node:Node in selectedNodes) {
                if (node == currentNode || !node.nodeLinks[Globals.playerTeam].includes(currentNode))
                    continue;
                NodeStaticLogic.sendShips(node, Globals.playerTeam, currentNode);
                FXHandler.addFade(node.nodeData.x, node.nodeData.y, node.nodeData.size, 0xFFFFFF, 0, false);
            }
        }

        //#region 计算工具
        private function getClosestNode(x:Number, y:Number):Node {
            var localPoint:Point = convertQuad.globalToLocal(new Point(x, y));
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
