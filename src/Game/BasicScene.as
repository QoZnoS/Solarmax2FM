package Game {

    import starling.display.Sprite;
    import Game.VictoryType.IVictoryType;
    import Game.LoseType.ILoseType;
    import starling.events.EnterFrameEvent;
    import starling.core.Starling;
    import utils.Rng;
    import UI.UIContainer;
    import flash.geom.Point;
    import Entity.EntityContainer;
    import Entity.FXHandler;
    import Entity.Node;

    public class BasicScene extends Sprite {

        public var scene:SceneController
        public var ui:UIContainer;

        public var victoryType:IVictoryType;
        public var loseType:ILoseType;
        public var barrierLines:Array;

        public var rng:Rng;


        public function BasicScene(scene:SceneController) {
            this.scene = scene;
            barrierLines = [];
        }

        public function update(e:EnterFrameEvent):void{

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
            EntityContainer.entityPool[EntityContainer.INDEX_BARRIERS].deInit();
            addBarriers();
            hideSingleBarriers();
        }

        public function addBarriers():void {
            var x1:Number, y1:Number, x2:Number, y2:Number, x3:Number, y3:Number;
            var dx:Number, dy:Number, angle:Number, distance:Number;
            var space:Number = 8, dspace:int = 0;
            for each (var barrierArray:Array in barrierLines) {
                x1 = Number(barrierArray[0].x), y1 = Number(barrierArray[0].y);
                x2 = Number(barrierArray[1].x), y2 = Number(barrierArray[1].y);
                dx = x2 - x1, dy = y2 - y1;
                angle = Math.atan2(dy, dx), distance = Math.sqrt(dx * dx + dy * dy);
                x3 = x1 + Math.cos(angle) * space, y3 = y1 + Math.sin(angle) * space;
                dspace = int(space);
                while (dspace < int(Math.floor(distance))) {
                    dx = x3 + Math.cos(angle) * space * 0.5, dy = y3 + Math.sin(angle) * space * 0.5;
                    FXHandler.addBarrier(x3, y3, angle, 16729156);
                    x3 += Math.cos(angle) * space, y3 += Math.sin(angle) * space;
                    dspace += int(space);
                }
            }
        }

        public function hideSingleBarriers():void {
            for each (var node:Node in EntityContainer.nodes) {
                if (!node.nodeData.isBarrier)
                    continue;
                node.moveState.image.visible = node.moveState.halo.visible = node.linked;
            }
        }
        /** 一次计算所有连接线 */
        public function initBarrierLines():void {
            var i:int, j:int, k:int;
            var L_1:int, L_2:int, L_3:int;
            var node1:Node, node2:Node;
            var array:Array;
            var exist:Boolean;
            barrierLines.length = 0; // 清空障碍线数组
            L_1 = EntityContainer.nodes.length;
            for (i = 0; i < L_1; i++) {
                node1 = EntityContainer.nodes[i];
                if (!node1.nodeData.isBarrier)
                    continue;
                L_2 = node1.nodeData.barrierLinks.length; // 该天体需连接的障碍总数
                for (j = 0; j < L_2; j++) {
                    if (node1.nodeData.barrierLinks[j] < L_1)
                        node2 = EntityContainer.nodes[node1.nodeData.barrierLinks[j]];
                    array = [new Point(node1.nodeData.x, node1.nodeData.y), new Point(node2.nodeData.x, node2.nodeData.y)];
                    exist = false;
                    L_3 = barrierLines.length;
                    for (k = 0; k < L_3; k++)
                        if (check4same(array, barrierLines[k]))
                            exist = true;
                    if (!exist && node2.nodeData.isBarrier) {
                        barrierLines.push(array);
                        node1.linked = node2.linked = true;
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
