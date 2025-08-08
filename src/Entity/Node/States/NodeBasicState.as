package Entity.Node.States {
    import Entity.Node;
    import Entity.Ship;
    import Entity.Node.NodeStaticLogic;

    public class NodeBasicState implements INodeState {
        public var node:Node;
        public var winPulseTimer:Number;
        public var warps:Vector.<Boolean>; // 是否有传送，只和传送门目的地特效有关

        public function NodeBasicState(node:Node) {
            this.node = node;
            warps = new Vector.<Boolean>;
        }

        public function init():void {
            warps.length = 0;
            for (var i:int = 0; i < Globals.teamCount; i++) {
                warps.push(false);
            }
            winPulseTimer = 0;
        }

        public function deinit():void {

        }

        public function update(dt:Number):void {
            for (var i:int = 0; i < node.ships.length; i++) {
                var l:int = int(node.ships[i].length);
                for (var j:int = 0; j < l; j++) {
                    var ship:Ship = node.ships[i][j];
                    if (ship.state == 0)
                        continue; // 不处理驻留的飞船
                    if (ship.state == 1) {
                        if (node.aiTimers[i] < 0.5)
                            node.aiTimers[i] = 0.5;
                    } else {
                        node.ships[i][j] = node.ships[i][l - 1];
                        node.ships[i].pop();
                        l--;
                        j--;
                    }
                }
            }
            if (winPulseTimer > 0) {
                winPulseTimer = Math.max(0, winPulseTimer - dt);
                if (winPulseTimer == 0)
                    NodeStaticLogic.changeTeam(node, node.game.winningTeam);
            }
            for (i = 0; i < warps.length; i++) { // 有传送时播放传送门目的地特效
                if (warps[i])
                    NodeStaticLogic.showWarpArrive(node, i);
                warps[i] = false;
            }
        }

        public function get enable():Boolean {
            return true;
        }

        public function toJSON(k:String):* {
            return null;
        }

        public function get stateType():String {
            return NodeStateFactory.BASIC;
        }


    }
}
