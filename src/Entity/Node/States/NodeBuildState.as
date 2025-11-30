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

        // #region S33加的队伍判断
        public function get enable():Boolean {
            var group:int = Globals.teamGroups[nodeData.team];
            var groupShips:int = 0;
            for (var i:int = 0; i < node.ships.length; i++){
                if (i == nodeData.team || Globals.teamGroups[i] == group)
                    groupShips += node.ships[i].length;
            }
            return !(nodeData.team == 0 || Globals.teamPops[nodeData.team] >= Globals.teamCaps[nodeData.team] || node.capturing || node.conflict && groupShips == 0)
        }

        public function get stateType():String {
            return NodeStateFactory.BUILD;
        }
    }
}
