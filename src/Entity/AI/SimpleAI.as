package Entity.AI {
    import Entity.Node;
    import Game.GameScene;
    import Entity.EntityContainer;
    import utils.Rng;
    import Entity.Node.NodeStaticLogic;
    import Entity.Node.NodeType;
    import Entity.EntityContainer;

    public class SimpleAI extends BasicAI {

        public function SimpleAI(rng:Rng) {
            super(rng)
        }

        override public function update(dt:Number):void {
            if (!updateTimer(dt))
                return;
            updateSimple()
        }

        public function updateSimple():void {
            if (Globals.teamCaps[team] == 0 && Globals.teamPops[team] < 40)
                return; // 上限为0且总飞船数少于40时挂机
            var _Node:Node = null;
            var _dx:Number = NaN;
            var _dy:Number = NaN;
            var _Distance:Number = NaN;
            var _Strength:Number = NaN;
            var _targetNode:Node = null;
            var _senderNode:Node = null;
            var _Ships:int = 0;
            var _NodeArray:Vector.<Node> = nodeArray;
            var _CenterX:Number = 0;
            var _CenterY:Number = 0;
            var _NodeCount:Number = 0;
            for each (_Node in _NodeArray) { // 计算己方天体的几何中心
                if (_Node.nodeData.team != team)
                    continue;
                _CenterX += _Node.nodeData.x;
                _CenterY += _Node.nodeData.y;
                _NodeCount += 1;
            }
            _CenterX /= _NodeCount;
            _CenterY /= _NodeCount;
            // #region 防御部分
            targets.length = 0;
            for each (_Node in _NodeArray) { // 计算目标天体
                _Node.getTransitShips(team);
                if (_Node.nodeData.team != team && _Node.predictedTeamStrength(team) == 0)
                    continue; // 条件1：为己方天体或有己方飞船（包括飞行中的
                if (_Node.predictedTeamStrength(team) > _Node.predictedOppStrength(team) * 2)
                    continue; // 条件2：预测己方强度低于敌方两倍（即可能打不过敌方
                if (_Node.nodeData.type == NodeType.BARRIER)
                    continue; // 排除障碍
                _dx = _Node.nodeData.x - _CenterX;
                _dy = _Node.nodeData.y - _CenterY;
                _Distance = Math.sqrt(_dx * _dx + _dy * _dy); // 该天体到己方天体几何中心的距离
                _Strength = _Node.predictedTeamStrength(team) - _Node.predictedOppStrength(team); // 己方势力强度减去非己方势力强度
                _Node.aiValue = _Distance + _Strength; // 计算ai价值
                targets.push(_Node);
            }
            targets.sortOn("aiValue", 16); // 依ai价值从小到大对targets进行排序
            // trace("defend targets: " + targets.length);
            if (targets.length > 0) { // 目标存在时，出兵防守
                senders.length = 0;
                for each (_Node in _NodeArray) { // 统计出兵天体
                    if (_Node.aiTimers[team] > 0 || _Node.teamStrength(team) == 0)
                        continue; // 基本条件：该天体己方ai倒计时为0且该天体己方强度不为0
                    if (_Node.nodeData.conflict && _Node.predictedTeamStrength(team) > _Node.predictedOppStrength(team))
                        continue; // 条件：没有战争或预测己方强度低于敌方
                    _Node.aiStrength = -_Node.teamStrength(team); // 将该天体己方强度记为飞船数的相反数
                    senders.push(_Node);
                }
                senders.sortOn("aiStrength", 16); // 依己方强度从小到大对出兵天体进行排序（由于强度记录的是相反数，此时看绝对值则是从大到小
                // trace("defend senders: " + senders.length);
                for each (_targetNode in targets) { // 防守判定
                    for each (_senderNode in senders) {
                        if (_senderNode == _targetNode || EntityContainer.nodesBlocked(_senderNode, _targetNode))
                            continue; // 基本条件：出兵天体和目标天体不为同一个，且二者之间没有被拦截
                        if (_senderNode.teamStrength(team) + _targetNode.predictedTeamStrength(team) <= _targetNode.predictedOppStrength(team))
                            continue; // 出兵条件：出兵天体的强度和目标天体的预测强度之和高于目标天体的预测敌方强度
                        // 飞船数：目标天体上预测敌方强度的二倍减去预测己方强度
                        _Ships = _targetNode.predictedOppStrength(team) * 2 - _targetNode.predictedTeamStrength(team);
                        NodeStaticLogic.sendAIShips(_senderNode, team, _targetNode, _Ships); // 发送飞船
                        // trace("defending!");
                        return; // 终止此次ai行动
                    }
                }
            }
            // trace("can't defend, or nothing to defend");
            // #endregion
            // #region 进攻部分
            targets.length = 0;
            for each (_Node in _NodeArray) { // 计算目标天体
                if (_Node.nodeData.team == team || _Node.nodeData.type == NodeType.BARRIER || _Node.nodeData.type == NodeType.DILATOR)
                    continue; // 基本条件：不为己方天体且不为障碍星核
                if (_Node.nodeData.team == 0 && _Node.predictedOppStrength(team) == 0 && _Node.predictedTeamStrength(team) > _Node.nodeData.size * 100)
                    continue; // 目标条件：不为中立或预测有非己方飞船或己方势力飞船不足100倍size（基本兵力上限）
                _dx = _Node.nodeData.x - _CenterX;
                _dy = _Node.nodeData.y - _CenterY;
                _Distance = Math.sqrt(_dx * _dx + _dy * _dy) + rng.nextNumber() * 32; // 计算距离，带32px随机数误差
                _Strength = _Node.predictedOppStrength(team) - _Node.predictedTeamStrength(team); // 计算敌方强度：预测敌方强度减去预测己方强度
                _Node.aiValue = _Distance + _Strength; // 计算ai价值：距离加上敌方强度
                targets.push(_Node);
            }
            targets.sortOn("aiValue", 16); // 依ai价值从小到大对targets进行排序
            // trace("attack targets: " + targets.length);
            // trace("teamStr: " + targets[0].predictedTeamStrength(team));
            if (targets.length > 0) { // 目标存在时，出兵进攻
                senders.length = 0;
                for each (_Node in _NodeArray) { // 统计出兵天体
                    if (_Node.aiTimers[team] > 0 || _Node.teamStrength(team) == 0)
                        continue; // 基本条件：该天体己方ai倒计时为0且该天体己方强度不为0
                    if (_Node.nodeData.conflict && _Node.predictedTeamStrength(team) > _Node.predictedOppStrength(team))
                        continue; // 出兵条件：天体上没有战争或预测敌方强度高于预测己方强度
                    _Node.aiStrength = -_Node.teamStrength(team); // 将该天体己方强度记为飞船数的相反数
                    senders.push(_Node);
                }
                senders.sortOn("aiStrength", 16); // 依己方强度从小到大对出兵天体进行排序（由于强度记录的是相反数，此时看绝对值则是从大到小
                // trace("attack senders: " + senders.length);
                for each (_targetNode in targets) { // 进攻判定
                    for each (_senderNode in senders) {
                        if (_senderNode == _targetNode || EntityContainer.nodesBlocked(_senderNode, _targetNode))
                            continue; // 基本条件：出兵天体和目标天体不为同一个，且二者之间没有被拦截
                        if (_senderNode.teamStrength(team) + _targetNode.predictedTeamStrength(team) <= _targetNode.predictedOppStrength(team))
                            continue; // 出兵条件：出兵天体的强度和目标天体的预测强度之和高于目标天体的预测敌方强度
                        // 计算出兵兵力，默认为预测目标天体上敌方兵力的二倍与己方兵力一半的差值
                        _Ships = _targetNode.predictedOppStrength(team) * 2 - _targetNode.predictedTeamStrength(team) * 0.5;
                        if (_targetNode.predictedOppStrength(team) * 2 - _targetNode.predictedTeamStrength(team) * 0.5 < _targetNode.nodeData.size * 200)
                            _Ships = _targetNode.nodeData.size * 200; // 若出兵兵力不足二倍目标天体标准兵力，则增加至二倍目标天体标准兵力
                        if (_senderNode.predictedOppStrength(team) > _senderNode.predictedTeamStrength(team))
                            _Ships = _senderNode.teamStrength(team); // 若预测出兵天体所受敌方威胁高于其强度，则派出全部兵力
                        NodeStaticLogic.sendAIShips(_senderNode, team, _targetNode, _Ships);
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
