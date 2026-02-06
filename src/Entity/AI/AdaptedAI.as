package Entity.AI {
    import utils.Rng;
    import Entity.Node;
    import Entity.EntityContainer;
    import Entity.Node.NodeStaticLogic;
    import Entity.Node.NodeType;
    import Entity.EntityContainer;
    import utils.GeneralFunctions;

    public class AdaptedAI extends BasicAI {
        public function AdaptedAI(rng:Rng, actionDelay:Number, startDelay:Number) {
            super(rng, actionDelay, startDelay)
        }

        override public function update(dt:Number):void {
            if (!updateTimer(dt))
                return;
            updateAdapted()
        }

        public function updateAdapted():void {
            if (Globals.teamCaps[team] == 0 && Globals.teamPops[team] < 40)
                return; // 上限为0且总飞船数少于40时挂机
            var node:Node = null;
            var dx:Number = NaN;
            var dy:Number = NaN;
            var distance:Number = NaN;
            var risk:Number = NaN;
            var invalidActions:Vector.<String> = new Vector.<String>;
            var targetNode:Node = null;
            var senderNode:Node = null;
            var ships:int = 0;
            var towerAttack:Number = NaN;
            var centerX:Number = 0;
            var centerY:Number = 0;
            var nodeCount:int = 0;
            var nodeGroup:int = -1;
            var shipStrength:Number = Globals.teamShipAttacks[team] * Globals.teamShipDefences[team]; //单体强度
            var shipSpeed:Number = Globals.teamShipSpeeds[team] / 50; //单体速度
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
            if (!centerX && centerX != 0) {
                centerX = 512;
                centerY = 384;
            }
            // #region 防御
            targets.length = 0;
            for each (node in nodeArray) { // 计算目标天体
                nodeGroup = Globals.teamGroups[node.nodeData.team];
                if (node.nodeData.type == NodeType.DILATOR && node.teamShipCount(team) > 0) {
                    node.unloadShips();
                    return;
                }
                if (node.nodeData.isAIinvisible)
                    continue;
                if (nodeGroup != group && node.predictedGroupShipCount(team) == 0)
                    continue; // 条件1：为己方天体或有己方飞船（包括飞行中的）
                if (node.predictedOppShipCount(team) == 0)
                    continue; // 条件2：有敌方
                if (node.predictedGroupStrength(team) > node.predictedOppStrength(team) * 2)
                    continue; // 条件3：预测己方强度低于敌方两倍（即可能打不过敌方
                dx = node.nodeData.x - centerX;
                dy = node.nodeData.y - centerY;
                distance = Math.sqrt(dx * dx + dy * dy) + rng.nextNumber() * 32;
                risk = node.predictedGroupStrength(team) - node.predictedOppCaptureRisk(team);
                node.aiValue = distance + risk;
                targets.push(node);
            }
            // targets.sortOn("aiValue", 16); // 依ai价值从小到大对targets进行排序
            if (targets.length > 0) { // 目标天体存在时
                senders.length = 0;
                for each (node in nodeArray) { // 计算出兵天体
                    nodeGroup = Globals.teamGroups[node.nodeData.team];
                    if (node.nodeData.isAIinvisible)
                        continue;
                    if (node.aiTimers[team] > 0 || node.teamShipCount(team) == 0)
                        continue; // 基本条件：该天体己方ai倒计时为0且该天体己方强度不为0
                    if (nodeGroup != group && node.predictedGroupStrength(team) > node.predictedOppStrength(team))
                        continue; // 条件：是己方天体或预测己方强度低于敌方
                    if (node.predictedOppShipCount(team) > 0 && node.predictedGroupStrength(team) > node.predictedOppStrength(team))
                        continue; // 条件：没有敌方或预测己方强度低于敌方
                    node.aiStrength = -node.groupStrength(team); // 将该天体己方强度记为己方船数的相反数
                    if (EntityContainer.inAttackNodeCheck(node, team, NodeType.PULSECANNON, true)) {
                        if (node.aiStrength > 0)
                            node.aiStrength /= 10;
                        else
                            node.aiStrength *= 10;
                    }
                    senders.push(node);
                }
                // senders.sortOn("aiStrength", 16); // 依己方强度从小到大对出兵天体进行排序（由于强度记录的是相反数，此时看绝对值则是从大到小
                invalidActions.length = 0;
                while (targets.length > 0 && senders.length > 0) {
                    if (invalidActions.length >= GeneralFunctions.getMinCount(targets, "aiValue") * GeneralFunctions.getMinCount(senders, "aiStrength")) {
                        invalidActions.length = 0;
                        targets = GeneralFunctions.popMinValues(targets, "aiValue", GeneralFunctions.getMinCount(targets, "aiValue"));
                        senders = GeneralFunctions.popMinValues(senders, "aiStrength", GeneralFunctions.getMinCount(targets, "aiStrength"));
                    }
                    targetNode = GeneralFunctions.getRandomMinByProperty(rng, targets, "aiValue") as Node; // 随机选择一个aiValue最小的目标
                    senderNode = GeneralFunctions.getRandomMinByProperty(rng, senders, "aiStrength") as Node; // 随机选择一个aiStrength最小的出兵天体
                    if (targetNode && senderNode) {
                        if (invalidActions.indexOf(senderNode.tag + "," + targetNode.tag) == -1) // 检查是否是已经尝试过的操作
                            invalidActions.push(senderNode.tag + "," + targetNode.tag); // 宣布操作已经尝试过
                        else
                            continue;
                        if (senderNode == targetNode || senderNode.nodeLinks[team].indexOf(targetNode) == -1) {
                            trace("\"Try defending.\" team: " + team + " sender: " + senderNode.tag + " target: " + targetNode.tag + " but failed: THE_SAME_ONE_OR_BLOCKED");
                            continue; // 基本条件：出兵天体和目标天体不为同一个，且二者之间没有被拦截
                        }
                        if (senderNode.teamStrength(team) + targetNode.predictedGroupStrength(team) < targetNode.predictedOppStrength(team)) {
                            trace("\"Try defending.\" team: " + team + " sender: " + senderNode.tag + " target: " + targetNode.tag + " but failed: TOO_WEAK");
                            continue; // 出兵条件：出兵天体的强度和目标天体的预测强度之和高于目标天体的预测敌方强度
                        }
                        if (!senderNode.nodeData.isWarp && EntityContainer.isInBlackhole(senderNode, targetNode, team)) {
                            trace("\"Try defending.\" team: " + team + " sender: " + senderNode.tag + " target: " + targetNode.tag + " but failed: DANGEROUS_BLACKHOLE");
                            continue; // 路径上无有威胁的黑洞
                        }
                        // 飞船数：目标天体上预测敌方强度的二倍减去预测己方强度与己方单体强度之商
                        ships = (targetNode.predictedOppShipCount(team) * 2 - targetNode.predictedGroupShipCount(team)) / shipStrength;
                        towerAttack = EntityContainer.getLengthInTowerRange(senderNode, targetNode, team) / 4.5 / shipSpeed; // 估算经过攻击天体损失的兵力（估损
                        ships += Math.max(towerAttack, 0); // 为飞船数加上估损
                        if (towerAttack > 0 && Globals.teamPops[team] < towerAttack) {
                            trace("\"Try defending.\" team: " + team + " sender: " + senderNode.tag + " target: " + targetNode.tag + " but failed: FATAL_TOWER_COST");
                            continue; // 条件：没有经过攻击天体或总兵力多于估损
                        }
                        if (towerAttack > 0 && senderNode.teamShipCount(team) < towerAttack * 0.5) {
                            trace("\"Try defending.\" team: " + team + " sender: " + senderNode.tag + " target: " + targetNode.tag + " but failed: DANGEROUS_TOWER_COST");
                            continue; // 条件：没有经过攻击天体或出兵天体强度高于估损的一半
                        }
                        // if (Globals.level == 34 && targetNode.x == 912 && targetNode.y == 544)
                        // trace("defending");
                        // traceDebug("defending       " + senderNode.x + "." + senderNode.y + "  to  " + targetNode.x + "." + targetNode.y + "  ships:  " + ships);
                        trace("\"Defending!\" team: " + team + " sender: " + senderNode.tag + " target: " + targetNode.tag + " ships: " + ships + " towerAttack: " + towerAttack);
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
                if (nodeGroup == group && ((node.nodeData.type != NodeType.DIFFUSION || node.predictedTeamShipCount(team) > (Globals.teamCaps[team] - Globals.teamPops[team]) / 3) || Globals.teamPops[team] >= Globals.teamCaps[team]) || node.nodeData.isAIinvisible)
                    continue; // 己方少兵扩散应纳入考虑范围
                if (node.predictedOppShipCount(team) == 0 && node.predictedGroupShipCount(team) > node.nodeData.size * 150)
                    continue; // 条件：排除己方船数足够且无敌方的天体
                dx = node.nodeData.x - centerX;
                dy = node.nodeData.y - centerY;
                distance = Math.sqrt(dx * dx + dy * dy) + rng.nextNumber() * 32;
                risk = node.predictedOppStrength(team) - node.predictedGroupStrength(team);
                node.aiValue = distance + risk;
                //trace(node.tag);
                //trace(EntityContainer.inAttackNodeCheck(node, team, NodeType.PULSECANNON, true));
                if (EntityContainer.inAttackNodeCheck(node, team, NodeType.PULSECANNON, true)) {
                    if (node.aiValue > 0)
                        node.aiValue *= 10;
                    else
                        node.aiValue /= 10;
                }
                targets.push(node);
            }
            // targets.sortOn("aiValue", 16);
            if (targets.length > 0) {
                senders.length = 0;
                for each (node in nodeArray) { // 计算出兵天体
                    nodeGroup = Globals.teamGroups[node.nodeData.team];
                    if (node.nodeData.isAIinvisible)
                        continue;
                    if (node.aiTimers[team] > 0 || node.teamShipCount(team) == 0)
                        continue; // 基本条件：该天体己方ai倒计时为0且该天体己方强度不为0
                    if (node.predictedOppShipCount(team) == 0 && node.capturing)
                        continue; // 条件：天体不被己方占据
                    if (nodeGroup != group && node.predictedGroupStrength(team) > node.predictedOppStrength(team))
                        continue; // 条件：是己方天体或预测己方强度低于敌方
                    if (node.predictedOppShipCount(team) > 0 && node.predictedGroupStrength(team) > node.predictedOppStrength(team))
                        continue; // 条件：没有敌方或预测己方强度低于敌方
                    node.aiStrength = -node.groupStrength(team);
                    if (EntityContainer.inAttackNodeCheck(node, team, NodeType.PULSECANNON, true)) {
                        if (node.aiStrength > 0)
                            node.aiStrength /= 10;
                        else
                            node.aiStrength *= 10;
                    }
                    senders.push(node);
                }
                // senders.sortOn("aiStrength", 16);
                invalidActions.length = 0;
                while (targets.length > 0 && senders.length > 0) {
                    if (invalidActions.length >= GeneralFunctions.getMinCount(targets, "aiValue") * GeneralFunctions.getMinCount(senders, "aiStrength")) {
                        invalidActions.length = 0;
                        targets = GeneralFunctions.popMinValues(targets, "aiValue", GeneralFunctions.getMinCount(targets, "aiValue"));
                        senders = GeneralFunctions.popMinValues(senders, "aiStrength", GeneralFunctions.getMinCount(targets, "aiStrength"));
                    }
                    targetNode = GeneralFunctions.getRandomMinByProperty(rng, targets, "aiValue") as Node; // 随机选择一个aiValue最小的目标
                    senderNode = GeneralFunctions.getRandomMinByProperty(rng, senders, "aiStrength") as Node; // 随机选择一个aiStrength最小的出兵天体
                    if (targetNode && senderNode) {
                        if (invalidActions.indexOf(senderNode.tag + "," + targetNode.tag) == -1) // 检查是否是已经尝试过的操作
                            invalidActions.push(senderNode.tag + "," + targetNode.tag); // 宣布操作已经尝试过
                        else
                            continue;
                        if (senderNode == targetNode || senderNode.nodeLinks[team].indexOf(targetNode) == -1) {
                            trace("\"Try attacking.\" team: " + team + " sender: " + senderNode.tag + " target: " + targetNode.tag + " but failed: THE_SAME_ONE_OR_BLOCKED");
                            continue; // 基本条件：出兵天体和目标天体不为同一个，且二者之间没有被拦截
                        }
                        if (senderNode.teamStrength(team) + targetNode.predictedGroupStrength(team) <= targetNode.predictedOppStrength(team)) {
                            trace("\"Try attacking.\" team: " + team + " sender: " + senderNode.tag + " target: " + targetNode.tag + " but failed: TOO_WEAK");
                            continue; // 出兵条件：出兵天体和目标天体的己方综合强度高于目标天体的预测敌方强度
                        }
                        //trace(team + ": [" + senderNode.tag + ", " + targetNode.tag + ", " + EntityContainer.isInBlackhole(senderNode, targetNode, team) + "]");
                        if (!senderNode.nodeData.isWarp && EntityContainer.isInBlackhole(senderNode, targetNode, team)) {
                            trace("\"Try attacking.\" team: " + team + " sender: " + senderNode.tag + " target: " + targetNode.tag + " but failed: DANGEROUS_BLACKHOLE");
                            continue; // 路径上无有威胁的黑洞
                        }
                        // 基本飞船数：目标天体上预测敌方强度的二倍减去预测己方强度一半与单体强度之商
                        ships = (targetNode.predictedOppStrength(team) * 2 - targetNode.predictedGroupStrength(team) * 0.5) / shipStrength;
                        if (targetNode.nodeData.type == NodeType.DIFFUSION && Globals.teamGroups[targetNode.nodeData.team] == group)
                            ships = (Globals.teamCaps[team] - Globals.teamPops[team]) / 3 - targetNode.predictedTeamShipCount(team); // 给己方扩散补兵
                        if (senderNode.predictedOppStrength(team) > senderNode.predictedGroupStrength(team))
                            ships = senderNode.teamShipCount(team); // 预测敌方强度大于己方时，派出全部飞船
                        if (ships < targetNode.nodeData.size * 200)
                            ships = targetNode.nodeData.size * 200; // 飞船数不应低于目标的二倍标准兵力
                        towerAttack = EntityContainer.getLengthInTowerRange(senderNode, targetNode, team) / 4.5 / shipSpeed; // 计算估损
                        ships += Math.max(towerAttack, 0); // 为飞船数加上估损
                        if (towerAttack > 0 && Globals.teamPops[team] < towerAttack) {
                            trace("\"Try attacking.\" team: " + team + " sender: " + senderNode.tag + " target: " + targetNode.tag + " but failed: FATAL_TOWER_COST");
                            continue; // 总兵力不足估损时不派兵
                        }
                        if (Globals.level == 31)
                            if (towerAttack > 0 && senderNode.teamShipCount(team) < towerAttack * 2) {
                                trace("\"Try attacking.\" team: " + team + " sender: " + senderNode.tag + " target: " + targetNode.tag + " but failed: DANGEROUS_TOWER_COST");
                                continue; // 32关兵力不足估损二倍时换个目标
                            }
                        if (towerAttack > 0 && senderNode.teamShipCount(team) < towerAttack * 0.5) {
                            trace("\"Try attacking.\" team: " + team + " sender: " + senderNode.tag + " target: " + targetNode.tag + " but failed: DANGEROUS_TOWER_COST");
                            continue; // 出兵天体强度低于估损的一半时不派兵
                        }
                        // if (Globals.level == 34 && targetNode.x == 912 && targetNode.y == 544)
                        // trace("attacking");
                        // traceDebug("attacking       " + senderNode.x + "." + senderNode.y + "  to  " + targetNode.x + "." + targetNode.y + "  ships:  " + ships);
                        trace("\"Attacking!\" team: " + team + " sender: " + senderNode.tag + " target: " + targetNode.tag + " ships: " + ships + " towerAttack: " + towerAttack);
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
                if (nodeGroup != group && node.predictedOppShipCount(team) == 0 && node.groupShipCount(team) > 0)
                    continue; // 条件：没在锁星
                if (node.predictedOppShipCount(team) > 0 && node.predictedGroupStrength(team) > node.predictedOppStrength(team))
                    continue; // 条件：无敌方或打不过敌方
                node.aiStrength = -node.teamStrength(team);
                node.aiValue = -node.oppNodeLinks.length; // 按路径数计算价值
                if (node.nodeData.type == NodeType.DIFFUSION && Globals.teamPops[team] < Globals.teamCaps[team] && node.teamShipCount(team) < (Globals.teamCaps[team] - Globals.teamPops[team]) / 3) {
                    dx = node.nodeData.x - centerX;
                    dy = node.nodeData.y - centerY;
                    distance = Math.sqrt(dx * dx + dy * dy) + rng.nextNumber() * 32;
                    node.aiValue = -256 / distance * node.oppNodeLinks.length; // 扩散按距离计算价值
                }
                if (node.nodeData.isWarp) {
                    dx = node.nodeData.x - centerX;
                    dy = node.nodeData.y - centerY;
                    distance = Math.sqrt(dx * dx + dy * dy) + rng.nextNumber() * 32;
                    node.aiValue = -512 / distance * nodeArray.length; // 传送按距离计算价值
                }
                if (EntityContainer.inAttackNodeCheck(node, team, NodeType.PULSECANNON, true)) {
                    if (node.aiStrength > 0)
                        node.aiStrength /= 10;
                    else
                        node.aiStrength *= 10;
                }
                senders.push(node);
            }
            // senders.sortOn("aiStrength", 16); // 依飞船强度从小到大对出兵天体进行排序
            if (senders.length > 0) {
                targets.length = 0;
                for each (node in nodeArray) { // 计算目标天体
                    nodeGroup = Globals.teamGroups[node.nodeData.team];
                    if (node.nodeData.isAIinvisible)
                        continue;
                    if (nodeGroup != group) 
                        continue;
                    if (nodeGroup == group) {
                        node.getOppLinks(team);
                        node.aiValue = -node.oppNodeLinks.length; // 按路径数计算价值
                        if (node.nodeData.isWarp) {
                            dx = node.nodeData.x - centerX;
                            dy = node.nodeData.y - centerY;
                            distance = Math.sqrt(dx * dx + dy * dy) + rng.nextNumber() * 32;
                            node.aiValue = -512 / distance * node.oppNodeLinks.length; // 传送按距离计算价值
                        }
                        else if (node.nodeData.type == NodeType.DIFFUSION && Globals.teamPops[team] < Globals.teamCaps[team] && node.teamShipCount(team) < (Globals.teamCaps[team] - Globals.teamPops[team]) / 3) {
                            dx = node.nodeData.x - centerX;
                            dy = node.nodeData.y - centerY;
                            distance = Math.sqrt(dx * dx + dy * dy) + rng.nextNumber() * 32;
                            node.aiValue = -512 / distance * node.oppNodeLinks.length; // 扩散按距离计算价值
                        }
                        else if (node.nodeData.type == NodeType.CLONETURRET && Globals.teamPops[team] < Globals.teamCaps[team]) {
                            dx = node.nodeData.x - centerX;
                            dy = node.nodeData.y - centerY;
                            distance = Math.sqrt(dx * dx + dy * dy) + rng.nextNumber() * 32;
                            node.aiValue = -256 / distance * node.oppNodeLinks.length; // 航母按距离计算价值
                        }
                    }
                    // if (Globals.level == 31 && node.nodeData.type == NodeType.STARBASE)
                    //     node.aiValue--; // 32关堡垒权重提高
                    if (EntityContainer.inAttackNodeCheck(node, team, NodeType.PULSECANNON, true)) {
                        if (node.aiValue > 0)
                            node.aiValue *= 10;
                        else if (!node.nodeData.isWarp)
                            node.aiValue /= 10;
                    }
                    targets.push(node);
                }
                // targets.sortOn("aiValue", 16);
                invalidActions.length = 0;
                while (targets.length > 0 && senders.length > 0) {
                    if (invalidActions.length >= GeneralFunctions.getMinCount(targets, "aiValue") * GeneralFunctions.getMinCount(senders, "aiStrength")) {
                        invalidActions.length = 0;
                        targets = GeneralFunctions.popMinValues(targets, "aiValue", GeneralFunctions.getMinCount(targets, "aiValue"));
                        senders = GeneralFunctions.popMinValues(senders, "aiStrength", GeneralFunctions.getMinCount(targets, "aiStrength"));
                    }
                    targetNode = GeneralFunctions.getRandomMinByProperty(rng, targets, "aiValue") as Node; // 随机选择一个aiValue最小的目标
                    senderNode = GeneralFunctions.getRandomMinByProperty(rng, senders, "aiStrength") as Node; // 随机选择一个aiStrength最小的出兵天体
                    if (targetNode && senderNode) {
                        if (invalidActions.indexOf(senderNode.tag + "," + targetNode.tag) == -1) // 检查是否是已经尝试过的操作
                            invalidActions.push(senderNode.tag + "," + targetNode.tag); // 宣布操作已经尝试过
                        else
                            continue;
                        if (senderNode == targetNode || senderNode.nodeLinks[team].indexOf(targetNode) == -1) {
                            trace("\"Try repositioning.\" team: " + team + " sender: " + senderNode.tag + " target: " + targetNode.tag + " but failed: THE_SAME_ONE_OR_BLOCKED");
                            continue; // 基本条件：出兵天体和目标天体不为同一个，且二者之间没有被拦截
                        }
                        if (targetNode.aiValue >= senderNode.aiValue) {
                            trace("\"Try repositioning.\" team: " + team + " sender: " + senderNode.tag + " target: " + targetNode.tag + " but failed: VALUELESS");
                            continue; // 条件：目标天体价值高于出兵天体价值
                        }
                        if (!senderNode.nodeData.isWarp && EntityContainer.isInBlackhole(senderNode, targetNode, team)) {
                            trace("\"Try repositioning.\" team: " + team + " sender: " + senderNode.tag + " target: " + targetNode.tag + " but failed: DANGEROUS_BLACKHOLE");
                            continue; // 路径上无有威胁的黑洞
                        }
                        ships = senderNode.teamShipCount(team); // 派出全部飞船
                        towerAttack = EntityContainer.getLengthInTowerRange(senderNode, targetNode, team) / 4.5 / shipSpeed;
                        ships += Math.max(towerAttack, 0); // 为飞船数加上估损
                        if (towerAttack > 0 && Globals.teamPops[team] < towerAttack) {
                            trace("\"Try repositioning.\" team: " + team + " sender: " + senderNode.tag + " target: " + targetNode.tag + " but failed: FATAL_TOWER_COST");
                            continue; // 条件：总兵力不足估损时不派兵
                        }
                        if (towerAttack > 0 && senderNode.teamShipCount(team) < towerAttack * 0.5) {
                            trace("\"Try repositioning.\" team: " + team + " sender: " + senderNode.tag + " target: " + targetNode.tag + " but failed: DANGEROUS_TOWER_COST");
                            continue; // 出兵天体强度低于估损的一半时不派兵
                        }
                        // if (Globals.level == 34 && targetNode.x == 912 && targetNode.y == 544)
                        // trace("repositioning");
                        // if (ships != 0)
                        //     traceDebug("repositioning   " + senderNode.x + "." + senderNode.y + "  to  " + targetNode.x + "." + targetNode.y + "  ships:  " + ships);
                        trace("\"Repositioning!\" team: " + team + " sender: " + senderNode.tag + " target: " + targetNode.tag + " ships: " + ships + " towerAttack: " + towerAttack);
                        NodeStaticLogic.sendAIShips(senderNode, team, targetNode, ships);
                        return;
                    }
                }
            }
            // #endregion
        }

        override public function get type():String {
            return EnemyAIFactory.ADAPTED;
        }
    }
}
