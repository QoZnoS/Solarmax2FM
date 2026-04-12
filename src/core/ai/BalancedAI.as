package core.ai {
    import core.EntityContainer;
    import core.entities.Node;
    import core.factories.EnemyAIFactory;
    import core.node.NodeStaticLogic;
    import core.node.NodeType;
    import managers.Globals;
    import utils.GeneralFunctions;
    import utils.Rng;

    public class BalancedAI extends BasicAI {

        public function BalancedAI(rng:Rng, actionDelay:Number, startDelay:Number) {
            super(rng, actionDelay, startDelay)
        }

        override public function update(dt:Number):void {
            if (!updateTimer(dt))
                return;
            updateBalanced()
        }

        public function updateBalanced():void {
            var node:Node = null;
            var invalidActions:Vector.<String> = new Vector.<String>;
            var validCount:int = 0;
            var targetNode:Node = null;
            var senderNode:Node = null;
            var ships:int = 0;
            var towerAttack:Number = NaN;
            var nodeGroup:int = -1;
            var shipStrength:Number = Math.sqrt(Globals.teamShipAttacks[team] * Globals.teamShipDefences[team]); //单体强度
            var shipSpeed:Number = Globals.teamShipSpeeds[team] / 50; //单体速度
            // #region 防御
            targets.length = 0;
            for each (node in nodeArray) { // 计算目标天体
                nodeGroup = Globals.teamGroups[node.nodeData.team];
                if (node.nodeData.type == NodeType.DILATOR && SituationAssessor.teamStrength(node, team, false) > 0) {
                    node.unloadShips();
                    return;
                }
                if (node.nodeData.isAIinvisible)
                    continue;
                if (nodeGroup != group && SituationAssessor.predictedGroupStrength(node, team, false) == 0)
                    continue; // 条件1：为己方天体或有己方飞船（包括飞行中的）
                if (SituationAssessor.predictedOppStrength(node, team, false) == 0)
                    continue; // 条件2：有敌方
                if (SituationAssessor.predictedGroupStrength(node, team) > SituationAssessor.predictedOppStrength(node, team) * 2)
                    continue; // 条件3：预测己方强度低于敌方两倍（即可能打不过敌方
                targets.push(node);
            }
            if (targets.length > 0) { // 目标天体存在时
                senders.length = 0;
                for each (node in nodeArray) { // 计算出兵天体
                    nodeGroup = Globals.teamGroups[node.nodeData.team];
                    if (node.nodeData.isAIinvisible)
                        continue;
                    if (node.aiTimers[team] > 0 || SituationAssessor.teamStrength(node, team, false) == 0)
                        continue; // 基本条件：该天体己方ai倒计时为0且该天体己方强度不为0
                    if (nodeGroup != group && SituationAssessor.predictedGroupStrength(node, team) > SituationAssessor.predictedOppStrength(node, team))
                        continue; // 条件：是己方天体或预测己方强度低于敌方
                    if (SituationAssessor.predictedOppStrength(node, team, false) > 0 && SituationAssessor.predictedGroupStrength(node, team) > SituationAssessor.predictedOppStrength(node, team))
                        continue; // 条件：没有敌方或预测己方强度低于敌方
                    if (SituationAssessor.teamStrength(node, team, false) == 0)
                        continue; // 基本条件：有我方兵力
                    node.aiStrength = -SituationAssessor.groupStrength(node, team); // 将该天体己方强度记为己方船数的相反数
                    if (EntityContainer.inAttackNodeCheck(node, team, NodeType.PULSECANNON, true)) {
                        if (node.aiStrength > 0)
                            node.aiStrength /= 10;
                        else
                            node.aiStrength *= 10;
                    }
                    senders.push(node);
                }
                invalidActions.length = 0;
                validCount = getValidCount("defend", senders, targets, team, rng);
                while (targets.length > 0 && senders.length > 0) {
                    if (invalidActions.length >= validCount) {
                        invalidActions.length = 0;
                        senders = GeneralFunctions.popMinValues(senders, "aiStrength", GeneralFunctions.getMinCount(senders, "aiStrength"));
                        validCount = getValidCount("defend", senders, targets, team, rng);
                    }
                    senderNode = GeneralFunctions.getRandomMinByProperty(rng, senders, "aiStrength") as Node; // 随机选择一个aiStrength最小的出兵天体
                    if (!senderNode)
                        break;
                    getDefendValue(senderNode, targets, team, rng);
                    targetNode = GeneralFunctions.getRandomMinByProperty(rng, targets, "aiValue") as Node; // 随机选择一个aiValue最小的目标
                    if (targetNode && senderNode) {
                        if (invalidActions.indexOf(senderNode.tag + "," + targetNode.tag) == -1) // 检查是否是已经尝试过的操作
                            invalidActions.push(senderNode.tag + "," + targetNode.tag); // 宣布操作已经尝试过
                        else
                            continue;
                        if (senderNode == targetNode || senderNode.nodeLinks[team].indexOf(targetNode) == -1) {
                            trace("\"Try defending.\" team: " + team + " sender: " + senderNode.tag + " target: " + targetNode.tag + " but failed: THE_SAME_ONE_OR_BLOCKED");
                            continue; // 基本条件：出兵天体和目标天体不为同一个，且二者之间没有被拦截
                        }
                        if (SituationAssessor.teamStrength(senderNode, team) + SituationAssessor.predictedGroupStrength(targetNode, team) < SituationAssessor.predictedOppStrength(targetNode, team)) {
                            trace("\"Try defending.\" team: " + team + " sender: " + senderNode.tag + " target: " + targetNode.tag + " but failed: TOO_WEAK");
                            continue; // 出兵条件：出兵天体的强度和目标天体的预测强度之和高于目标天体的预测敌方强度
                        }
                        if (!senderNode.nodeData.isWarp && EntityContainer.isInBlackhole(senderNode, targetNode, team)) {
                            trace("\"Try defending.\" team: " + team + " sender: " + senderNode.tag + " target: " + targetNode.tag + " but failed: DANGEROUS_BLACKHOLE");
                            continue; // 路径上无有威胁的黑洞
                        }
                        // 飞船数：目标天体上预测敌方强度的二倍减去预测己方强度与己方单体强度之商
                        ships = (SituationAssessor.predictedOppStrength(targetNode, team, false) * 2 - SituationAssessor.predictedGroupStrength(targetNode, team, false)) / shipStrength;
                        towerAttack = getTowerAttack(senderNode, targetNode); // 估算经过攻击天体损失的兵力（估损
                        ships += Math.max(towerAttack, 0); // 为飞船数加上估损
                        if (towerAttack > 0 && Globals.teamPops[team] < towerAttack) {
                            trace("\"Try defending.\" team: " + team + " sender: " + senderNode.tag + " target: " + targetNode.tag + " but failed: FATAL_TOWER_COST");
                            continue; // 条件：没有经过攻击天体或总兵力多于估损
                        }
                        if (towerAttack > 0 && SituationAssessor.teamStrength(senderNode, team, false) < towerAttack) {
                            trace("\"Try defending.\" team: " + team + " sender: " + senderNode.tag + " target: " + targetNode.tag + " but failed: DANGEROUS_TOWER_COST");
                            continue; // 条件：没有经过攻击天体或出兵天体强度高于估损
                        }
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
                if (nodeGroup == group && ((node.nodeData.type != NodeType.DIFFUSION || SituationAssessor.predictedTeamStrength(node, team, false) > (Globals.teamCaps[team] - Globals.teamPops[team]) / 3) || Globals.teamPops[team] >= Globals.teamCaps[team]) || node.nodeData.isAIinvisible)
                    continue; // 己方少兵扩散应纳入考虑范围
                if (SituationAssessor.predictedOppStrength(node, team, false) == 0 && SituationAssessor.predictedGroupStrength(node, team, false) > node.nodeData.size * 150)
                    continue; // 条件：排除己方船数足够且无敌方的天体
                targets.push(node);
            }
            if (targets.length > 0) {
                senders.length = 0;
                for each (node in nodeArray) { // 计算出兵天体
                    nodeGroup = Globals.teamGroups[node.nodeData.team];
                    if (node.nodeData.isAIinvisible)
                        continue;
                    if (node.aiTimers[team] > 0 || SituationAssessor.teamStrength(node, team, false) == 0)
                        continue; // 基本条件：该天体己方ai倒计时为0且该天体己方强度不为0
                    if (SituationAssessor.predictedOppStrength(node, team, false) == 0 && node.capturing)
                        continue; // 条件：天体不被己方占据
                    if (nodeGroup != group && SituationAssessor.predictedGroupStrength(node, team) > SituationAssessor.predictedOppStrength(node, team))
                        continue; // 条件：是己方天体或预测己方强度低于敌方
                    if (SituationAssessor.predictedOppStrength(node, team, false) > 0 && SituationAssessor.predictedGroupStrength(node, team) > SituationAssessor.predictedOppStrength(node, team))
                        continue; // 条件：没有敌方或预测己方强度低于敌方
                    if (SituationAssessor.teamStrength(node, team, false) == 0)
                        continue; // 基本条件：有我方兵力
                    node.aiStrength = -SituationAssessor.groupStrength(node, team);
                    if (EntityContainer.inAttackNodeCheck(node, team, NodeType.PULSECANNON, true)) {
                        if (node.aiStrength > 0)
                            node.aiStrength /= 10;
                        else
                            node.aiStrength *= 10;
                    }
                    senders.push(node);
                }
                invalidActions.length = 0;
                validCount = getValidCount("attack", senders, targets, team, rng);
                while (targets.length > 0 && senders.length > 0) {
                    if (invalidActions.length >= validCount) {
                        invalidActions.length = 0;
                        senders = GeneralFunctions.popMinValues(senders, "aiStrength", GeneralFunctions.getMinCount(senders, "aiStrength"));
                        validCount = getValidCount("attack", senders, targets, team, rng);
                    }
                    senderNode = GeneralFunctions.getRandomMinByProperty(rng, senders, "aiStrength") as Node; // 随机选择一个aiStrength最小的出兵天体
                    if (!senderNode)
                        break;
                    getAttackValue(senderNode, targets, team, rng);
                    targetNode = GeneralFunctions.getRandomMinByProperty(rng, targets, "aiValue") as Node; // 随机选择一个aiValue最小的目标
                    if (targetNode && senderNode) {
                        if (invalidActions.indexOf(senderNode.tag + "," + targetNode.tag) == -1) // 检查是否是已经尝试过的操作
                            invalidActions.push(senderNode.tag + "," + targetNode.tag); // 宣布操作已经尝试过
                        else
                            continue;
                        if (senderNode == targetNode || senderNode.nodeLinks[team].indexOf(targetNode) == -1) {
                            trace("\"Try attacking.\" team: " + team + " sender: " + senderNode.tag + " target: " + targetNode.tag + " but failed: THE_SAME_ONE_OR_BLOCKED");
                            continue; // 基本条件：出兵天体和目标天体不为同一个，且二者之间没有被拦截
                        }
                        if (SituationAssessor.teamStrength(senderNode, team) + SituationAssessor.predictedGroupStrength(targetNode, team) <= SituationAssessor.predictedOppStrength(targetNode, team)) {
                            trace("\"Try attacking.\" team: " + team + " sender: " + senderNode.tag + " target: " + targetNode.tag + " but failed: TOO_WEAK");
                            continue; // 出兵条件：出兵天体和目标天体的己方综合强度高于目标天体的预测敌方强度
                        }
                        if (!senderNode.nodeData.isWarp && EntityContainer.isInBlackhole(senderNode, targetNode, team)) {
                            trace("\"Try attacking.\" team: " + team + " sender: " + senderNode.tag + " target: " + targetNode.tag + " but failed: DANGEROUS_BLACKHOLE");
                            continue; // 路径上无有威胁的黑洞
                        }
                        // 基本飞船数：目标天体上预测敌方强度的二倍减去预测己方强度一半与单体强度之商
                        ships = (SituationAssessor.predictedOppStrength(targetNode, team) * 2 - SituationAssessor.predictedGroupStrength(targetNode, team) * 0.5) / shipStrength;
                        if (targetNode.nodeData.type == NodeType.DIFFUSION && Globals.teamGroups[targetNode.nodeData.team] == group)
                            ships = (Globals.teamCaps[team] - Globals.teamPops[team]) / 3 - SituationAssessor.predictedTeamStrength(targetNode, team, false); // 给己方扩散补兵
                        if (SituationAssessor.predictedOppStrength(senderNode, team) > SituationAssessor.predictedGroupStrength(senderNode, team))
                            ships = SituationAssessor.teamStrength(senderNode, team, false); // 预测敌方强度大于己方时，派出全部飞船
                        if (ships < targetNode.nodeData.size * 200)
                            ships = targetNode.nodeData.size * 200; // 飞船数不应低于目标的二倍标准兵力
                        towerAttack = getTowerAttack(senderNode, targetNode); // 计算估损
                        ships += Math.max(towerAttack, 0); // 为飞船数加上估损
                        if (towerAttack > 0 && Globals.teamPops[team] < towerAttack) {
                            trace("\"Try attacking.\" team: " + team + " sender: " + senderNode.tag + " target: " + targetNode.tag + " but failed: FATAL_TOWER_COST");
                            continue; // 总兵力不足估损时不派兵
                        }
                        if (towerAttack > 0 && SituationAssessor.teamStrength(senderNode, team, false) < towerAttack) {
                            trace("\"Try attacking.\" team: " + team + " sender: " + senderNode.tag + " target: " + targetNode.tag + " but failed: DANGEROUS_TOWER_COST");
                            continue; // 出兵天体强度低于估损的一半时不派兵
                        }
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
                if (nodeGroup != group && SituationAssessor.predictedOppStrength(node, team, false) == 0 && SituationAssessor.groupStrength(node, team, false) > 0)
                    continue; // 条件：没在锁星
                if (SituationAssessor.predictedOppStrength(node, team, false) > 0 && SituationAssessor.predictedGroupStrength(node, team) > SituationAssessor.predictedOppStrength(node, team))
                    continue; // 条件：无敌方或打不过敌方
                if (SituationAssessor.teamStrength(node, team, false) == 0)
                    continue; // 基本条件：有我方兵力
                node.aiStrength = -SituationAssessor.teamStrength(node, team);
                node.aiValue = -SituationAssessor.getOppCloseLinks(node, team); // 按接近前线程度计算价值
                if (EntityContainer.inAttackNodeCheck(node, team, NodeType.PULSECANNON, true)) {
                    if (node.aiStrength > 0)
                        node.aiStrength /= 10;
                    else
                        node.aiStrength *= 10;
                }
                senders.push(node);
            }
            if (senders.length > 0) {
                targets.length = 0;
                for each (node in nodeArray) { // 计算目标天体
                    nodeGroup = Globals.teamGroups[node.nodeData.team];
                    if (node.nodeData.isAIinvisible)
                        continue;
                    if (nodeGroup != group)
                        continue;
                    if (nodeGroup == group) {
                        node.aiValue = -SituationAssessor.getOppCloseLinks(node, team); // 按靠近前线程度计算价值
                    }
                    targets.push(node);
                }
                invalidActions.length = 0;
                validCount = getValidCount("reposition", senders, targets, team, rng);
                while (targets.length > 0 && senders.length > 0) {
                    if (invalidActions.length >= validCount) {
                        invalidActions.length = 0;
                        senders = GeneralFunctions.popMinValues(senders, "aiStrength", GeneralFunctions.getMinCount(senders, "aiStrength"));
                        validCount = getValidCount("reposition", senders, targets, team, rng);
                    }
                    senderNode = GeneralFunctions.getRandomMinByProperty(rng, senders, "aiStrength") as Node; // 随机选择一个aiStrength最小的出兵天体
                    if (!senderNode)
                        break;
                    getRepositionValue(senderNode, targets, team, rng);
                    targetNode = GeneralFunctions.getRandomMinByProperty(rng, targets, "aiValue") as Node; // 随机选择一个aiValue最小的目标
                    if (targetNode && senderNode) {
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
                            if (targetNode.aiValue > senderNode.aiValue) {
                                trace("\"Try repositioning.\" team: " + team + " sender: " + senderNode.tag + " target: " + targetNode.tag + " but failed: VALUELESS");
                                continue; // 条件：目标天体价值高于出兵天体价值
                            }
                            if (!senderNode.nodeData.isWarp && EntityContainer.isInBlackhole(senderNode, targetNode, team)) {
                                trace("\"Try repositioning.\" team: " + team + " sender: " + senderNode.tag + " target: " + targetNode.tag + " but failed: DANGEROUS_BLACKHOLE");
                                continue; // 路径上无有威胁的黑洞
                            }
                            ships = SituationAssessor.teamStrength(senderNode, team, false); // 派出全部飞船
                            towerAttack = getTowerAttack(senderNode, targetNode);
                            ships += Math.max(towerAttack, 0); // 为飞船数加上估损
                            if (towerAttack > 0 && Globals.teamPops[team] < towerAttack) {
                                trace("\"Try repositioning.\" team: " + team + " sender: " + senderNode.tag + " target: " + targetNode.tag + " but failed: FATAL_TOWER_COST");
                                continue; // 条件：总兵力不足估损时不派兵
                            }
                            if (towerAttack > 0 && SituationAssessor.teamStrength(senderNode, team, false) < towerAttack) {
                                trace("\"Try repositioning.\" team: " + team + " sender: " + senderNode.tag + " target: " + targetNode.tag + " but failed: DANGEROUS_TOWER_COST");
                                continue; // 出兵天体强度低于估损的一半时不派兵
                            }
                            trace("\"Repositioning!\" team: " + team + " sender: " + senderNode.tag + " target: " + targetNode.tag + " ships: " + ships + " towerAttack: " + towerAttack);
                            NodeStaticLogic.sendAIShips(senderNode, team, targetNode, ships);
                            return;
                        }
                    }
                }
                    // #endregion
            }
        }

        // #region 估损函数（QoZnoS 著
        public function getTowerAttack(node1:Node, node2:Node):Number {
            if (node1.nodeData.isWarp && Globals.teamGroups[node1.nodeData.team] == group) {
                return 0;
            }

            // 所有变量声明在函数顶部
            var teamGroups:Array = Globals.teamGroups;
            var teamShipSpeed:Number = Globals.teamShipSpeeds[team];
            var node1TeamGroup:int = teamGroups[node1.nodeData.team];
            var startX:Number = node1.nodeData.x;
            var startY:Number = node1.nodeData.y;
            var endX:Number = node2.nodeData.x;
            var endY:Number = node2.nodeData.y;
            var dx:Number = endX - startX;
            var dy:Number = endY - startY;
            var segLengthSquared:Number = dx * dx + dy * dy;
            var segmentLength:Number = Math.sqrt(segLengthSquared);
            var towerAttack:Number = 0;

            // 预先计算所有攻击型节点的攻击参数
            var nodes:Vector.<Node> = nodeArray;
            var nodeCount:int = nodes.length;

            // 预筛选节点，只处理敌方攻击节点
            for (var i:int = 0; i < nodeCount; i++) {
                var node:Node = nodes[i];
                var nodeData:Object = node.nodeData;

                // 快速跳过条件
                if (nodeData.team == 0)
                    continue;
                if (teamGroups[nodeData.team] == group)
                    continue;

                var nodeType:String = nodeData.type;
                if (nodeType != NodeType.TOWER && nodeType != NodeType.STARBASE && nodeType != NodeType.CAPTURESHIP)
                    continue;

                var attackState:Object = node.attackState;
                var attackRange:Number = attackState.attackRange;
                if (attackRange <= 0)
                    continue;

                // 使用内联的快速几何判断
                var centerX:Number = nodeData.x;
                var centerY:Number = nodeData.y;
                var radiusSquared:Number = attackRange * attackRange;

                // 计算圆心到起点的向量
                var cx:Number = centerX - startX;
                var cy:Number = centerY - startY;

                // 计算投影参数
                var t:Number = (cx * dx + cy * dy) / segLengthSquared;
                t = t < 0 ? 0 : (t > 1 ? 1 : t);

                // 计算最近点距离平方
                var closestX:Number = startX + t * dx;
                var closestY:Number = startY + t * dy;
                var distX:Number = centerX - closestX;
                var distY:Number = centerY - closestY;
                var distSquared:Number = distX * distX + distY * distY;

                // 如果不相交，跳过
                if (distSquared > radiusSquared)
                    continue;

                // 计算重叠长度
                var length:Number = 0;

                // 检查是否完全在圆内
                var startDistSquared:Number = cx * cx + cy * cy;
                var endDistSquared:Number = (centerX - endX) * (centerX - endX) + (centerY - endY) * (centerY - endY);

                if (startDistSquared <= radiusSquared && endDistSquared <= radiusSquared) {
                    length = segmentLength;
                } else {
                    // 计算半弦长
                    var halfChordLength:Number = Math.sqrt(radiusSquared - distSquared);
                    var dt:Number = halfChordLength / segmentLength;
                    var t1:Number = t - dt;
                    var t2:Number = t + dt;

                    t1 = t1 < 0 ? 0 : (t1 > 1 ? 1 : t1);
                    t2 = t2 < 0 ? 0 : (t2 > 1 ? 1 : t2);

                    length = (t2 - t1) * segmentLength;
                }

                if (length > 0) {
                    towerAttack += (length / teamShipSpeed) / attackState.attackRate;
                }
            }
            return towerAttack;
            // #endregion
        }

        // #region aiValues

        public function getDefendValue(senderNode:Node, targets:Array, team:int, rng:Rng):void {
            for each (var targetNode:Node in targets) {
                var dx:Number = targetNode.nodeData.x - senderNode.nodeData.x;
                var dy:Number = targetNode.nodeData.y - senderNode.nodeData.y;
                var distance:Number = Math.sqrt(dx * dx + dy * dy) + rng.nextNumber() * 32;
                var towerAttack:Number = getTowerAttack(senderNode, targetNode);
                var risk:Number = SituationAssessor.predictedGroupStrength(targetNode, team) - SituationAssessor.predictedOppCaptureRisk(targetNode, team);

                targetNode.aiValue = distance + risk + towerAttack * 64;
            }
        }

        public function getAttackValue(senderNode:Node, targets:Array, team:int, rng:Rng):void {
            for each (var targetNode:Node in targets) {
                var dx:Number = targetNode.nodeData.x - senderNode.nodeData.x;
                var dy:Number = targetNode.nodeData.y - senderNode.nodeData.y;
                var distance:Number = Math.sqrt(dx * dx + dy * dy) + rng.nextNumber() * 32;
                var towerAttack:Number = getTowerAttack(senderNode, targetNode);
                var risk:Number = SituationAssessor.predictedOppStrength(targetNode, team) - SituationAssessor.predictedGroupStrength(targetNode, team);

                targetNode.aiValue = distance + risk + towerAttack * 64;
                if (EntityContainer.inAttackNodeCheck(targetNode, team, NodeType.PULSECANNON, true)) {
                    if (targetNode.aiValue > 0)
                        targetNode.aiValue *= 10;
                    else
                        targetNode.aiValue /= 10;
                }
            }
        }

        public function getRepositionValue(senderNode:Node, targets:Array, team:int, rng:Rng):void {
            for each (var node:Node in targets) {
                var towerAttack:Number = getTowerAttack(senderNode, node);
                node.aiValue += towerAttack * 2;
                if (node.nodeData.isWarp) {
                    var dx:Number = node.nodeData.x - senderNode.nodeData.x;
                    var dy:Number = node.nodeData.y - senderNode.nodeData.y;
                    var distance:Number = Math.sqrt(dx * dx + dy * dy) + rng.nextNumber() * 32;
                    towerAttack = getTowerAttack(senderNode, node);
                    node.aiValue = -512 / distance * node.oppNodeLinks[team].length + towerAttack; // 传送按距离计算价值
                } else if (node.nodeData.type == NodeType.DIFFUSION && Globals.teamPops[team] < Globals.teamCaps[team] && SituationAssessor.teamStrength(node, team, false) < (Globals.teamCaps[team] - Globals.teamPops[team]) / 3) {
                    dx = node.nodeData.x - senderNode.nodeData.x;
                    dy = node.nodeData.y - senderNode.nodeData.y;
                    distance = Math.sqrt(dx * dx + dy * dy) + rng.nextNumber() * 32;
                    towerAttack = getTowerAttack(senderNode, node);
                    node.aiValue = -512 / distance * node.oppNodeLinks[team].length + towerAttack; // 扩散按距离计算价值
                } else if (node.nodeData.type == NodeType.CLONETURRET && Globals.teamPops[team] < Globals.teamCaps[team]) {
                    dx = node.nodeData.x - senderNode.nodeData.x;
                    dy = node.nodeData.y - senderNode.nodeData.y;
                    distance = Math.sqrt(dx * dx + dy * dy) + rng.nextNumber() * 32;
                    towerAttack = getTowerAttack(senderNode, node);
                    node.aiValue = -256 / distance * node.oppNodeLinks[team].length + towerAttack * 4; // 航母按距离计算价值
                }
                if (EntityContainer.inAttackNodeCheck(node, team, NodeType.PULSECANNON, true)) {
                    if (node.aiValue > 0)
                        node.aiValue *= 10;
                    else
                        node.aiValue /= 10;
                }
            }
        }

        // #endregion

        private function getValidCount(type:String, senders:Array, targets:Array, team:int, rng:Rng):int {
            var validCount:int = 0;
            for each (var senderNode:Node in GeneralFunctions.getMins(senders, "aiStrength")) {
                if (!senderNode)
                    break;

                switch (type) {
                    case "defend":
                        getDefendValue(senderNode, targets, team, rng);
                        break;
                    case "attack":
                        getAttackValue(senderNode, targets, team, rng);
                        break;
                    case "reposition":
                        getRepositionValue(senderNode, targets, team, rng);
                        break;
                }

                validCount += GeneralFunctions.getMinCount(targets, "aiValue");
            }
            return validCount;
        }

        override public function get type():String {
            return EnemyAIFactory.BALANCED;
        }
    }
}
