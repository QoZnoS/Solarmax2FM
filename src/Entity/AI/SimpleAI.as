package Entity.AI {
    import Entity.Node;
    import Entity.EntityContainer;
    import utils.Rng;
    import Entity.Node.NodeStaticLogic;
    import Entity.EntityContainer;

    public class SimpleAI extends BasicAI {

        public function SimpleAI(rng:Rng, actionDelay:Number, startDelay:Number) {
            super(rng, actionDelay, startDelay)
        }

        override public function update(dt:Number):void {
            if (!updateTimer(dt))
                return;
            updateSimple()
        }

        public function updateSimple():void {
            if (Globals.teamCaps[team] == 0 && Globals.teamPops[team] < 40)
                return; // 上限为0且总飞船数少于40时挂机
            var node:Node = null;
            var dx:Number = NaN;
            var dy:Number = NaN;
            var distance:Number = NaN;
            var strength:Number = NaN;
            var targetNode:Node = null;
            var senderNode:Node = null;
            var ships:int = 0;
            var nodeArray:Vector.<Node> = nodeArray;
            var centerX:Number = 0;
            var centerY:Number = 0;
            var nodeCount:int = 0;
            for each (node in nodeArray) { // 计算己方天体的几何中心
                if (node.nodeData.team != team)
                    continue;
                centerX += node.nodeData.x;
                centerY += node.nodeData.y;
                nodeCount += 1;
            }
            centerX /= nodeCount;
            centerY /= nodeCount;
            // #region 防御部分
            targets.length = 0;
            for each (node in nodeArray) { // 计算目标天体
                if (node.nodeData.isAIinvisible)
                    continue;
                node.getTransitShips(team);
                if (node.nodeData.team != team && node.predictedTeamStrength(team) == 0)
                    continue; // 条件1：为己方天体或有己方飞船（包括飞行中的
                if (node.predictedTeamStrength(team) > node.predictedOppStrength(team) * 2)
                    continue; // 条件2：预测己方强度低于敌方两倍（即可能打不过敌方
                dx = node.nodeData.x - centerX;
                dy = node.nodeData.y - centerY;
                distance = Math.sqrt(dx * dx + dy * dy); // 该天体到己方天体几何中心的距离
                strength = node.predictedTeamStrength(team) - node.predictedOppStrength(team); // 己方势力强度减去非己方势力强度
                node.aiValue = distance + strength; // 计算ai价值
                targets.push(node);
            }
            targets.sortOn("aiValue", 16); // 依ai价值从小到大对targets进行排序
            // trace("defend targets: " + targets.length);
            if (targets.length > 0) { // 目标存在时，出兵防守
                senders.length = 0;
                for each (node in nodeArray) { // 统计出兵天体
                    if (node.aiTimers[team] > 0 || node.teamStrength(team) == 0)
                        continue; // 基本条件：该天体己方ai倒计时为0且该天体己方强度不为0
                    if (node.conflict && node.predictedTeamStrength(team) > node.predictedOppStrength(team))
                        continue; // 条件：没有战争或预测己方强度低于敌方
                    node.aiStrength = -node.teamStrength(team); // 将该天体己方强度记为飞船数的相反数
                    senders.push(node);
                }
                senders.sortOn("aiStrength", 16); // 依己方强度从小到大对出兵天体进行排序（由于强度记录的是相反数，此时看绝对值则是从大到小
                // trace("defend senders: " + senders.length);
                for each (targetNode in targets) { // 防守判定
                    for each (senderNode in senders) {
                        if (senderNode == targetNode || EntityContainer.nodesBlocked(senderNode, targetNode))
                            continue; // 基本条件：出兵天体和目标天体不为同一个，且二者之间没有被拦截
                        if (senderNode.teamStrength(team) + targetNode.predictedTeamStrength(team) <= targetNode.predictedOppStrength(team))
                            continue; // 出兵条件：出兵天体的强度和目标天体的预测强度之和高于目标天体的预测敌方强度
                        // 飞船数：目标天体上预测敌方强度的二倍减去预测己方强度
                        ships = targetNode.predictedOppStrength(team) * 2 - targetNode.predictedTeamStrength(team);
                        NodeStaticLogic.sendAIShips(senderNode, team, targetNode, ships); // 发送飞船
                        // trace("defending!");
                        return; // 终止此次ai行动
                    }
                }
            }
            // trace("can't defend, or nothing to defend");
            // #endregion
            // #region 进攻部分
            targets.length = 0;
            for each (node in nodeArray) { // 计算目标天体
                if (node.nodeData.team == team || node.nodeData.isAIinvisible)
                    continue;
                if (node.nodeData.team == 0 && node.predictedOppStrength(team) == 0 && node.predictedTeamStrength(team) > node.nodeData.size * 100)
                    continue; // 目标条件：不为中立或预测有非己方飞船或己方势力飞船不足100倍size（基本兵力上限）
                dx = node.nodeData.x - centerX;
                dy = node.nodeData.y - centerY;
                distance = Math.sqrt(dx * dx + dy * dy) + rng.nextNumber() * 32; // 计算距离，带32px随机数误差
                strength = node.predictedOppStrength(team) - node.predictedTeamStrength(team); // 计算敌方强度：预测敌方强度减去预测己方强度
                node.aiValue = distance + strength; // 计算ai价值：距离加上敌方强度
                targets.push(node);
            }
            targets.sortOn("aiValue", 16); // 依ai价值从小到大对targets进行排序
            // trace("attack targets: " + targets.length);
            // trace("teamStr: " + targets[0].predictedTeamStrength(team));
            if (targets.length > 0) { // 目标存在时，出兵进攻
                senders.length = 0;
                for each (node in nodeArray) { // 统计出兵天体
                    if (node.aiTimers[team] > 0 || node.teamStrength(team) == 0)
                        continue; // 基本条件：该天体己方ai倒计时为0且该天体己方强度不为0
                    if (node.conflict && node.predictedTeamStrength(team) > node.predictedOppStrength(team))
                        continue; // 出兵条件：天体上没有战争或预测敌方强度高于预测己方强度
                    node.aiStrength = -node.teamStrength(team); // 将该天体己方强度记为飞船数的相反数
                    senders.push(node);
                }
                senders.sortOn("aiStrength", 16); // 依己方强度从小到大对出兵天体进行排序（由于强度记录的是相反数，此时看绝对值则是从大到小
                // trace("attack senders: " + senders.length);
                for each (targetNode in targets) { // 进攻判定
                    for each (senderNode in senders) {
                        if (senderNode == targetNode || EntityContainer.nodesBlocked(senderNode, targetNode))
                            continue; // 基本条件：出兵天体和目标天体不为同一个，且二者之间没有被拦截
                        if (senderNode.teamStrength(team) + targetNode.predictedTeamStrength(team) <= targetNode.predictedOppStrength(team))
                            continue; // 出兵条件：出兵天体的强度和目标天体的预测强度之和高于目标天体的预测敌方强度
                        // 计算出兵兵力，默认为预测目标天体上敌方兵力的二倍与己方兵力一半的差值
                        ships = targetNode.predictedOppStrength(team) * 2 - targetNode.predictedTeamStrength(team) * 0.5;
                        if (targetNode.predictedOppStrength(team) * 2 - targetNode.predictedTeamStrength(team) * 0.5 < targetNode.nodeData.size * 200)
                            ships = targetNode.nodeData.size * 200; // 若出兵兵力不足二倍目标天体标准兵力，则增加至二倍目标天体标准兵力
                        if (senderNode.predictedOppStrength(team) > senderNode.predictedTeamStrength(team))
                            ships = senderNode.teamStrength(team); // 若预测出兵天体所受敌方威胁高于其强度，则派出全部兵力
                        NodeStaticLogic.sendAIShips(senderNode, team, targetNode, ships);
                        // trace("attacking!");
                        return;
                    }
                }
            }
            // #endregion
        }

        override public function get type():String {
            return EnemyAIFactory.SIMPLE;
        }
    }
}
