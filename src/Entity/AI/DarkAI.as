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
            var _Node:Node = null;
            var _dx:Number = NaN;
            var _dy:Number = NaN;
            var _Distence:Number = NaN;
            var _Strength:Number = NaN;
            var _targetNode:Node = null;
            var _senderNode:Node = null;
            var _Ships:Number = NaN;
            var _towerAttack:Number = NaN;
            var _CenterX:Number = 0;
            var _CenterY:Number = 0;
            var _NodeCount:Number = 0;
            for each (_Node in nodeArray) { // 计算己方天体的几何中心
                _Node.getTransitShips(team);
                if (_Node.nodeData.team != team)
                    continue;
                _CenterX += _Node.nodeData.x;
                _CenterY += _Node.nodeData.y;
                _NodeCount += 1;
            }
            _CenterX /= _NodeCount;
            _CenterY /= _NodeCount;
            for each (_Node in nodeArray) { // 分散星核兵力
                if (team == 6 && _Node.nodeData.type == NodeType.DILATOR && _Node.teamStrength(team) > 0) {
                    _Node.unloadShips();
                    return;
                }
            }
            // #region 进攻
            targets.length = 0;
            for each (_Node in nodeArray) { // 计算目标天体
                if (_Node.nodeData.team == team || _Node.nodeData.isUntouchable || _Node.nodeData.isAIinvisible)
                    continue; // 排除己方天体和星核障碍
                if (_Node.predictedOppStrength(team) == 0 && _Node.predictedTeamStrength(team) > _Node.nodeData.size * 200)
                    continue; // 条件1：天体未被己方以二倍标准兵力占据
                if (_Node.predictedOppStrength(team) > 0 && _Node.predictedTeamStrength(team) * 0.5 > _Node.predictedOppStrength(team))
                    continue; // 条件2：敌方无兵力或高于己方兵力一半
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
                        continue; // 基本条件：天体AI计时器为0且有己方飞船
                    if (_Node.predictedOppStrength(team) == 0 && _Node.capturing)
                        continue; // 条件1：没在锁星
                    if (_Node.nodeData.team != team && _Node.predictedTeamStrength(team) > _Node.predictedOppStrength(team))
                        continue; // 条件2：为己方天体或己方兵力不足敌方
                    if (_Node.predictedOppStrength(team) > 0 && _Node.predictedTeamStrength(team) > _Node.predictedOppStrength(team))
                        continue; // 条件3：敌方无兵力或己方兵力不足敌方
                    _Node.aiStrength = -_Node.teamStrength(team);
                    senders.push(_Node);
                }
                senders.sortOn("aiStrength", 16);
                for each (_targetNode in targets) {
                    for each (_senderNode in senders) {
                        if (_senderNode == _targetNode || _senderNode.nodeLinks[team].indexOf(_targetNode) == -1)
                            continue; // 基本条件：出兵天体和目标天体不为同一个，且二者之间没有被拦截
                        if (_senderNode.teamStrength(team) + _targetNode.predictedTeamStrength(team) < _targetNode.predictedOppStrength(team))
                            continue; // 出兵条件：出兵天体的强度和目标天体的预测强度之和高于目标天体的预测敌方强度
                        // 飞船数：目标天体上预测敌方强度的二倍减去预测己方强度一半
                        _Ships = _targetNode.predictedOppStrength(team) * 2 - _targetNode.predictedTeamStrength(team) * 0.5;
                        if (_senderNode.predictedOppStrength(team) > _senderNode.predictedTeamStrength(team))
                            _Ships = _senderNode.teamStrength(team); // 预测出兵天体敌方兵力高于己方兵力时派出全部兵力
                        if (_Ships < _targetNode.nodeData.size * 200)
                            _Ships = _targetNode.nodeData.size * 200; // 兵力不足目标二倍标准兵力时派出目标二倍标准兵力
                        _towerAttack = EntityContainer.getLengthInTowerRange(_senderNode, _targetNode, team) / 4.5;
                        _Ships += _towerAttack; // 加上估损
                        if (_towerAttack > 0 && Globals.teamPops[team] < _towerAttack)
                            continue; // 总兵力不足估损时不派兵
                        if (_towerAttack > 0 && _senderNode.teamStrength(team) < _towerAttack * 0.5)
                            continue; // 出兵天体的兵力不足估损的一半时不派兵
                        NodeStaticLogic.sendAIShips(_senderNode, team, _targetNode, _Ships);
                        return;
                    }
                }
            }
            // #endregion
            // #region 聚兵
            senders.length = 0;
            for each (_Node in nodeArray) { // 计算出兵天体
                if (_Node.nodeData.team != team || _Node.conflict)
                    continue; // 条件：为己方天体且无战争
                _Node.aiValue = -_Node.teamStrength(team);
                senders.push(_Node);
            }
            senders.sortOn("aiValue", 16);
            if (senders.length > 0) {
                targets.length = 0;
                for each (_Node in nodeArray) { // 计算目标天体
                    _Node.getOppLinks(team);
                    if (_Node.nodeData.isUntouchable || _Node.nodeData.isAIinvisible)
                        continue; // 排除星核障碍
                    _Node.aiValue = -_Node.oppNodeLinks.length; // 按路径数计算价值
                    if (_Node.nodeData.isWarp)
                        _Node.aiValue--; // 提高传送权重
                    if (Globals.level == 31 && _Node.nodeData.type == NodeType.STARBASE)
                        _Node.aiValue--; // 32关堡垒权重提高
                    targets.push(_Node);
                }
                targets.sortOn("aiValue", 16);
                for each (_senderNode in senders) {
                    for each (_targetNode in targets) {
                        if (_senderNode == _targetNode || _senderNode.nodeLinks[team].indexOf(_targetNode) == -1)
                            continue; // 基本条件：出兵天体和目标天体不为同一个，且二者之间没有被拦截
                        if (_targetNode.aiValue >= _senderNode.aiValue)
                            continue; // 条件：目标天体价值高于出兵天体价值
                        _Ships = _senderNode.teamStrength(team); // 派出该天体全部兵力
                        _towerAttack = EntityContainer.getLengthInTowerRange(_senderNode, _targetNode, team) / 4.5;
                        _Ships += _towerAttack; // 加上估损
                        if (_towerAttack > 0 && Globals.teamPops[team] < _towerAttack)
                            continue; // 总兵力不足估损时不派兵
                        if (_towerAttack > 0 && _senderNode.teamStrength(team) < _towerAttack * 0.5)
                            continue; // 出兵天体的兵力不足估损的一半时不派兵
                        NodeStaticLogic.sendAIShips(_senderNode, team, _targetNode, _Ships);
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
