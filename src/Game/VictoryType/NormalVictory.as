package Game.VictoryType {
    import Entity.EntityContainer;
    import Entity.Node;
    import Entity.Node.NodeType;
    import Entity.Node.NodeData;

    public class NormalVictory implements IVictoryType {
        public function NormalVictory(trigger:Object) {
        }

        public function update(dt:Number):int {
            var winTeam:int = 0;
            // 验证仅有一方势力有飞船
            for (var j:int = 0; j < Globals.teamCount; j++) {
                if (Globals.teamPops[j] <= 0)
                    continue;
                if (winTeam == 0)
                    winTeam = j;
                else
                    return -1;
            }
            // 验证所有天体被占据
            for each (var node:Node in EntityContainer.nodes) {
                var nodeData:NodeData = node.nodeData;
                if (nodeData.type == NodeType.BARRIER || nodeData.type == NodeType.DILATOR)
                    continue;
                if (nodeData.team == 0 || nodeData.team == winTeam)
                    continue;
                if (winTeam == 0 && node.buildState.buildRate != 0)
                    return -1;
                if (winTeam != 0 && node.ships[winTeam].length == 0)
                    return -1;
            }
            return winTeam;
        }

        public function get type():String {
            return VictoryTypeFactory.NORMAL_TYPE;
        }
    }
}
