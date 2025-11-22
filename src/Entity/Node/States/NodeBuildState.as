package Entity.Node.States {
    import Entity.Node;
    import Entity.EntityHandler;
    import Entity.Node.NodeData;

    public class NodeBuildState implements INodeState {

        public var node:Node;
        public var nodeData:NodeData;
        public var buildTimer:Number; // 生产计时器
        public var buildRate:Number; // 生产速度，生产时间的倒数

        public function NodeBuildState(node:Node) {
            this.node = node
        }

        public function init():void {
            this.nodeData = node.nodeData;
            buildTimer = 1;
        }

        public function deinit():void {
        }

        public function update(dt:Number):void {
            buildTimer -= buildRate * Globals.teamNodeBuilds[nodeData.team] * dt; // 计算生产计时器
            while (buildTimer <= 0) {
                buildTimer += 1; // 重置倒计时
                EntityHandler.addShip(node, nodeData.team); // 生产飞船
            }
        }

        public function toJSON(k:String):* {
            throw new Error("Method not implemented.");
        }

        public function get enable():Boolean {
            return !(nodeData.team == 0 || // 天体中立
                Globals.teamPops[nodeData.team] >= Globals.teamCaps[nodeData.team] || // 飞船已达上限
                node.capturing || // 正在被占领
                node.conflict && node.ships[nodeData.team].length == 0 // 混战但无己方飞船
                );
        }

        public function get stateType():String {
            return NodeStateFactory.BUILD;
        }
    }
}
