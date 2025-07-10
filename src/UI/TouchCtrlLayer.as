package UI {
    import starling.display.Sprite;
    import starling.events.TouchEvent;
    import Game.Entity.GameEntity.Node;
    import Game.Entity.FXHandler;
    import starling.events.Touch;
    import starling.display.Quad;
    import flash.geom.Point;
    import Game.GameScene;
    import utils.Drawer;

    public class TouchCtrlLayer extends Sprite {
        private var touchQuad:Quad;
        private var touches:Vector.<Touch>;
        private var game:GameScene;

        public function TouchCtrlLayer(_game:GameScene) {
            this.game = _game;
            touchQuad = new Quad(1024, 768, 16711680);
            touchQuad.alpha = 0;
            addChild(touchQuad)
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
                    Drawer.drawCircle(game.uiBatch, _Touch.hoverNode.x, _Touch.hoverNode.y, Globals.teamColors[_Touch.hoverNode.team], _Touch.hoverNode.lineDist - 4, _Touch.hoverNode.size * 25 * 2, true, 0.5);
                    if (_Touch.hoverNode.attackStrategy.attackRate > 0)
                        Drawer.drawDashedCircle(game.uiBatch, _Touch.hoverNode.x, _Touch.hoverNode.y, Globals.teamColors[_Touch.hoverNode.team], _Touch.hoverNode.attackStrategy.attackRange, _Touch.hoverNode.attackStrategy.attackRange - 2, false, 0.5, 1, 0, 256);
                }
                if (!(_Touch.downNodes && _Touch.downNodes.length > 0))
                    continue
                for each (var _Node:Node in _Touch.downNodes) {
                    Drawer.drawCircle(game.uiBatch, _Node.x, _Node.y, _Color, _Node.lineDist - 4, _Node.lineDist - 7, false, 0.8);
                    _Tx = _Touch.globalX;
                    _Ty = _Touch.globalY;
                    if (_Touch.hoverNode) { // 绘制目标天体的定位圈
                        _Block = nodesBlocked(_Node, _Touch.hoverNode);
                        _Tx = _Touch.hoverNode.x;
                        _Ty = _Touch.hoverNode.y;
                        if (_Block)
                            Drawer.drawCircle(game.uiBatch, _Tx, _Ty, 0xFF3333, _Touch.hoverNode.lineDist - 4, _Touch.hoverNode.lineDist - 7, false, 0.8);
                        else
                            Drawer.drawCircle(game.uiBatch, _Tx, _Ty, _Color, _Touch.hoverNode.lineDist - 4, _Touch.hoverNode.lineDist - 7, false, 0.8);
                    } else
                        _Block = lineBlocked(_Node.x, _Node.y, _Tx, _Ty);
                    _dx = _Tx - _Node.x;
                    _dy = _Ty - _Node.y;
                    _Distance = Math.sqrt(_dx * _dx + _dy * _dy);
                    if (_Distance > _Node.lineDist - 5) { // 鼠标移出天体定位圈时绘制
                        _Angle = Math.atan2(_dy, _dx);
                        _Nx = _Node.x + Math.cos(_Angle) * (_Node.lineDist - 5);
                        _Ny = _Node.y + Math.sin(_Angle) * (_Node.lineDist - 5);
                        if (_Touch.hoverNode) {
                            _Tx -= Math.cos(_Angle) * (_Touch.hoverNode.lineDist - 5);
                            _Ty -= Math.sin(_Angle) * (_Touch.hoverNode.lineDist - 5);
                        }
                        if (_Block) { // 分段绘制鼠标线
                            Drawer.drawLine(game.uiBatch, _Nx, _Ny, _Block.x, _Block.y, _Color, 3, 0.8);
                            Drawer.drawLine(game.uiBatch, _Block.x, _Block.y, _Tx, _Ty, 0xFF3333, 3, 0.8);
                        } else
                            Drawer.drawLine(game.uiBatch, _Nx, _Ny, _Tx, _Ty, _Color, 3, 0.8);
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
                _Touch.hoverNode = getClosestNode(_Touch.globalX, _Touch.globalY);
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
                var _Node:Node = getClosestNode(_Touch.globalX, _Touch.globalY);
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
                var _Node:Node = getClosestNode(_Touch.globalX, _Touch.globalY);
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
                    FXHandler.addFade(_Node1.x, _Node1.y, _Node1.size, 0xFFFFFF, 1);
                    for each (_Node2 in _Touch.downNodes) {
                        if (_Node2 == _Node1 || nodesBlocked(_Node2, _Node1))
                            continue;
                        _Node2.sendShips(1, _Node1);
                        FXHandler.addFade(_Node2.x, _Node2.y, _Node2.size, 0xFFFFFF, 0);
                    }
                }
                _Touch.hoverNode = null;
                if (_Touch.downNodes)
                    _Touch.downNodes.length = 0;
            }
        }

        //#region 计算工具
        private function getClosestNode(_x:Number, _y:Number):Node {
            var _ClosestNode:Node = null;
            var _dx:Number = NaN;
            var _dy:Number = NaN;
            var _Distance:Number = NaN;
            var _lineDist:Number = NaN;
            var _ClosestDist:Number = 200;
            for each (var _Node:Node in game.nodes.active) {
                if (_Node.type == 3)
                    continue;
                _dx = _Node.x - _x;
                _dy = _Node.y - _y;
                _Distance = Math.sqrt(_dx * _dx + _dy * _dy);
                _lineDist = _Node.lineDist;
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
            if (_Node1.team == 1 && _Node1.type == 1)
                return null;
            for each (var _bar:Array in game.barrierLines) {
                _bar1 = _bar[0];
                _bar2 = _bar[1];
                _Intersection = getIntersection(_Node1.x, _Node1.y, _Node2.x, _Node2.y, _bar1.x, _bar1.y, _bar2.x, _bar2.y); // 计算交点
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
