package Entity.AI {
    import utils.Rng;
    import Entity.Node;
    import Entity.Node.NodeStaticLogic;
    import Entity.Node.NodeType;
    import Entity.EntityContainer;

    public class DarkAI extends BasicAI {
        public function DarkAI(rng:Rng, actionDelay:Number, startDelay:Number) {
            super(rng, actionDelay, startDelay)
        }

        override public function update(dt:Number):void {
            if (!updateTimer(dt))
                return;
            updateDark()
        }

        public function updateDark():void {
            if (Globals.teamCaps[team] == 0 && Globals.teamPops[team] < 40)
                return; // 上限为0且总飞船数少于40时挂机
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
            for each (node in nodeArray) { // 计算己方天体的几何中心
                node.getTransitShips(team);
                if (node.nodeData.team != team)
                    continue;
                centerX += node.nodeData.x;
                centerY += node.nodeData.y;
                nodeCount += 1;
            }
            centerX /= nodeCount;
            centerY /= nodeCount;
            for each (node in nodeArray) { // 分散星核兵力
                if (team == 6 && node.nodeData.type == NodeType.DILATOR && node.teamStrength(team) > 0) {
                    node.unloadShips();
                    return;
                }
            }
            // #region 进攻
            targets.length = 0;
            for each (node in nodeArray) { // 计算目标天体
                if (node.nodeData.team == team || node.nodeData.isAIinvisible)
                    continue;
                if (node.predictedOppStrength(team) == 0 && node.predictedTeamStrength(team) > node.nodeData.size * 200)
                    continue; // 条件1：天体未被己方以二倍标准兵力占据
                if (node.predictedOppStrength(team) > 0 && node.predictedTeamStrength(team) * 0.5 > node.predictedOppStrength(team))
                    continue; // 条件2：敌方无兵力或高于己方兵力一半
                dx = node.nodeData.x - centerX;
                dy = node.nodeData.y - centerY;
                distence = Math.sqrt(dx * dx + dy * dy) + rng.nextNumber() * 32;
                strength = node.predictedOppStrength(team) - node.predictedTeamStrength(team);
                node.aiValue = distence + strength;
                targets.push(node);
            }
            targets.sortOn("aiValue", 16);
            if (targets.length > 0) {
                senders.length = 0;
                for each (node in nodeArray) { // 计算出兵天体
                    if (node.aiTimers[team] > 0 || node.teamStrength(team) == 0)
                        continue; // 基本条件：天体AI计时器为0且有己方飞船
                    if (node.predictedOppStrength(team) == 0 && node.capturing)
                        continue; // 条件1：没在锁星
                    if (node.nodeData.team != team && node.predictedTeamStrength(team) > node.predictedOppStrength(team))
                        continue; // 条件2：为己方天体或己方兵力不足敌方
                    if (node.predictedOppStrength(team) > 0 && node.predictedTeamStrength(team) > node.predictedOppStrength(team))
                        continue; // 条件3：敌方无兵力或己方兵力不足敌方
                    node.aiStrength = -node.teamStrength(team);
                    senders.push(node);
                }
                senders.sortOn("aiStrength", 16);
                for each (targetNode in targets) {
                    for each (senderNode in senders) {
                        if (senderNode == targetNode || senderNode.nodeLinks[team].indexOf(targetNode) == -1)
                            continue; // 基本条件：出兵天体和目标天体不为同一个，且二者之间没有被拦截
                        if (senderNode.teamStrength(team) + targetNode.predictedTeamStrength(team) < targetNode.predictedOppStrength(team))
                            continue; // 出兵条件：出兵天体的强度和目标天体的预测强度之和高于目标天体的预测敌方强度
                        // 飞船数：目标天体上预测敌方强度的二倍减去预测己方强度一半
                        ships = targetNode.predictedOppStrength(team) * 2 - targetNode.predictedTeamStrength(team) * 0.5;
                        if (senderNode.predictedOppStrength(team) > senderNode.predictedTeamStrength(team))
                            ships = senderNode.teamStrength(team); // 预测出兵天体敌方兵力高于己方兵力时派出全部兵力
                        if (ships < targetNode.nodeData.size * 200)
                            ships = targetNode.nodeData.size * 200; // 兵力不足目标二倍标准兵力时派出目标二倍标准兵力
                        towerAttack = EntityContainer.getLengthInTowerRange(senderNode, targetNode, team) / 4.5;
                        ships += towerAttack; // 加上估损
                        if (towerAttack > 0 && Globals.teamPops[team] < towerAttack)
                            continue; // 总兵力不足估损时不派兵
                        if (towerAttack > 0 && senderNode.teamStrength(team) < towerAttack * 0.5)
                            continue; // 出兵天体的兵力不足估损的一半时不派兵
                        NodeStaticLogic.sendAIShips(senderNode, team, targetNode, ships);
                        return;
                    }
                }
            }
            // #endregion
            // #region 聚兵
            senders.length = 0;
            for each (node in nodeArray) { // 计算出兵天体
                if (node.nodeData.team != team || node.conflict || node.teamStrength(team) == 0)
                    continue; // 条件：为己方天体且无战争
                node.aiValue = -node.teamStrength(team);
                senders.push(node);
            }
            senders.sortOn("aiValue", 16);
            if (senders.length > 0) {
                targets.length = 0;
                for each (node in nodeArray) { // 计算目标天体
                    if (node.nodeData.isAIinvisible)
                        continue;
                    node.getOppLinks(team);
                    node.aiValue = -node.oppNodeLinks.length; // 按路径数计算价值
                    if (node.nodeData.isWarp)
                        node.aiValue--; // 提高传送权重
                    if (Globals.level == 31 && node.nodeData.type == NodeType.STARBASE)
                        node.aiValue--; // 32关堡垒权重提高
                    targets.push(node);
                }
                targets.sortOn("aiValue", 16);
                for each (senderNode in senders) {
                    for each (targetNode in targets) {
                        if (senderNode == targetNode || senderNode.nodeLinks[team].indexOf(targetNode) == -1)
                            continue; // 基本条件：出兵天体和目标天体不为同一个，且二者之间没有被拦截
                        if (targetNode.aiValue >= senderNode.aiValue)
                            continue; // 条件：目标天体价值高于出兵天体价值
                        ships = senderNode.teamStrength(team); // 派出该天体全部兵力
                        towerAttack = EntityContainer.getLengthInTowerRange(senderNode, targetNode, team) / 4.5;
                        ships += towerAttack; // 加上估损
                        if (towerAttack > 0 && Globals.teamPops[team] < towerAttack)
                            continue; // 总兵力不足估损时不派兵
                        if (towerAttack > 0 && senderNode.teamStrength(team) < towerAttack * 0.5)
                            continue; // 出兵天体的兵力不足估损的一半时不派兵
                        NodeStaticLogic.sendAIShips(senderNode, team, targetNode, ships);
                        return;
                    }
                }
            }
            // #endregion
        }

        override public function get type():String {
            return EnemyAIFactory.DARK;
        }
    }
}
