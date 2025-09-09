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
    import Entity.Node.NodeType;
    import Entity.EntityContainer;

    public class TouchCtrlLayer extends Sprite {
        private var convertQuad:Quad; // 转换触点坐标用
        private var touchQuad:Quad;
        private var displayBatch:QuadBatch;
        private var touches:Vector.<Touch>;
        private var game:GameScene;

        public function TouchCtrlLayer(_ui:UIContainer) {
            this.game = _ui.scene.gameScene;
            this.displayBatch = UIContainer.behaviorBatch;
            this.touchQuad = _ui.touchQuad;
            convertQuad = new Quad(1024, 768, 16711680);
            convertQuad.alpha = 0;
            addChild(convertQuad)
        }

        public function init():void {
            touchQuad.addEventListener("touch", on_touch); // 按操作方式添加事件监听器
        }

        public function deinit():void {
            touchQuad.removeEventListener("touch", on_touch);
        }

        public function draw():void {
            const _Color:uint = 0xFFFFFF;
            var _Tx:Number = NaN; // T 表示 touch 触摸点
            var _Ty:Number = NaN;
            var _Block:Point = null;
            var _dx:Number = NaN;
            var _dy:Number = NaN;
            var _Distance:Number = NaN;
            var _Angle:Number = NaN;
            var _Nx:Number = NaN; // N 表示 node 天体
            var _Ny:Number = NaN;
            if (!touches)
                return;
            for each (var _Touch:Touch in touches) {
                if (_Touch.hoverNode) {
                    Drawer.drawCircle(displayBatch, _Touch.hoverNode.nodeData.x, _Touch.hoverNode.nodeData.y, Globals.teamColors[_Touch.hoverNode.nodeData.team], _Touch.hoverNode.nodeData.lineDist - 4, _Touch.hoverNode.nodeData.size * 25 * 2, true, 0.5);
                    if (_Touch.hoverNode.attackState.attackRate > 0)
                        Drawer.drawDashedCircle(displayBatch, _Touch.hoverNode.nodeData.x, _Touch.hoverNode.nodeData.y, Globals.teamColors[_Touch.hoverNode.nodeData.team], _Touch.hoverNode.attackState.attackRange, _Touch.hoverNode.attackState.attackRange - 2, false, 0.5, 1, 0, 256);
                }
                if (!(_Touch.downNodes && _Touch.downNodes.length > 0))
                    continue
                for each (var _Node:Node in _Touch.downNodes) {
                    Drawer.drawCircle(displayBatch, _Node.nodeData.x, _Node.nodeData.y, _Color, _Node.nodeData.lineDist - 4, _Node.nodeData.lineDist - 7, false, 0.8);
                    var _localPoint:Point = convertQuad.globalToLocal(new Point(_Touch.globalX, _Touch.globalY));
                    _Tx = _localPoint.x;
                    _Ty = _localPoint.y;
                    if (_Touch.hoverNode) { // 绘制目标天体的定位圈
                        if (_Touch.hoverNode.nodeData.team == Globals.playerTeam)
                            _Block = EntityContainer.nodesBlocked(_Node, _Touch.hoverNode);
                        _Tx = _Touch.hoverNode.nodeData.x;
                        _Ty = _Touch.hoverNode.nodeData.y;
                        if (_Block)
                            Drawer.drawCircle(displayBatch, _Tx, _Ty, 0xFF3333, _Touch.hoverNode.nodeData.lineDist - 4, _Touch.hoverNode.nodeData.lineDist - 7, false, 0.8);
                        else
                            Drawer.drawCircle(displayBatch, _Tx, _Ty, _Color, _Touch.hoverNode.nodeData.lineDist - 4, _Touch.hoverNode.nodeData.lineDist - 7, false, 0.8);
                    } else
                        _Block = lineBlocked(_Node.nodeData.x, _Node.nodeData.y, _Tx, _Ty);
                    _dx = _Tx - _Node.nodeData.x;
                    _dy = _Ty - _Node.nodeData.y;
                    _Distance = Math.sqrt(_dx * _dx + _dy * _dy);
                    if (_Distance > _Node.nodeData.lineDist - 5) { // 鼠标移出天体定位圈时绘制
                        _Angle = Math.atan2(_dy, _dx);
                        _Nx = _Node.nodeData.x + Math.cos(_Angle) * (_Node.nodeData.lineDist - 5);
                        _Ny = _Node.nodeData.y + Math.sin(_Angle) * (_Node.nodeData.lineDist - 5);
                        if (_Touch.hoverNode) {
                            _Tx -= Math.cos(_Angle) * (_Touch.hoverNode.nodeData.lineDist - 5);
                            _Ty -= Math.sin(_Angle) * (_Touch.hoverNode.nodeData.lineDist - 5);
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

        private function on_touch(_TouchEvent:TouchEvent):void {
            if (game.alpha < 0.5)
                return;
            touchHover(_TouchEvent); // 专用于选中渐变圈
            touchBegan(_TouchEvent); // 获取鼠标按下时选中的初始天体
            touchMoved(_TouchEvent); // 获取鼠标移动中选中的初始天体
            touchEnded(_TouchEvent); // 获取鼠标释放时选中的目标天体，并发送飞船
            touches = _TouchEvent.getTouches(touchQuad);
        }

        private function touchHover(_TouchEvent:TouchEvent):void {
            var _TouchArray:Vector.<Touch> = _TouchEvent.getTouches(touchQuad, "hover");
            if (!_TouchArray)
                return;
            for each (var _Touch:Touch in _TouchArray) {
                _Touch.hoverNode = getClosestNode(_Touch);
            }
        }

        private function touchBegan(_TouchEvent:TouchEvent):void {
            var _TouchArray:Vector.<Touch> = _TouchEvent.getTouches(touchQuad, "began");
            if (!_TouchArray)
                return;
            for each (var _Touch:Touch in _TouchArray) {
                if (!_Touch.downNodes)
                    _Touch.downNodes = [];
                _Touch.downNodes.length = 0;
                var _Node:Node = getClosestNode(_Touch);
                if (_Node && _Touch.downNodes.indexOf(_Node) == -1)
                    _Touch.downNodes.push(_Node);
                _Touch.hoverNode = null;
                if (_Node)
                    _Touch.hoverNode = _Node;
            }
        }

        private function touchMoved(_TouchEvent:TouchEvent):void {
            var _TouchArray:Vector.<Touch> = _TouchEvent.getTouches(touchQuad, "moved");
            if (!_TouchArray)
                return;
            for each (var _Touch:Touch in _TouchArray) {
                if (!_Touch.downNodes)
                    _Touch.downNodes = [];
                var _Node:Node = getClosestNode(_Touch);
                if (_Node && _Touch.downNodes.indexOf(_Node) == -1 && _Touch.downNodes.length == 0)
                    _Touch.downNodes.push(_Node);
                _Touch.hoverNode = null;
                if (_Node)
                    _Touch.hoverNode = _Node;
            }
        }

        private function touchEnded(_TouchEvent:TouchEvent):void {
            var _Node1:Node = null;
            var _Node2:Node = null;
            var _TouchArray:Vector.<Touch> = _TouchEvent.getTouches(touchQuad, "ended");
            if (!_TouchArray)
                return;
            for each (var _Touch:Touch in _TouchArray) {
                if (_Touch.hoverNode && _Touch.downNodes.length > 0) {
                    _Node1 = _Touch.hoverNode;
                    FXHandler.addFade(_Node1.nodeData.x, _Node1.nodeData.y, _Node1.nodeData.size, 0xFFFFFF, 1);
                    for each (_Node2 in _Touch.downNodes) {
                        if (_Node2 == _Node1 || !_Node2.nodeLinks[Globals.playerTeam].includes(_Node1))
                            continue;
                        NodeStaticLogic.sendShips(_Node2, Globals.playerTeam, _Node1);
                        FXHandler.addFade(_Node2.nodeData.x, _Node2.nodeData.y, _Node2.nodeData.size, 0xFFFFFF, 0);
                    }
                }
                _Touch.hoverNode = null;
                if (_Touch.downNodes)
                    _Touch.downNodes.length = 0;
            }
        }

        //#region 计算工具
        private function getClosestNode(_Touch:Touch):Node {
            var _localPoint:Point = convertQuad.globalToLocal(new Point(_Touch.globalX, _Touch.globalY));
            var _ClosestNode:Node = null;
            var _dx:Number = NaN;
            var _dy:Number = NaN;
            var _Distance:Number = NaN;
            var _lineDist:Number = NaN;
            var _ClosestDist:Number = 200;
            for each (var _Node:Node in EntityContainer.nodes) {
                if (_Node.nodeData.isUntouchable)
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

        private function lineBlocked(_x1:Number, _y1:Number, _x2:Number, _y2:Number):Point {
            var _Intersection:Point = null;
            var _bar1:Point = null;
            var _bar2:Point = null;
            for each (var _bar:Array in game.barrierLines) {
                _bar1 = _bar[0];
                _bar2 = _bar[1];
                _Intersection = EntityContainer.getIntersection(_x1, _y1, _x2, _y2, _bar1.x, _bar1.y, _bar2.x, _bar2.y);
                if (_Intersection)
                    return _Intersection;
            }
            return null;
        }
        //#endregion
    }
}
