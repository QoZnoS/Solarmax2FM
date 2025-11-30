package Entity.AI {
    import utils.Rng;
    import Entity.Node;
    import Entity.Node.NodeStaticLogic;
    import Entity.Node.NodeType;
    import Entity.EntityContainer;

    public class FinalAI extends BasicAI {
        public function FinalAI(rng:Rng, actionDelay:Number, startDelay:Number) {
            super(rng, actionDelay, startDelay)
        }

        override public function update(dt:Number):void {
            if (!updateTimer(dt))
                return;
            updateFinal()
        }

        public function updateFinal():void {
            var group:int = Globals.teamGroups[team];
            var node:Node = null;
            var dx:Number = NaN;
            var dy:Number = NaN;
            var distence:Number = NaN;
            var strength:Number = NaN;
            var targetNode:Node = null;
            var senderNode:Node = null;
            var ships:Number = NaN;
            var towerAttack:Number = NaN;
            var centerX:Number = 0;
            var centerY:Number = 0;
            var nodeCount:int = 0;
            var nodeGroup:int = -1;
            for each (node in nodeArray) { // 计算己方天体几何中心
                node.getTransitShips(team);
                if (node.nodeData.team == team) {
                    centerX += node.nodeData.x;
                    centerY += node.nodeData.y;
                    nodeCount += 1;
                }
            }
            centerX /= nodeCount;
            centerY /= nodeCount;
            targets.length = 0; // 计算目标天体
            if (nodeArray[0].predictedOppStrength(team) > 0)
                targets.push(node); // 星核受威胁时将其作为唯一目标
            else {
                for each (node in nodeArray) {
                    nodeGroup = Globals.teamGroups[node.nodeData.team];
                    if (nodeGroup == group || node.nodeData.isAIinvisible)
                        continue; // 排除己方天体和障碍
                    if (node.nodeData.team == 0 && node.predictedOppStrength(team) == 0 && node.predictedGroupStrength(team) >= node.nodeData.size * 200)
                        continue; // 排除仅被己方以二倍标准兵力占据的中立天体
                    if (node.predictedOppStrength(team) > 0 && node.predictedGroupStrength(team) * 0.5 > node.predictedOppStrength(team))
                        continue; // 排除有敌方但兵力不足己方一半的天体
                    dx = node.nodeData.x - centerX;
                    dy = node.nodeData.y - centerY;
                    distence = Math.sqrt(dx * dx + dy * dy) + rng.nextNumber() * 32;
                    strength = node.predictedOppStrength(team) - node.predictedGroupStrength(team);
                    node.aiValue = distence + strength;
                    targets.push(node);
                }
                targets.sortOn("aiValue", 16);
            }
            if (targets.length > 0) {
                senders.length = 0;
                for each (node in nodeArray) { // 计算出兵天体
                    nodeGroup = Globals.teamGroups[node.nodeData.team];
                    if (node.aiTimers[team] > 0 || node.teamStrength(team) == 0)
                        continue; // 基本条件：天体AI计时器为0且有己方飞船
                    if (node.predictedOppStrength(team) == 0 && node.capturing)
                        continue; // 排除被锁星的天体
                    if (node.nodeData.type == NodeType.DILATOR && node.conflict)
                        continue; // 排除战争状态的星核
                    if (nodeGroup != group && node.predictedGroupStrength(team) > node.predictedOppStrength(team))
                        continue; // 排除敌方兵力低于己方的非己方天体
                    if (node.predictedOppStrength(team) > 0 && node.predictedGroupStrength(team) > node.predictedOppStrength(team))
                        continue; // 排除有敌方但兵力低于己方的天体
                    node.aiStrength = -node.teamStrength(team);
                    senders.push(node);
                }
                senders.sortOn("aiStrength", 16);
                for each (targetNode in targets) {
                    for each (senderNode in senders) {
                        if (senderNode == targetNode || senderNode.nodeLinks[team].indexOf(targetNode) == -1)
                            continue; // 基本条件：出兵天体和目标天体不为同一个，且二者之间没有被拦截
                        if (senderNode.teamStrength(team) + targetNode.predictedGroupStrength(team) < targetNode.predictedOppStrength(team))
                            continue; // 出兵条件：出兵天体的强度和目标天体的预测强度之和高于目标天体的预测敌方强度
                        // 飞船数：目标天体上预测敌方强度的二倍减去预测己方强度一半
                        ships = targetNode.predictedOppStrength(team) * 2 - targetNode.predictedGroupStrength(team) * 0.5;
                        if (senderNode.predictedOppStrength(team) > senderNode.predictedGroupStrength(team))
                            ships = senderNode.teamStrength(team); // 预测出兵天体敌方兵力高于己方兵力时派出全部兵力
                        if (ships < targetNode.nodeData.size * 200)
                            ships = targetNode.nodeData.size * 200; // 兵力不足目标二倍标准兵力时派出目标二倍标准兵力
                        towerAttack = EntityContainer.getLengthInTowerRange(senderNode, targetNode, team) / 4.5;
                        ships += towerAttack; // 加上估损
                        if (towerAttack > 0 && Globals.teamPops[team] < towerAttack)
                            continue; // 总兵力不足估损时不派兵
                        if (towerAttack > 0 && senderNode.teamStrength(team) < towerAttack * 0.5)
                            continue; // 出兵天体的兵力不足估损的一半时不派兵
                        if (senderNode.nodeData.type == NodeType.DILATOR)
                            NodeStaticLogic.sendAIShips(senderNode, team, targetNode, senderNode.teamStrength(team) - 150); // 星核特殊出兵机制
                        else
                            NodeStaticLogic.sendAIShips(senderNode, team, targetNode, ships);
                        return;
                    }
                }
            }
        }

        override public function get type():String {
            return EnemyAIFactory.FINAL;
        }
    }
}
