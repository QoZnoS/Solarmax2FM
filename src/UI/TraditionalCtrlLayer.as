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
    import Entity.Node.NodeType;
    import Entity.EntityContainer;

    public class TraditionalCtrlLayer extends Sprite {

        private var selectedNodes:Array;
        private var down_x:Number;
        private var down_y:Number;
        private var drag_x:Number;
        private var drag_y:Number;
        private var mouseDown:Boolean;
        private var dragging:Boolean;
        private var rightDown:Boolean;
        private var game:GameScene;
        private var displayBatch:QuadBatch;
        private var mouseBatch:QuadBatch;
        private var dragQuad:Quad;
        private var dragLine:Quad;
        private var convertQuad:Quad;

        public function TraditionalCtrlLayer(_ui:UIContainer) {
            this.game = _ui.scene.gameScene;
            this.displayBatch = _ui.behaviorBatch;
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
            var _quadtypeX:Number = NaN;
            var _quadtypeY:Number = NaN;
            var i:int = 0;
            var _Node1:Node = null;
            var _mouseX:Number = NaN;
            var _mouseY:Number = NaN;
            var _Node2:Node = null;
            var _Block:Point = null;
            var _x:Number = NaN;
            var _y:Number = NaN;
            var _dx:Number = NaN;
            var _dy:Number = NaN;
            var _angle:Number = NaN;
            var _lx:Number = NaN;
            var _ly:Number = NaN;
            if (mouseDown && dragging) {
                dragQuad.x = down_x;
                dragQuad.y = down_y;
                dragQuad.width = drag_x - down_x;
                dragQuad.height = drag_y - down_y;
                dragQuad.alpha = 0.2;
                mouseBatch.addQuad(dragQuad);
                _quadtypeX = drag_x - down_x > 0 ? 1 : -1;
                _quadtypeY = drag_y - down_y > 0 ? 1 : -1;
                dragLine.alpha = 0.5;
                dragLine.width = (dragQuad.width + 2) * _quadtypeX;
                dragLine.height = _quadtypeY;
                dragLine.x = down_x - _quadtypeX;
                dragLine.y = down_y - _quadtypeY;
                mouseBatch.addQuad(dragLine);
                dragLine.x = down_x - _quadtypeX;
                dragLine.y = down_y + dragQuad.height * _quadtypeY;
                mouseBatch.addQuad(dragLine);
                dragLine.width = _quadtypeX;
                dragLine.height = dragQuad.height * _quadtypeY;
                dragLine.x = down_x - _quadtypeX;
                dragLine.y = down_y;
                mouseBatch.addQuad(dragLine);
                dragLine.x = down_x + dragQuad.width * _quadtypeX;
                dragLine.y = down_y;
                mouseBatch.addQuad(dragLine);
                if(dragQuad.color != 0x000000)
                    mouseBatch.blendMode = "add";
                for each (_Node1 in EntityContainer.nodes) {
                    if (_Node1.ships[1].length == 0 && _Node1.nodeData.team != 1)
                        continue;
                    if (selectedNodes.indexOf(_Node1) != -1)
                        continue;
                    if (_quadtypeX > 0 && _quadtypeY > 0) {
                        if (_Node1.nodeData.x > down_x && _Node1.nodeData.x < drag_x && _Node1.nodeData.y > down_y && _Node1.nodeData.y < drag_y)
                            selectedNodes.push(_Node1);
                    } else if (_quadtypeX > 0 && _quadtypeY < 0) {
                        if (_Node1.nodeData.x > down_x && _Node1.nodeData.x < drag_x && _Node1.nodeData.y > drag_y && _Node1.nodeData.y < down_y)
                            selectedNodes.push(_Node1);
                    } else if (_quadtypeX < 0 && _quadtypeY > 0) {
                        if (_Node1.nodeData.x > drag_x && _Node1.nodeData.x < down_x && _Node1.nodeData.y > down_y && _Node1.nodeData.y < drag_y)
                            selectedNodes.push(_Node1);
                    } else if (_quadtypeX < 0 && _quadtypeY < 0) {
                        if (_Node1.nodeData.x > drag_x && _Node1.nodeData.x < down_x && _Node1.nodeData.y > drag_y && _Node1.nodeData.y < down_y)
                            selectedNodes.push(_Node1);
                    }
                }
            } else {
                _mouseX = (Starling.current.nativeStage.mouseX - Starling.current.viewPort.x) / Starling.contentScaleFactor;
                _mouseY = (Starling.current.nativeStage.mouseY - Starling.current.viewPort.y) / Starling.contentScaleFactor;
                _Node2 = getClosestNode(_mouseX, _mouseY);
                if (_Node2) {
                    Drawer.drawCircle(displayBatch, _Node2.nodeData.x, _Node2.nodeData.y, Globals.teamColors[_Node2.nodeData.team], _Node2.nodeData.lineDist - 4, _Node2.nodeData.size * 25 * 2, true, 0.5);
                    if (_Node2.attackState.attackRate > 0 && _Node2.attackState.attackRange > 0)
                        Drawer.drawDashedCircle(displayBatch, _Node2.nodeData.x, _Node2.nodeData.y, Globals.teamColors[_Node2.nodeData.team], _Node2.attackState.attackRange, _Node2.attackState.attackRange - 2, false, 0.5, 1, 0, 256);
                    if (rightDown && selectedNodes.length > 0) {
                        for each (_Node1 in selectedNodes) {
                            _Block = nodesBlocked(_Node1, _Node2);
                            _x = _Node2.nodeData.x;
                            _y = _Node2.nodeData.y;
                            _dx = _x - _Node1.nodeData.x;
                            _dy = _y - _Node1.nodeData.y;
                            if (Math.sqrt(_dx * _dx + _dy * _dy) > _Node1.nodeData.lineDist - 5) {
                                _angle = Math.atan2(_dy, _dx);
                                _lx = _Node1.nodeData.x + Math.cos(_angle) * (_Node1.nodeData.lineDist - 5);
                                _ly = _Node1.nodeData.y + Math.sin(_angle) * (_Node1.nodeData.lineDist - 5);
                                _x -= Math.cos(_angle) * (_Node2.nodeData.lineDist - 5);
                                _y -= Math.sin(_angle) * (_Node2.nodeData.lineDist - 5);
                                if (_Block) {
                                    Drawer.drawLine(displayBatch, _lx, _ly, _Block.x, _Block.y, 0xFFFFFF, 3, 0.8);
                                    Drawer.drawLine(displayBatch, _Block.x, _Block.y, _x, _y, 0xFF3333, 3, 0.8);
                                } else
                                    Drawer.drawLine(displayBatch, _lx, _ly, _x, _y, 0xFFFFFF, 3, 0.8);
                            }
                        }
                        if (_Block)
                            Drawer.drawCircle(displayBatch, _Node2.nodeData.x, _Node2.nodeData.y, 0xFF3333, _Node2.nodeData.lineDist - 4, _Node2.nodeData.lineDist - 7, false, 0.8);
                        else
                            Drawer.drawCircle(displayBatch, _Node2.nodeData.x, _Node2.nodeData.y, 0xFFFFFF, _Node2.nodeData.lineDist - 4, _Node2.nodeData.lineDist - 7, false, 0.8);
                    }
                }
            }
            for each (_Node1 in selectedNodes) {
                Drawer.drawCircle(displayBatch, _Node1.nodeData.x, _Node1.nodeData.y, 0xFFFFFF, _Node1.nodeData.lineDist - 4, _Node1.nodeData.lineDist - 7, false, 0.8);
            }
        }

        public function on_mouseDown(_Mouse:MouseEvent):void // 鼠标左键按下
        {
            if (game.alpha < 0.5)
                return;
            down_x = (_Mouse.stageX - Starling.current.viewPort.x) / Starling.contentScaleFactor;
            down_y = (_Mouse.stageY - Starling.current.viewPort.y) / Starling.contentScaleFactor;
            var _localPoint:Point = convertQuad.globalToLocal(new Point(down_x, down_y));
            down_x = _localPoint.x;
            down_y = _localPoint.y;
            mouseDown = true;
            dragging = false;
        }

        public function on_mouseMove(_Mouse:MouseEvent):void // 鼠标左键拖动（框选天体）
        {
            var _dx:Number = NaN;
            var _dy:Number = NaN;
            if (game.alpha < 0.5)
                return;
            if (!mouseDown)
                return;
            drag_x = (_Mouse.stageX - Starling.current.viewPort.x) / Starling.contentScaleFactor;
            drag_y = (_Mouse.stageY - Starling.current.viewPort.y) / Starling.contentScaleFactor;
            var _localPoint:Point = convertQuad.globalToLocal(new Point(drag_x, drag_y));
            drag_x = _localPoint.x;
            drag_y = _localPoint.y;
            if (dragging)
                return;
            _dx = drag_x - down_x;
            _dy = drag_y - down_y;
            if (Math.sqrt(_dx * _dx + _dy * _dy) > 5) {
                dragging = true;
                if (!_Mouse.shiftKey)
                    selectedNodes.length = 0;
            }
        }

        public function on_mouseUp(_Mouse:MouseEvent):void // 鼠标左键抬起（选中天体）
        {
            var _x:Number = NaN;
            var _y:Number = NaN;
            var _Node:Node = null;
            mouseDown = false;
            if (game.alpha < 0.5)
                return;
            if (dragging)
                return;
            _x = (_Mouse.stageX - Starling.current.viewPort.x) / Starling.contentScaleFactor;
            _y = (_Mouse.stageY - Starling.current.viewPort.y) / Starling.contentScaleFactor;
            _Node = getClosestNode(_x, _y);
            if (_Mouse.shiftKey) {
                if (_Node && selectedNodes.indexOf(_Node) == -1)
                    selectedNodes.push(_Node);
                else if (_Node && selectedNodes.indexOf(_Node) != -1)
                    selectedNodes.splice(selectedNodes.indexOf(_Node), 1);
            } else {
                selectedNodes.length = 0;
                if (_Node)
                    selectedNodes.push(_Node);
            }
        }

        public function on_rightDown(_Mouse:MouseEvent):void // 鼠标右键按下
        {
            if (game.alpha < 0.5)
                return;
            rightDown = true;
        }

        public function on_rightUp(_Mouse:MouseEvent):void // 鼠标右键抬起（发送飞船）
        {
            rightDown = false;
            if (game.alpha < 0.5)
                return;
            var _x:Number = (_Mouse.stageX - Starling.current.viewPort.x) / Starling.contentScaleFactor;
            var _y:Number = (_Mouse.stageY - Starling.current.viewPort.y) / Starling.contentScaleFactor;
            var _currentNode:Node = getClosestNode(_x, _y);
            if (!_currentNode)
                return;
            FXHandler.addFade(_currentNode.nodeData.x, _currentNode.nodeData.y, _currentNode.nodeData.size, 0xFFFFFF, 1);
            for each (var _Node:Node in selectedNodes) {
                if (_Node == _currentNode || nodesBlocked(_Node, _currentNode))
                    continue;
                NodeStaticLogic.sendShips(_Node, 1, _currentNode);
                FXHandler.addFade(_Node.nodeData.x, _Node.nodeData.y, _Node.nodeData.size, 0xFFFFFF, 0);
            }
        }


        //#region 计算工具
        private function getClosestNode(_x:Number, _y:Number):Node {
            var _localPoint:Point = convertQuad.globalToLocal(new Point(_x, _y));
            var _ClosestNode:Node = null;
            var _dx:Number = NaN;
            var _dy:Number = NaN;
            var _Distance:Number = NaN;
            var _lineDist:Number = NaN;
            var _ClosestDist:Number = 200;
            for each (var _Node:Node in EntityContainer.nodes) {
                if (_Node.nodeData.type == NodeType.BARRIER)
                    continue;
                _dx = _Node.nodeData.x - _localPoint.x;
                _dy = _Node.nodeData.y - _localPoint.y;
                _Distance = Math.sqrt(_dx * _dx + _dy * _dy);
                _lineDist = _Node.nodeData.lineDist;
                if (_Distance < _lineDist && _Distance < _ClosestDist) {
                    _ClosestDist = _Distance;
                    _ClosestNode = _Node;
                }
            }
            return _ClosestNode;
        }

        /**判断路径是否被拦截并计算拦截点*/
        private function nodesBlocked(_Node1:Node, _Node2:Node):Point {
            var _bar1:Point = null;
            var _bar2:Point = null;
            var _Intersection:Point = null;
            if (_Node1.nodeData.team == 1 && _Node1.nodeData.type == NodeType.WARP)
                return null;
            for each (var _bar:Array in game.barrierLines) {
                _bar1 = _bar[0];
                _bar2 = _bar[1];
                _Intersection = getIntersection(_Node1.nodeData.x, _Node1.nodeData.y, _Node2.nodeData.x, _Node2.nodeData.y, _bar1.x, _bar1.y, _bar2.x, _bar2.y); // 计算交点
                if (_Intersection)
                    return _Intersection;
            }
            return null;
        }

        private function getIntersection(_p1x:Number, _p1y:Number, _p2x:Number, _p2y:Number, _p3x:Number, _p3y:Number, _p4x:Number, _p4y:Number):Point {
            var _L1dx:Number = _p2x - _p1x;
            var _L1dy:Number = _p2y - _p1y;
            var _L2dx:Number = _p4x - _p3x;
            var _L2dy:Number = _p4y - _p3y;
            var _Ratio1:Number = (-_L1dy * (_p1x - _p3x) + _L1dx * (_p1y - _p3y)) / (-_L2dx * _L1dy + _L1dx * _L2dy);
            var _Ratio2:Number = (_L2dx * (_p1y - _p3y) - _L2dy * (_p1x - _p3x)) / (-_L2dx * _L1dy + _L1dx * _L2dy);
            if (_Ratio1 >= 0 && _Ratio1 <= 1 && _Ratio2 >= 0 && _Ratio2 <= 1)
                return new Point(_p1x + _Ratio2 * _L1dx, _p1y + _Ratio2 * _L1dy);
            return null;
        }

        private function lineBlocked(_x1:Number, _y1:Number, _x2:Number, _y2:Number):Point {
            var _Intersection:Point = null;
            var _bar1:Point = null;
            var _bar2:Point = null;
            for each (var _bar:Array in game.barrierLines) {
                _bar1 = _bar[0];
                _bar2 = _bar[1];
                _Intersection = getIntersection(_x1, _y1, _x2, _y2, _bar1.x, _bar1.y, _bar2.x, _bar2.y);
                if (_Intersection)
                    return _Intersection;
            }
            return null;
        }
        //#endregion        
    }
}
