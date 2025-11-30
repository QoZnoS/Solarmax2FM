package Game.VictoryType {
    import Entity.EntityContainer;
    import Entity.Node;
    import Entity.Node.NodeType;
    import Entity.Node.NodeData;

    public class NormalVictory implements IVictoryType {
        public function NormalVictory(trigger:Object) {
        }

        public function update(dt:Number):int {
            var winGroup:int = 0;
            // 验证仅有一个队伍有飞船
            for (var j:int = 0; j < Globals.teamCount; j++) {
                var group:int = Globals.teamGroups[j];
                if (Globals.teamPops[j] <= 0)
                    continue;
                if (winGroup == 0)
                    winGroup = group;
                else if (group != winGroup)
                    return -1;
            }
            // 验证所有天体被占据
            for each (var node:Node in EntityContainer.nodes) {
                var nodeData:NodeData = node.nodeData;
                var nodeGroup:int = Globals.teamGroups[nodeData.team];
                var groupShipNum:int = 0;
                for (var teamId:int = 0; teamId < node.ships.length; teamId++) {
                    group = Globals.teamGroups[teamId];
                    if (group == winGroup)
                        groupShipNum += node.ships[teamId].length;
                }
                if (nodeData.isUntouchable || nodeData.type == NodeType.DILATOR)
                    continue;
                if (nodeData.team == 0 || nodeGroup == winGroup)
                    continue;
                if (winGroup == 0 && node.buildState.buildRate != 0)
                    return -1;
                if (winGroup != 0 && groupShipNum == 0)
                    return -1;
            }
            return winGroup;
        }

        public function get type():String {
            return VictoryTypeFactory.NORMAL_TYPE;
        }
    }
}
