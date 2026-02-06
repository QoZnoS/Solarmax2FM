package Game.VictoryType {

    import Entity.Node;
    import Entity.Node.NodeData;
    import Entity.EntityContainer;
    import Entity.Node.NodeType;

    public class AllOccupyVictory implements IVictoryType {

        public function AllOccupyVictory(trigger:Object) {
        }

        public function update(dt:Number):int {
            var winGroup:int = Globals.teamGroups[EntityContainer.nodes[0].nodeData.team];
            for each (var node:Node in EntityContainer.nodes) {
                var nodeData:NodeData = node.nodeData;
                var nodeGroup:int = Globals.teamGroups[nodeData.team];
                if (nodeData.isUntouchable || nodeData.type == NodeType.DILATOR)
                    continue;
                if (nodeGroup != winGroup) {
                    winGroup = -1;
                    break;
                }
            }
            if (winGroup == -1) {
                winGroup = 0;
                for each (node in EntityContainer.nodes) {
                    // 验证是否仍存在飞船
                    if (node.buildState.buildRate != 0) {
                        winGroup = -1;
                        break;
                    }
                    else {
                        for (var teamId:int = 1; teamId < node.ships.length; teamId++) {
                            if (node.ships[teamId].length)
                                winGroup = -1;
                                break;
                        }
                    }
                }
            }
            return winGroup;
        }

        public function get type():String {
            return VictoryTypeFactory.ALL_OCCUPY_TYPE;
        }
    }
}
