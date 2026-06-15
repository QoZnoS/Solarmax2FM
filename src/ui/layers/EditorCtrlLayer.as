package ui.layers {
    import scenes.EditorScene;
    import starling.display.Quad;
    import starling.display.Sprite;
    import starling.events.Touch;
    import starling.events.TouchEvent;

    import ui.UIContainer;
    import flash.geom.Point;
    import core.EntityContainer;
    import core.entities.Node;
    import starling.events.TouchPhase;
    import utils.Drawer;
    import managers.Globals;
    import starling.display.MeshBatch;
    import core.node.NodeStaticLogic;
    import core.node.NodeData;
    import starling.display.Image;
    import core.node.NodeType;

    public class EditorCtrlLayer extends Sprite {
        private const COLOR:uint = 0xFFAAAA;

        private var convertQuad:Quad; // 转换触点坐标用
        private var touchQuad:Quad;
        private var displayBatch:MeshBatch;
        private var touches:Vector.<Touch>;
        private var editor:EditorScene;
        private var novaBar:Sprite; // 仅用于显示，坐标计算使用全局坐标系

        // #region 初始化逻辑
        public function EditorCtrlLayer(_ui:UIContainer) {
            this.editor = _ui.scene.editorScene;
            this.touchQuad = _ui.touchQuad;
            convertQuad = new Quad(1024, 768, 0xFF0000);
            convertQuad.alpha = 0;
            addChild(convertQuad);
        }

        public function init():void {
            this.displayBatch = LayerFactory.getLayer(LayerFactory.BEHAVIOR) as MeshBatch;
            touchQuad.addEventListener("touch", on_touch);
            initNovaBar();
        }

        public function deinit():void {
            touchQuad.removeEventListener("touch", on_touch);
        }

        // #endregion

        // #region 绘制逻辑
        public function draw():void {
            switch (faceType) {
                case START_FACE:
                    drawStart();
                    break;
                case MOVE_FACE:
                    drawMove();
                    break;
                case NODE_FACE:
                    drawNode();
                    break;
                default:
                    break;
            }
        }

        private function drawStart():void {
            for each (var touch:Touch in touches) {
                if (touch.hoverNode && touch.hoverNode.active) {
                    var nd:NodeData = touch.hoverNode.nodeData;
                    Drawer.drawCircle(displayBatch, nd.x, nd.y, Globals.teamColors[nd.team], nd.lineDist - 4, nd.size * 25 * 2, true, 0.5);
                    if (touch.hoverNode.attackState.attackRate > 0)
                        Drawer.drawDashedCircle(displayBatch, nd.x, nd.y, Globals.teamColors[nd.team], touch.hoverNode.attackState.attackRange, touch.hoverNode.attackState.attackRange - 2, false, 0.5, 1, 0, 256);
                }
            }
        }

        private function drawMove():void {
            for each (var touch:Touch in touches) {
                var point:Point = EntityContainer.getPoint();
                touch.getLocation(convertQuad, point);
                Drawer.drawCircle(displayBatch, point.x, point.y, Globals.teamColors[touch.hoverNode.nodeData.team], touch.hoverNode.nodeData.lineDist - 4, touch.hoverNode.nodeData.size * 25 * 2, true, 0.5);
                if (touch.hoverNode.attackState.attackRate > 0)
                    Drawer.drawDashedCircle(displayBatch, point.x, point.y, Globals.teamColors[touch.hoverNode.nodeData.team], touch.hoverNode.attackState.attackRange, touch.hoverNode.attackState.attackRange - 2, false, 0.5, 1, 0, 256);
                EntityContainer.returnPoint(point);
            }
        }

        private function drawNode():void {
            if (!editor.hoverNode)
                return;
            var nd:NodeData = editor.hoverNode.nodeData
            var nodeX:Number = nd.x;
            var nodeY:Number = nd.y;
            // Drawer.drawCircle(displayBatch, nodeX, nodeY, Globals.teamColors[nd.team], nd.lineDist - 4, nd.size * 25 * 2, true, 0.5);
            Drawer.drawLine(displayBatch, 0, nodeY + novaBarLine, 1024, nodeY + novaBarLine, COLOR);
            Drawer.drawLine(displayBatch, 0, nodeY - novaBarLine, 1024, nodeY - novaBarLine, COLOR);
            Drawer.drawLine(displayBatch, nodeX + novaBarLine, 0, nodeX + novaBarLine, 768, COLOR);
            Drawer.drawLine(displayBatch, nodeX - novaBarLine, 0, nodeX - novaBarLine, 768, COLOR);
        }
        // #region NovaBar
        private const novaBarLine:Number = 36;
        private const novaPreviewSpace:Number = 120;
        private const novaPreviewCount:int = 21;
        private var novaNodeData:NodeData;
        private var novaTypeSprite:Vector.<Image>;
        private var novaTeamSprite:Vector.<Image>;

        private function initNovaBar():void {
            novaBar = new Sprite();
            novaBar.visible = false;
            addChild(novaBar);
            novaNodeData = new NodeData();
            novaTypeSprite = new Vector.<Image>(true, novaPreviewCount);
            novaTeamSprite = new Vector.<Image>(true, novaPreviewCount);
            for (var i:int = 0; i < novaPreviewCount; i++) {
                novaTypeSprite[i] = new Image(Root.assets.getTexture(NodeStaticLogic.getRandomPlanetImage()));
                novaTypeSprite[i].visible = false;
                novaTeamSprite[i] = new Image(Root.assets.getTexture(NodeStaticLogic.getRandomPlanetImage()));
                novaTeamSprite[i].visible = false;
            }
        }

        private function updateNovaBar():void {
            if (!novaBar)
                return;
            if (faceType != NODE_FACE || !editor.hoverNode) {
                novaBar.visible = false;
                return;
            }
            var nd:NodeData = editor.hoverNode.nodeData;
            if (novaBar.visible == false) {
                novaBar.visible = true;
                novaBar.x = nd.x;
                novaBar.y = nd.y;
                syncNovaNodeData(nd);
            }

        }

        private function updateNovaPreview():void {
            // 以 NovaNodeData 为锚点先确定所有预览的类型和位置
            var startIndex:int = -Math.floor(novaPreviewCount / 2);
            var itype:int = scrollInt(NodeType.typeStr2Int(novaNodeData.type), startIndex, NodeType.getTypeCount());
            for each(var preview:Image in novaTypeSprite)
            {
                preview.x = startIndex * novaPreviewSpace;
                preview.texture = Root.assets.getTexture(NodeType.typeInt2Str(itype));
            }

        }

        private function scrollInt(start:int, add:int, max:int, min:int = 0):int {
            start += add;
            if (start >= max)
                start -= max;
            else if (start <= min)
                start += max;
            return start;
        }

        private function syncNovaNodeData(nd:NodeData):void {
            for each (var key:String in nd)
                novaNodeData[key] = nd[key];
        }

        private function isTouchInNovaBar(touch:Touch):Boolean {
            if (!editor.hoverNode)
                return false;
            var p:Point = EntityContainer.getPoint();
            touch.getLocation(convertQuad, p);
            var nd:NodeData = editor.hoverNode.nodeData;
            var inBar:Boolean = Math.abs(p.x - nd.x) <= novaBarLine || Math.abs(p.y - nd.y) <= novaBarLine;
            EntityContainer.returnPoint(p);
            return inBar;
        }
        // #endregion

        // #endregion

        // #region 触控逻辑
        /**
         * 界面：区分交互的响应模式
         * 0：初始界面
         * 1：长按或滑动天体进入移动模式
         * 2：单击进入天体菜单界面
         * 其他：任何不希望与天体交互的界面
         */
        private var faceType:int = 0;
        private const START_FACE:int = 0;
        private const MOVE_FACE:int = 1;
        private const NODE_FACE:int = 2;

        public function update(dt:Number):void {
            draw();
            updateNovaBar();
        }

        private function on_touch(touchEvent:TouchEvent):void {
            if (editor.alpha < 0.5)
                return;
            touches = touchEvent.getTouches(touchQuad);
            if (touches.length == 0)
                return;
            switch (faceType) {
                case START_FACE:
                    startHover(touchEvent);
                    startBegan(touchEvent);
                    startMoved(touchEvent);
                    startEnded(touchEvent);
                    break;
                case MOVE_FACE:
                    moveBegan(touchEvent);
                    moveMoved(touchEvent);
                    moveEnded(touchEvent);
                    break;
                case NODE_FACE:
                    nodeBegan(touchEvent);
                    nodeMoved(touchEvent);
                    nodeEnded(touchEvent);
                    break;
                default:
                    break;
            }
        }

        // #region start face function
        private function startHover(touchEvent:TouchEvent):void {
            var touchArray:Vector.<Touch> = touchEvent.getTouches(touchQuad, TouchPhase.HOVER);
            if (!touchArray)
                return;
            for each (var touch:Touch in touchArray) {
                touch.hoverNode = getClosestNode(touch);
                touch.getLocation(convertQuad, editor.mousePoint);
                editor.hoverNode = touch.hoverNode;
            }
        }

        private function startBegan(touchEvent:TouchEvent):void {
            var touchArray:Vector.<Touch> = touchEvent.getTouches(touchQuad, TouchPhase.BEGAN);
            if (!touchArray)
                return;
            for each (var touch:Touch in touchArray) {
                if (!touch.downNodes)
                    touch.downNodes = new Vector.<Node>;
                touch.downNodes.length = 0;
                var node:Node = getClosestNode(touch);
                if (node && touch.downNodes.indexOf(node) == -1)
                    touch.downNodes.push(node);
                touch.hoverNode = null;
                if (node) {
                    touch.hoverNode = node;
                    if (getMovedDistance(touch) > 10 || touch.duration > 1)
                        faceType = MOVE_FACE;
                }
            }
        }

        private function startMoved(touchEvent:TouchEvent):void {
            var touchArray:Vector.<Touch> = touchEvent.getTouches(touchQuad, TouchPhase.MOVED);
            if (!touchArray)
                return;
            for each (var touch:Touch in touchArray)
                if (touch.hoverNode)
                    if (getMovedDistance(touch) > 10 || touch.duration > 1)
                        faceType = MOVE_FACE;
        }

        private function startEnded(touchEvent:TouchEvent):void {
            var touchArray:Vector.<Touch> = touchEvent.getTouches(touchQuad, TouchPhase.ENDED);
            if (!touchArray)
                return;
            for each (var touch:Touch in touchArray)
                if (touch.hoverNode)
                    if (getMovedDistance(touch) < 10 && touch.duration < 1)
                        faceType = NODE_FACE;
        }

        // #endregion
        // #region move face function
        private function moveBegan(touchEvent:TouchEvent):void {
            var touchArray:Vector.<Touch> = touchEvent.getTouches(touchQuad, TouchPhase.BEGAN);
            if (!touchArray)
                return;
            for each (var touch:Touch in touchArray) {
                if (!touch.hoverNode)
                    continue;
                var node:Node = touch.hoverNode;
                var point:Point = EntityContainer.getPoint();
                touch.getLocation(convertQuad, point);
                NodeStaticLogic.setImagePoint(node, point);
                EntityContainer.returnPoint(point);
            }
        }

        private function moveMoved(touchEvent:TouchEvent):void {
            var touchArray:Vector.<Touch> = touchEvent.getTouches(touchQuad, TouchPhase.MOVED);
            if (!touchArray)
                return;
            for each (var touch:Touch in touchArray) {
                if (!touch.hoverNode)
                    continue;
                var node:Node = touch.hoverNode;
                var point:Point = EntityContainer.getPoint();
                touch.getLocation(convertQuad, point);
                NodeStaticLogic.setImagePoint(node, point);
                EntityContainer.returnPoint(point);
            }
        }

        private function moveEnded(touchEvent:TouchEvent):void {
            var touchArray:Vector.<Touch> = touchEvent.getTouches(touchQuad, TouchPhase.ENDED);
            if (!touchArray)
                return;
            for each (var touch:Touch in touchArray) {
                if (!touch.hoverNode)
                    continue;
                var node:Node = touch.hoverNode;
                var point:Point = EntityContainer.getPoint();
                touch.getLocation(convertQuad, point);
                NodeStaticLogic.setImagePoint(node, point);
                var params:Array = createParameterArray();
                params.push(node.tag, point.x, point.y);
                var output:String = editor.exeCode(EditorScene.MOVE, params);
                EntityContainer.returnPoint(point);
                trace(output);
                faceType = START_FACE;
            }
        }

        // #endregion

        // #region node face function
        private function nodeBegan(touchEvent:TouchEvent):void {
            var touchArray:Vector.<Touch> = touchEvent.getTouches(touchQuad, TouchPhase.BEGAN);
        }

        private function nodeMoved(touchEvent:TouchEvent):void {
            var touchArray:Vector.<Touch> = touchEvent.getTouches(touchQuad, TouchPhase.MOVED);
        }

        private function nodeEnded(touchEvent:TouchEvent):void {
            var touchArray:Vector.<Touch> = touchEvent.getTouches(touchQuad, TouchPhase.ENDED);
            // var p:Point = EntityContainer.getPoint();

            // 退出到 start face
            if (touchArray.length == 1)
                if (!isTouchInNovaBar(touchArray[0]))
                    faceType = START_FACE;
        }

        // #endregion

        // #endregion

        // #region 动画

        // #endregion

        // #region 计算工具
        private function getClosestNode(touch:Touch):Node {
            var globalPoint:Point = EntityContainer.getPoint(touch.globalX, touch.globalY);
            var localPoint:Point = EntityContainer.getPoint();
            convertQuad.globalToLocal(globalPoint, localPoint);
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
            EntityContainer.returnPoint(globalPoint);
            EntityContainer.returnPoint(localPoint);
            return closestNode;
        }

        private function getMovedDistance(touch:Touch):Number {
            var startPoint:Point = EntityContainer.getPoint();
            var endPoint:Point = EntityContainer.getPoint();
            touch.getStartLocation(convertQuad, startPoint);
            touch.getLocation(convertQuad, endPoint);
            var distacne:Number = Point.distance(startPoint, endPoint);
            EntityContainer.returnPoint(startPoint);
            EntityContainer.returnPoint(endPoint);
            return distacne;
        }

        private var TEMP_ARR:Array;

        private function createParameterArray():Array {
            if (!TEMP_ARR)
                TEMP_ARR = [];
            TEMP_ARR.length = 0;
            return TEMP_ARR;
        }

        // #endregion
        public function get faceName():String {
            switch (faceType) {
                case MOVE_FACE:
                    return "move";
                case NODE_FACE:
                    return "node";
                case START_FACE:
                    return "start";
                default:
                    return "unknow";
            }
        }

    }
}
