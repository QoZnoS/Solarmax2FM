package Entity.AI {
    import utils.Rng;
    import Entity.Node;
    import Entity.EntityContainer;
    import Entity.Node.NodeStaticLogic;
    import Entity.Node.NodeType;
    import Entity.EntityContainer;

    public class SmartAI extends BasicAI {
        public function SmartAI(rng:Rng, actionDelay:Number, startDelay:Number) {
            super(rng, actionDelay, startDelay)
        }

        override public function update(dt:Number):void {
            if (!updateTimer(dt))
                return;
            updateSmart()
        }

        public function updateSmart():void {
            if (Globals.teamCaps[team] == 0 && Globals.teamPops[team] < 40)
                return; // 上限为0且总飞船数少于40时挂机
            var node:Node = null;
            var dx:Number = NaN;
            var dy:Number = NaN;
            var distence:Number = NaN;
            var strength:Number = NaN;
            var targetNode:Node = null;
            var senderNode:Node = null;
            var ships:int = 0;
            var towerAttack:Number = NaN;
            var centerX:Number = 0;
            var centerY:Number = 0;
            var nodeCount:int = 0;
            var nodeGroup:int = -1;
            for each (node in nodeArray) {
                node.getTransitShips(team);
                if (node.nodeData.team == team) {
                    centerX += node.nodeData.x;
                    centerY += node.nodeData.y;
                    nodeCount += 1;
                }
            }
            centerX /= nodeCount;
            centerY /= nodeCount;
            // #region 防御
            targets.length = 0;
            for each (node in nodeArray) { // 计算目标天体
                nodeGroup = Globals.teamGroups[node.nodeData.team];
                if (node.nodeData.type == NodeType.DILATOR && node.teamStrength(team) > 0) {
                    node.unloadShips();
                    return;
                }
                if (node.nodeData.isAIinvisible)
                    continue;
                if (nodeGroup != group && node.predictedGroupStrength(team) == 0)
                    continue; // 条件1：为己方天体或有己方飞船（包括飞行中的）
                if (node.predictedOppStrength(team) == 0)
                    continue; // 条件2：有敌方
                if (node.predictedGroupStrength(team) > node.predictedOppStrength(team) * 2)
                    continue; // 条件3：预测己方强度低于敌方两倍（即可能打不过敌方
                dx = node.nodeData.x - centerX;
                dy = node.nodeData.y - centerY;
                distence = Math.sqrt(dx * dx + dy * dy) + rng.nextNumber() * 32;
                strength = node.predictedGroupStrength(team) - node.predictedOppStrength(team);
                node.aiValue = distence + strength;
                targets.push(node);
            }
            targets.sortOn("aiValue", 16); // 依ai价值从小到大对targets进行排序
            if (targets.length > 0) { // 目标天体存在时
                senders.length = 0;
                for each (node in nodeArray) { // 计算出兵天体
                    nodeGroup = Globals.teamGroups[node.nodeData.team];
                    if (node.nodeData.isAIinvisible)
                        continue;
                    if (node.aiTimers[team] > 0 || node.teamStrength(team) == 0)
                        continue; // 基本条件：该天体己方ai倒计时为0且该天体己方强度不为0
                    if (nodeGroup != group && node.predictedGroupStrength(team) > node.predictedOppStrength(team))
                        continue; // 条件：是己方天体或预测己方强度低于敌方
                    if (node.predictedOppStrength(team) > 0 && node.predictedGroupStrength(team) > node.predictedOppStrength(team))
                        continue; // 条件：没有敌方或预测己方强度低于敌方
                    node.aiStrength = -node.groupStrength(team); // 将该天体己方强度记为飞船数的相反数
                    senders.push(node);
                }
                senders.sortOn("aiStrength", 16); // 依己方强度从小到大对出兵天体进行排序（由于强度记录的是相反数，此时看绝对值则是从大到小
                for each (targetNode in targets) {
                    for each (senderNode in senders) {
                        if (senderNode == targetNode || senderNode.nodeLinks[team].indexOf(targetNode) == -1)
                            continue; // 基本条件：出兵天体和目标天体不为同一个，且二者之间没有被拦截
                        if (senderNode.teamStrength(team) + targetNode.predictedGroupStrength(team) < targetNode.predictedOppStrength(team))
                            continue; // 出兵条件：出兵天体的强度和目标天体的预测强度之和高于目标天体的预测敌方强度
                        // 飞船数：目标天体上预测敌方强度的二倍减去预测己方强度
                        ships = targetNode.predictedOppStrength(team) * 2 - targetNode.predictedGroupStrength(team);
                        towerAttack = EntityContainer.getLengthInTowerRange(senderNode, targetNode, team) / 4.5; // 估算经过攻击天体损失的兵力（估损
                        ships += towerAttack; // 为飞船数加上估损
                        if (towerAttack > 0 && Globals.teamPops[team] < towerAttack)
                            continue; // 条件：没有经过攻击天体或总兵力多于估损
                        if (towerAttack > 0 && senderNode.teamStrength(team) < towerAttack * 0.5)
                            continue; // 条件：没有经过攻击天体或出兵天体强度高于估损的一半
                        // if (Globals.level == 34 && targetNode.x == 912 && targetNode.y == 544)
                        // trace("defending");
                        // traceDebug("defending       " + senderNode.x + "." + senderNode.y + "  to  " + targetNode.x + "." + targetNode.y + "  ships:  " + ships);
                        NodeStaticLogic.sendAIShips(senderNode, team, targetNode, ships);
                        return;
                    }
                }
            }
            // #endregion
            // #region 进攻
            targets.length = 0;
            for each (node in nodeArray) { // 计算目标天体
                nodeGroup = Globals.teamGroups[node.nodeData.team];
                if (nodeGroup == group || node.nodeData.isAIinvisible)
                    continue;
                if (node.predictedOppStrength(team) == 0 && node.predictedGroupStrength(team) > node.nodeData.size * 150)
                    continue; // 条件：排除己方强度足够且无敌方的天体
                dx = node.nodeData.x - centerX;
                dy = node.nodeData.y - centerY;
                distence = Math.sqrt(dx * dx + dy * dy) + rng.nextNumber() * 32;
                strength = node.predictedOppStrength(team) - node.predictedGroupStrength(team);
                node.aiValue = distence + strength;
                targets.push(node);
            }
            targets.sortOn("aiValue", 16);
            if (targets.length > 0) {
                senders.length = 0;
                for each (node in nodeArray) { // 计算出兵天体
                    nodeGroup = Globals.teamGroups[node.nodeData.team];
                    if (node.nodeData.isAIinvisible)
                        continue;
                    if (node.aiTimers[team] > 0 || node.teamStrength(team) == 0)
                        continue; // 基本条件：该天体己方ai倒计时为0且该天体己方强度不为0
                    if (node.predictedOppStrength(team) == 0 && node.capturing)
                        continue; // 条件：天体不被己方占据
                    if (nodeGroup != group && node.predictedGroupStrength(team) > node.predictedOppStrength(team))
                        continue; // 条件：是己方天体或预测己方强度低于敌方
                    if (node.predictedOppStrength(team) > 0 && node.predictedGroupStrength(team) > node.predictedOppStrength(team))
                        continue; // 条件：没有敌方或预测己方强度低于敌方
                    node.aiStrength = -node.groupStrength(team);
                    senders.push(node);
                }
                senders.sortOn("aiStrength", 16);
                for each (targetNode in targets) {
                    for each (senderNode in senders) {
                        if (senderNode == targetNode || senderNode.nodeLinks[team].indexOf(targetNode) == -1)
                            continue; // 基本条件：出兵天体和目标天体不为同一个，且二者之间没有被拦截
                        if (senderNode.teamStrength(team) + targetNode.predictedGroupStrength(team) <= targetNode.predictedOppStrength(team))
                            continue; // 出兵条件：出兵天体和目标天体的己方综合强度高于目标天体的预测敌方强度
                        // 基本飞船数：目标天体上预测敌方强度的二倍减去预测己方强度一半
                        ships = targetNode.predictedOppStrength(team) * 2 - targetNode.predictedGroupStrength(team) * 0.5;
                        if (senderNode.predictedOppStrength(team) > senderNode.predictedGroupStrength(team))
                            ships = senderNode.teamStrength(team); // 预测敌方强度大于己方时，派出全部飞船
                        if (ships < targetNode.nodeData.size * 200)
                            ships = targetNode.nodeData.size * 200; // 飞船数不应低于目标的二倍标准兵力
                        towerAttack = EntityContainer.getLengthInTowerRange(senderNode, targetNode, team) / 4.5; // 计算估损
                        ships += towerAttack; // 为飞船数加上估损
                        if (towerAttack > 0 && Globals.teamPops[team] < towerAttack)
                            continue; // 总兵力不足估损时不派兵
                        if (Globals.level == 31)
                            if (towerAttack > 0 && senderNode.teamStrength(team) < towerAttack * 2)
                                continue; // 32关兵力不足估损二倍时换个目标
                        if (towerAttack > 0 && senderNode.teamStrength(team) < towerAttack * 0.5)
                            continue; // 出兵天体强度低于估损的一半时不派兵
                        // if (Globals.level == 34 && targetNode.x == 912 && targetNode.y == 544)
                        // trace("attacking");
                        // traceDebug("attacking       " + senderNode.x + "." + senderNode.y + "  to  " + targetNode.x + "." + targetNode.y + "  ships:  " + ships);
                        NodeStaticLogic.sendAIShips(senderNode, team, targetNode, ships);
                        return;
                    }
                }
            }
            // #endregion
            // #region 聚兵
            senders.length = 0;
            for each (node in nodeArray) { // 计算出兵天体
                nodeGroup = Globals.teamGroups[node.nodeData.team];
                if (node.nodeData.isAIinvisible)
                    continue;
                if (nodeGroup != group && node.predictedOppStrength(team) == 0 && node.groupStrength(team) > 0)
                    continue; // 条件：没在锁星
                if (node.predictedOppStrength(team) > 0 && node.predictedGroupStrength(team) > node.predictedOppStrength(team))
                    continue; // 条件：无敌方或打不过敌方
                node.aiStrength = -node.teamStrength(team) - node.oppStrength(team); // 计算己方和最强方的飞船总数
                node.aiValue = -node.oppNodeLinks.length; // 按路径数计算价值
                if (node.nodeData.isWarp)
                    node.aiValue--; // 传送权重提高
                senders.push(node);
            }
            senders.sortOn("aiStrength", 16); // 依飞船强度从小到大对出兵天体进行排序
            if (senders.length > 0) {
                targets.length = 0;
                for each (node in nodeArray) { // 计算目标天体
                    if (node.nodeData.isAIinvisible)
                        continue;
                    node.getOppLinks(team);
                    node.aiValue = -node.oppNodeLinks.length; // 按路径数计算价值
                    if (node.nodeData.isWarp)
                        node.aiValue--; // 传送权重提高
                    if (Globals.level == 31 && node.nodeData.type == NodeType.STARBASE)
                        node.aiValue--; // 32关堡垒权重提高
                    targets.push(node);
                }
                targets.sortOn("aiValue", 16);
                for each (targetNode in targets) {
                    for each (senderNode in senders) {
                        if (senderNode == targetNode || senderNode.nodeLinks[team].indexOf(targetNode) == -1)
                            continue; // 基本条件：出兵天体和目标天体不为同一个，且二者之间没有被拦截
                        if (targetNode.aiValue >= senderNode.aiValue)
                            continue; // 条件：目标天体价值高于出兵天体价值
                        ships = senderNode.teamStrength(team); // 派出全部飞船
                        towerAttack = EntityContainer.getLengthInTowerRange(senderNode, targetNode, team) / 4.5;
                        ships += towerAttack; // 为飞船数加上估损
                        if (towerAttack > 0 && Globals.teamPops[team] < towerAttack)
                            continue; // 条件：总兵力不足估损时不派兵
                        if (Globals.level == 31)
                            if (towerAttack > 0 && senderNode.teamStrength(team) < towerAttack * 3)
                                continue; // 32关兵力不足估损三倍时换个目标
                        if (towerAttack > 0 && senderNode.teamStrength(team) < towerAttack * 0.5)
                            continue; // 出兵天体强度低于估损的一半时不派兵
                        // if (Globals.level == 34 && targetNode.x == 912 && targetNode.y == 544)
                        // trace("repositioning");
                        // if (ships != 0)
                        //     traceDebug("repositioning   " + senderNode.x + "." + senderNode.y + "  to  " + targetNode.x + "." + targetNode.y + "  ships:  " + ships);
                        NodeStaticLogic.sendAIShips(senderNode, team, targetNode, ships);
                        return;
                    }
                }
            }
            // #endregion
        }

        override public function get type():String {
            return EnemyAIFactory.SMART;
        }
    }
}
