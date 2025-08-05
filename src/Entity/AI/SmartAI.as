package Entity.AI {
    import Game.GameScene;
    import utils.Rng;
    import Entity.Node;
    import Entity.EntityContainer;
    import Entity.Node.NodeStaticLogic;
    import Entity.Node.NodeType;
    import Entity.EntityContainer;

    public class SmartAI extends BasicAI {
        public function SmartAI(game:GameScene, rng:Rng) {
            super(game, rng)
        }

        override public function update(dt:Number):void {
            if (!updateTimer(dt))
                return;
            updateSmart()
        }

        public function updateSmart():void {
            if (Globals.teamCaps[team] == 0 && Globals.teamPops[team] < 40)
                return; // 上限为0且总飞船数少于40时挂机
            var _Node:Node = null;
            var _dx:Number = NaN;
            var _dy:Number = NaN;
            var _Distence:Number = NaN;
            var _Strength:Number = NaN;
            var _targetNode:Node = null;
            var _senderNode:Node = null;
            var _Ships:int = 0;
            var _towerAttack:Number = NaN;
            var _CenterX:Number = 0;
            var _CenterY:Number = 0;
            var _NodeCount:Number = 0;
            for each (_Node in nodeArray) {
                _Node.getNodeLinks(team);
                _Node.getTransitShips(team);
                if (_Node.nodeData.team == team) {
                    _CenterX += _Node.nodeData.x;
                    _CenterY += _Node.nodeData.y;
                    _NodeCount += 1;
                }
            }
            _CenterX /= _NodeCount;
            _CenterY /= _NodeCount;
            // #region 防御
            targets.length = 0;
            for each (_Node in nodeArray) { // 计算目标天体
                if (team == 6 && _Node.nodeData.type == NodeType.DILATOR && _Node.teamStrength(team) > 0) {
                    _Node.unloadShips();
                    return;
                }
                if (team == 6 || _Node.nodeData.type == NodeType.BARRIER || _Node.nodeData.type == NodeType.DILATOR)
                    continue; // ？排除障碍星核
                if (_Node.nodeData.team != team && _Node.predictedTeamStrength(team) == 0)
                    continue; // 条件1：为己方天体或有己方飞船（包括飞行中的）
                if (_Node.predictedOppStrength(team) == 0)
                    continue; // 条件2：有敌方
                if (_Node.predictedTeamStrength(team) > _Node.predictedOppStrength(team) * 2)
                    continue; // 条件3：预测己方强度低于敌方两倍（即可能打不过敌方
                _dx = _Node.nodeData.x - _CenterX;
                _dy = _Node.nodeData.y - _CenterY;
                _Distence = Math.sqrt(_dx * _dx + _dy * _dy) + rng.nextNumber() * 32;
                _Strength = _Node.predictedTeamStrength(team) - _Node.predictedOppStrength(team);
                _Node.aiValue = _Distence + _Strength;
                targets.push(_Node);
            }
            targets.sortOn("aiValue", 16); // 依ai价值从小到大对targets进行排序
            if (targets.length > 0) { // 目标天体存在时
                senders.length = 0;
                for each (_Node in nodeArray) { // 计算出兵天体
                    if (_Node.aiTimers[team] > 0 || _Node.teamStrength(team) == 0)
                        continue; // 基本条件：该天体己方ai倒计时为0且该天体己方强度不为0
                    if (_Node.nodeData.team != team && _Node.predictedTeamStrength(team) > _Node.predictedOppStrength(team))
                        continue; // 条件：是己方天体或预测己方强度低于敌方
                    if (_Node.predictedOppStrength(team) > 0 && _Node.predictedTeamStrength(team) > _Node.predictedOppStrength(team))
                        continue; // 条件：没有敌方或预测己方强度低于敌方
                    _Node.aiStrength = -_Node.teamStrength(team); // 将该天体己方强度记为飞船数的相反数
                    senders.push(_Node);
                }
                senders.sortOn("aiStrength", 16); // 依己方强度从小到大对出兵天体进行排序（由于强度记录的是相反数，此时看绝对值则是从大到小
                for each (_targetNode in targets) {
                    for each (_senderNode in senders) {
                        if (_senderNode == _targetNode || _senderNode.nodeLinks.indexOf(_targetNode) == -1)
                            continue; // 基本条件：出兵天体和目标天体不为同一个，且二者之间没有被拦截
                        if (_senderNode.teamStrength(team) + _targetNode.predictedTeamStrength(team) < _targetNode.predictedOppStrength(team))
                            continue; // 出兵条件：出兵天体的强度和目标天体的预测强度之和高于目标天体的预测敌方强度
                        // 飞船数：目标天体上预测敌方强度的二倍减去预测己方强度
                        _Ships = _targetNode.predictedOppStrength(team) * 2 - _targetNode.predictedTeamStrength(team);
                        _towerAttack = EntityContainer.getLengthInTowerRange(_senderNode, _targetNode, team) / 4.5; // 估算经过攻击天体损失的兵力（估损
                        _Ships += _towerAttack; // 为飞船数加上估损
                        if (_towerAttack > 0 && Globals.teamPops[team] < _towerAttack)
                            continue; // 条件：没有经过攻击天体或总兵力多于估损
                        if (_towerAttack > 0 && _senderNode.teamStrength(team) < _towerAttack * 0.5)
                            continue; // 条件：没有经过攻击天体或出兵天体强度高于估损的一半
                        // if (Globals.level == 34 && _targetNode.x == 912 && _targetNode.y == 544)
                        // trace("defending");
                        // traceDebug("defending       " + _senderNode.x + "." + _senderNode.y + "  to  " + _targetNode.x + "." + _targetNode.y + "  ships:  " + _Ships);
                        NodeStaticLogic.sendAIShips(_senderNode, team, _targetNode, _Ships);
                        return;
                    }
                }
            }
            // #endregion
            // #region 进攻
            targets.length = 0;
            for each (_Node in nodeArray) { // 计算目标天体
                if (_Node.nodeData.team == team || _Node.nodeData.type == NodeType.BARRIER || _Node.nodeData.type == NodeType.DILATOR)
                    continue; // 基本条件：不为己方天体和障碍星核
                if (_Node.predictedOppStrength(team) == 0 && _Node.predictedTeamStrength(team) > _Node.nodeData.size * 150)
                    continue; // 条件：排除己方强度足够且无敌方的天体
                _dx = _Node.nodeData.x - _CenterX;
                _dy = _Node.nodeData.y - _CenterY;
                _Distence = Math.sqrt(_dx * _dx + _dy * _dy) + rng.nextNumber() * 32;
                _Strength = _Node.predictedOppStrength(team) - _Node.predictedTeamStrength(team);
                _Node.aiValue = _Distence + _Strength;
                targets.push(_Node);
            }
            targets.sortOn("aiValue", 16);
            if (targets.length > 0) {
                senders.length = 0;
                for each (_Node in nodeArray) { // 计算出兵天体
                    if (_Node.aiTimers[team] > 0 || _Node.teamStrength(team) == 0)
                        continue; // 基本条件：该天体己方ai倒计时为0且该天体己方强度不为0
                    if (_Node.predictedOppStrength(team) == 0 && _Node.capturing)
                        continue; // 条件：天体不被己方占据
                    if (_Node.nodeData.team != team && _Node.predictedTeamStrength(team) > _Node.predictedOppStrength(team))
                        continue; // 条件：是己方天体或预测己方强度低于敌方
                    if (_Node.predictedOppStrength(team) > 0 && _Node.predictedTeamStrength(team) > _Node.predictedOppStrength(team))
                        continue; // 条件：没有敌方或预测己方强度低于敌方
                    _Node.aiStrength = -_Node.teamStrength(team);
                    senders.push(_Node);
                }
                senders.sortOn("aiStrength", 16);
                for each (_targetNode in targets) {
                    for each (_senderNode in senders) {
                        if (_senderNode == _targetNode || _senderNode.nodeLinks.indexOf(_targetNode) == -1)
                            continue; // 基本条件：出兵天体和目标天体不为同一个，且二者之间没有被拦截
                        if (_senderNode.teamStrength(team) + _targetNode.predictedTeamStrength(team) <= _targetNode.predictedOppStrength(team))
                            continue; // 出兵条件：出兵天体和目标天体的己方综合强度高于目标天体的预测敌方强度
                        // 基本飞船数：目标天体上预测敌方强度的二倍减去预测己方强度一半
                        _Ships = _targetNode.predictedOppStrength(team) * 2 - _targetNode.predictedTeamStrength(team) * 0.5;
                        if (_senderNode.predictedOppStrength(team) > _senderNode.predictedTeamStrength(team))
                            _Ships = _senderNode.teamStrength(team); // 预测敌方强度大于己方时，派出全部飞船
                        if (_Ships < _targetNode.nodeData.size * 200)
                            _Ships = _targetNode.nodeData.size * 200; // 飞船数不应低于目标的二倍标准兵力
                        _towerAttack = EntityContainer.getLengthInTowerRange(_senderNode, _targetNode, team) / 4.5; // 计算估损
                        _Ships += _towerAttack; // 为飞船数加上估损
                        if (_towerAttack > 0 && Globals.teamPops[team] < _towerAttack)
                            continue; // 总兵力不足估损时不派兵
                        if (Globals.level == 31)
                            if (_towerAttack > 0 && _senderNode.teamStrength(team) < _towerAttack * 2)
                                break; // 32关兵力不足估损二倍时换个目标
                        if (_towerAttack > 0 && _senderNode.teamStrength(team) < _towerAttack * 0.5)
                            continue; // 出兵天体强度低于估损的一半时不派兵
                        // if (Globals.level == 34 && _targetNode.x == 912 && _targetNode.y == 544)
                        // trace("attacking");
                        // traceDebug("attacking       " + _senderNode.x + "." + _senderNode.y + "  to  " + _targetNode.x + "." + _targetNode.y + "  ships:  " + _Ships);
                        NodeStaticLogic.sendAIShips(_senderNode, team, _targetNode, _Ships);
                        return;
                    }
                }
            }
            // #endregion
            // #region 聚兵
            senders.length = 0;
            for each (_Node in nodeArray) { // 计算出兵天体
                if (_Node.nodeData.team != team && _Node.predictedOppStrength(team) == 0 && _Node.teamStrength(team) > 0)
                    continue; // 条件：没在锁星
                if (_Node.predictedOppStrength(team) > 0 && _Node.predictedTeamStrength(team) > _Node.predictedOppStrength(team))
                    continue; // 条件：无敌方或打不过敌方
                _Node.aiStrength = -_Node.teamStrength(team) - _Node.oppStrength(team); // 计算己方和最强方的飞船总数
                _Node.aiValue = -_Node.oppNodeLinks.length; // 按路径数计算价值
                if (_Node.nodeData.type == NodeType.WARP)
                    _Node.aiValue--; // 传送权重提高
                senders.push(_Node);
            }
            senders.sortOn("aiStrength", 16); // 依飞船强度从小到大对出兵天体进行排序
            if (senders.length > 0) {
                targets.length = 0;
                for each (_Node in nodeArray) { // 计算目标天体
                    _Node.getOppLinks(team);
                    if (_Node.nodeData.type == NodeType.BARRIER || _Node.nodeData.type == NodeType.DILATOR)
                        continue; // 排除障碍星核
                    _Node.aiValue = -_Node.oppNodeLinks.length; // 按路径数计算价值
                    if (_Node.nodeData.type == NodeType.WARP)
                        _Node.aiValue--; // 传送权重提高
                    if (Globals.level == 31 && _Node.nodeData.type == NodeType.STARBASE)
                        _Node.aiValue--; // 32关堡垒权重提高
                    targets.push(_Node);
                }
                targets.sortOn("aiValue", 16);
                for each (_targetNode in targets) {
                    for each (_senderNode in senders) {
                        if (_senderNode == _targetNode || _senderNode.nodeLinks.indexOf(_targetNode) == -1)
                            continue; // 基本条件：出兵天体和目标天体不为同一个，且二者之间没有被拦截
                        if (_targetNode.aiValue >= _senderNode.aiValue)
                            continue; // 条件：目标天体价值高于出兵天体价值
                        _Ships = _senderNode.teamStrength(team); // 派出全部飞船
                        _towerAttack = EntityContainer.getLengthInTowerRange(_senderNode, _targetNode, team) / 4.5;
                        _Ships += _towerAttack; // 为飞船数加上估损
                        if (_towerAttack > 0 && Globals.teamPops[team] < _towerAttack)
                            continue; // 条件：总兵力不足估损时不派兵
                        if (Globals.level == 31)
                            if (!(_towerAttack > 0 && _senderNode.teamStrength(team) < _towerAttack * 3))
                                break; // 32关兵力不足估损三倍时换个目标
                        if (_towerAttack > 0 && _senderNode.teamStrength(team) < _towerAttack * 0.5)
                            continue; // 出兵天体强度低于估损的一半时不派兵
                        // if (Globals.level == 34 && _targetNode.x == 912 && _targetNode.y == 544)
                        // trace("repositioning");
                        // if (_Ships != 0)
                        //     traceDebug("repositioning   " + _senderNode.x + "." + _senderNode.y + "  to  " + _targetNode.x + "." + _targetNode.y + "  ships:  " + _Ships);
                        NodeStaticLogic.sendAIShips(_senderNode, team, _targetNode, _Ships);
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
