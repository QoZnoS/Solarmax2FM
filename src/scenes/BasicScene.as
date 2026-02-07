package scenes {

    import core.entities.Node;
    import core.game.lose.ILoseType;
    import core.game.victory.IVictoryType;

    import flash.geom.Point;

    import starling.events.EnterFrameEvent;

    import ui.UIContainer;

    import utils.Rng;
    import starling.display.Sprite;
    import starling.core.Starling;
    import managers.Globals;
    import core.FXHandler;
    import core.EntityContainer;

    public class BasicScene extends Sprite {

        public var scene:SceneController

        public var victoryType:IVictoryType;
        public var loseType:ILoseType;
        public var barrierLines:Array; // 格式: [[node1, node2], [node1, node3], ...]
        // 缓存障碍天体
        private var _barrierNodes:Array;

        public var rng:Rng;


        public function BasicScene(scene:SceneController) {
            this.scene = scene;
            barrierLines = [];
            _barrierNodes = [];
        }

        public function update(e:EnterFrameEvent):void {

        }

        public function animateIn():void {
            this.alpha = 0;
            this.visible = true;
            Starling.juggler.tween(this, Globals.transitionSpeed, {"alpha": 1,
                    "transition": "easeInOut"});
        }

        public function animateOut():void {
            Starling.juggler.tween(this, Globals.transitionSpeed, {"alpha": 0,
                    "transition": "easeInOut"});
        }

        public function updateBarrier():void {
            addBarriers();
            hideSingleBarriers();
        }

        public function addBarriers():void {
            var node1:Node, node2:Node;
            var x1:Number, y1:Number, x2:Number, y2:Number, x3:Number, y3:Number;
            var dx:Number, dy:Number, angle:Number, distance:Number;
            var space:Number = 8, dspace:int = 0;

            for each (var nodePair:Array in barrierLines) {
                node1 = nodePair[0];
                node2 = nodePair[1];
                x1 = node1.nodeData.x;
                y1 = node1.nodeData.y;
                x2 = node2.nodeData.x;
                y2 = node2.nodeData.y;
                dx = x2 - x1;
                dy = y2 - y1;
                angle = Math.atan2(dy, dx);
                distance = Math.sqrt(dx * dx + dy * dy);
                x3 = x1 + Math.cos(angle) * space;
                y3 = y1 + Math.sin(angle) * space;
                dspace = int(space);
                while (dspace < int(Math.floor(distance))) {
                    FXHandler.addBarrier(x3, y3, angle, 0xFF4444);
                    x3 += Math.cos(angle) * space;
                    y3 += Math.sin(angle) * space;
                    dspace += int(space);
                }
            }
        }

        public function hideSingleBarriers():void {
            for each (var node:Node in _barrierNodes)
                node.moveState.image.visible = node.moveState.halo.visible = node.linked;
        }

        /** 一次计算所有连接线 */
        public function initBarrierLines():void {
            var i:int, j:int;
            var node1:Node, node2:Node;
            var nodePair:Array;
            barrierLines.length = 0;
            _barrierNodes.length = 0;
            var totalNodes:int = EntityContainer.nodes.length;
            for (i = 0; i < totalNodes; i++) {
                node1 = EntityContainer.nodes[i];
                if (node1.nodeData.isBarrier)
                    _barrierNodes.push(node1);
            }
            // 使用Set避免重复添加相同的连接线
            var addedPairs:Object = {};
            var barrierCount:int = _barrierNodes.length;
            for (i = 0; i < barrierCount; i++) {
                node1 = _barrierNodes[i];
                var linkCount:int = node1.nodeData.barrierLinks.length;
                for (j = 0; j < linkCount; j++) {
                    var linkIndex:int = node1.nodeData.barrierLinks[j];
                    if (linkIndex >= totalNodes)
                        continue;
                    node2 = EntityContainer.nodes[linkIndex];
                    if (!node2.nodeData.isBarrier)
                        continue;
                    // 创建连接线ID（按节点ID排序，确保唯一性）
                    var pairId:String;
                    if (node1.tag < node2.tag)
                        pairId = node1.tag + "_" + node2.tag;
                    else
                        pairId = node2.tag + "_" + node1.tag;

                    if (!addedPairs[pairId]) {
                        addedPairs[pairId] = true;
                        barrierLines.push([node1, node2]);
                        node1.linked = true;
                        node2.linked = true;
                    }
                }
            }
        }

        protected function check4same(array1:Array, array2:Array):Boolean {
            var a1:Point = array1[0];
            var a2:Point = array1[1];
            var b1:Point = array2[0];
            var b2:Point = array2[1];
            var result:Boolean = false;
            if (a1.x == b1.x && a1.y == b1.y && a2.x == b2.x && a2.y == b2.y)
                result = true;
            if (a1.x == b2.x && a1.y == b2.y && a2.x == b1.x && a2.y == b1.y)
                result = true;
            return result;
        }
    }
}
