package Entity.AI {
    import utils.Rng;
    import Entity.Node;
    import flash.geom.Point;
    import Entity.Node.NodeStaticLogic;
    import Entity.Node.NodeType;
    import Entity.EntityContainer;

    public class HardAI extends BasicAI {
        public function HardAI(rng:Rng) {
            super(rng);
        }

        override public function update(dt:Number):void {
            if (!updateTimer(dt))
                return;
            updateHard();
        }

        public function updateHard():void {
            var surrender:Boolean = true;
            for each (var _Node:Node in nodeArray) {
                if (_Node.nodeData.team == this.team)
                    surrender = false; // 有己方天体则不认输
            }
            if (surrender && Globals.teamPops[team] < 30)
                return;
            if (team == 6 && nodeArray[0].nodeData.type == NodeType.DILATOR && nodeArray[0].hard_AllStrength(team) * 0.6 < nodeArray[0].hard_oppAllStrength(team)){
                blackDefend();
                return;
            }
            attackV1();
        }

        public function attackV1():void {
            var _Node:Node = null;
            var _Distance:Number = NaN;
            senders.length = 0;
            for each (_Node in nodeArray) {
                // 计算出兵天体
                if (!senderCheckBasic(_Node))
                    continue;
                if (_Node.hard_oppAllStrength(team) != 0 || _Node.conflict) {
                    // (预)战争状态
                    if (_Node.hard_teamStrength(team) * 0.6 > _Node.hard_oppAllStrength(team)) {
                        if (_Node.nodeData.team != team && _Node.hard_teamStrength(team) < _Node.nodeData.size * 200)
                            continue; // 保留占据兵力
                        senders.push(_Node); // 己方过强时出兵（损失不到五分之一）
                        _Node.senderType = "overflow"; // 类型：兵力溢出
                    } else if (_Node.hard_AllStrength(team) < _Node.hard_oppAllStrength(team)) {
                        if (!_Node.hard_retreatCheck(team))
                            continue; // 战术撤退时机检测
                        senders.push(_Node); // 己方过弱时出兵
                        _Node.senderType = "retreat"; // 类型：战术撤退
                    }
                    continue;
                }
                if (_Node.capturing) {
                    if (_Node.nodeData.team == 0 && (100 - _Node.nodeData.hp) / _Node.captureState.captureRate < 0.5 && _Node.nodeData.type != NodeType.WARP) {
                        senders.push(_Node); // 提前出兵
                        _Node.senderType = "attack"; // 类型：正常出兵
                    }
                    continue;
                }
                senders.push(_Node);
                _Node.senderType = "attackcom"; // 类型：正常出兵
            }
            if (senders.length == 0)
                return;
            targets.length = 0;
            for each (_Node in nodeArray) {
                // 计算目标天体
                if (!targetCheckBasic(_Node))
                    continue;
                if (_Node.hard_oppAllStrength(team) != 0) {
                    // (预)战争状态
                    if (_Node.hard_teamStrength(team) * 0.866 < _Node.hard_oppAllStrength(team)) {
                        targets.push(_Node); // 己方强度不足时作为目标（损失超过一半）
                        _Node.targetType = "lack"; // 类型：兵力不足
                    }
                    continue;
                }
                if (_Node.nodeData.team == 0 && _Node.capturing && _Node.captureState.captureTeam == team && (100 - _Node.nodeData.hp) / _Node.captureState.captureRate < _Node.aiValue / 50)
                    continue; // 不向快占完的天体派兵
                if (_Node.nodeData.team == team && _Node.nodeData.type != NodeType.WARP)
                    continue; // 除传送门不向己方天体派兵
                targets.push(_Node);
                _Node.targetType = "attack"; // 类型：正常目标
            }
            if (targets.length == 0)
                return;
            for each (var _senderNode:Node in senders) {
                // 出兵
                for each (var _targetNode:Node in targets) {
                    // 先排序
                    _Distance = calcDistence(_senderNode, _targetNode) + rng.nextNumber() * 32;
                    _targetNode.aiValue = _Distance * 0.8 + _targetNode.hard_oppAllStrength(team);
                    if (_targetNode.attackState.attackRate != 0)
                        _targetNode.aiValue += getTowerAIValue();
                    if (_targetNode.nodeData.type == NodeType.STARBASE)
                        _targetNode.aiValue -= Globals.teamCaps[0];
                    if (_targetNode.nodeData.type == NodeType.WARP)
                        _targetNode.aiValue += getWarpAIValue();
                    var _targetClose:Node = breadthFirstSearch(_senderNode, _targetNode);
                    if (!_targetClose)
                        continue;
                    var _towerAttack:Number = hard_getTowerAttack(_senderNode, _targetClose);
                    _targetNode.aiValue += _towerAttack * 4; // 估损权重
                }
                targets.sortOn("aiValue", 16);
                for each (_targetNode in targets) {
                    // 再派兵
                    _targetClose = breadthFirstSearch(_senderNode, _targetNode);
                    if (!_targetClose)
                        continue;
                    if (_targetClose.nodeData.type == NodeType.WARP && _senderNode.nodeData.type == NodeType.WARP && _senderNode.nodeData.team == team)
                        continue; // 避免传送门之间反复横跳
                    var _Ships:Number = _senderNode.hard_teamStrength(team);
                    if (_senderNode.senderType == "overflow") {
                        if (_senderNode.nodeData.team != team)
                            _Ships -= _senderNode.nodeData.size * 200; // 尝试占领时减少派兵数量
                        _Ships -= Math.floor(_senderNode.hard_oppAllStrength(team) * 1.667); // 兵力溢出时减少派兵数量
                    }
                    if (_targetNode.targetType == "lack") {
                        if (_targetNode.nodeData.team == team)
                            _Ships = Math.min(_Ships, Math.floor(_targetNode.hard_oppAllStrength(team) * 1.2 - _targetNode.hard_AllStrength(team)) + 4); // 目标兵力不足时防止派兵过度
                        else if (team != 6)
                            _Ships = Math.min(_Ships, Math.floor(_targetNode.hard_oppAllStrength(team) * 1.6 - _targetNode.hard_AllStrength(team))); // 目标兵力不足时防止派兵过度
                        else
                            _Ships = Math.min(_Ships, Math.floor(_targetNode.hard_oppAllStrength(team) * 2.4 - _targetNode.hard_AllStrength(team)) + 4); // 加强黑色分兵
                    }
                    _Ships = Math.max(_Ships, ((hard_distance(_senderNode, _targetNode) * _targetNode.buildState.buildRate / 50) * 1.2 + 3));
                    _towerAttack = hard_getTowerAttack(_senderNode, _targetClose);
                    if (_towerAttack > 0 && _Ships < _towerAttack + 30)
                        continue; // 派出的兵力不超估损30兵时不派兵
                    if (_Ships - _towerAttack < _targetNode.hard_oppAllStrength(team) - _targetNode.hard_teamStrength(team))
                        continue; // 己方兵力不足敌方时不派兵
                    NodeStaticLogic.sendAIShips(_senderNode, team, _targetClose, _Ships);
                    // traceDebug("attackV1: " + _senderNode.senderType + " " + _senderNode.tag + " -> " + _targetNode.tag + " " + _targetNode.targetType + " ships: " + _Ships + " guessDieShips: " + _towerAttack);
                    return;
                }
            }
        }

        public function blackDefend():void {
            // 回防
            var _boss:Node = nodeArray[0];
            if (_boss.conflict || _boss.capturing) {
                for each (var _Node:Node in nodeArray) {
                    if (!senderCheckBasic(_Node) || !moveCheckBasic(_Node, _boss))
                        continue;
                    if (_boss.hard_AllStrength(team) * 0.6 < _boss.hard_oppAllStrength(team))
                        NodeStaticLogic.sendAIShips(_Node, team, _boss, _Node.hard_teamStrength(team)); // 回防
                }
            }
        }

        public function senderCheckBasic(_Node:Node):Boolean {
            // 判断能否出兵
            if (_Node.hard_teamStrength(team) == 0)
                return false; // 无己方飞船不出兵
            return true;
        }

        public function targetCheckBasic(_Node:Node):Boolean {
            // 判断能否作为目标天体
            if (_Node.nodeData.type == NodeType.BARRIER || _Node.nodeData.type == NodeType.DILATOR)
                return false;
            return true;
        }

        public function moveCheckBasic(_senderNode:Node, _targetNode:Node):Boolean {
            // 移动判断
            if (_senderNode == _targetNode)
                return false;
            if (_senderNode.nodeData.type == NodeType.WARP && _senderNode.nodeData.team == team)
                return true;
            else if (_senderNode.nodeLinks[team].indexOf(_targetNode) != -1)
                return true;
            return false;
        }

        public function getTowerAIValue():Number {
            // 计算攻击天体价值
            var _capValue:Number = 0;
            for (var i:int = 1; i < Globals.teamCaps.length; i++) {
                _capValue += Globals.teamCaps[i];
            }
            return (Globals.teamCaps[0] - _capValue);
        }

        public function getWarpAIValue():Number {
            // 计算传送价值
            var _warpValue:Number = 0;
            for each (var _Node:Node in nodeArray) {
                _warpValue += _Node.nodeData.popVal;
                if (_Node.nodeData.team != 0 && _Node.nodeData.team != team)
                    _warpValue -= _Node.attackState.attackRange * 3.5;
            }
            return _warpValue;
        }

        public function breadthFirstSearch(_startNode:Node, _targetNode:Node):Node {
            // 广度优先搜索，寻路算法
            if (_startNode == _targetNode)
                return null;
            if (moveCheckBasic(_startNode, _targetNode))
                return _targetNode;
            clearbreadthFirstSearch();
            var _queue:Array = new Array();
            _queue.push(_startNode);
            var _visited:Array = new Array();
            _visited.push(_startNode);
            while (_queue.length > 0) {
                var _current:Node = _queue.shift();
                for each (var _next:Node in _current.nodeLinks[team]) {
                    if (_visited.indexOf(_next) != -1)
                        continue;
                    if (moveCheckBasic(_current, _next)) {
                        _queue.push(_next);
                        _visited.push(_next);
                        _next.breadthFirstSearchNode = _current;
                    }
                }
                if (_visited.indexOf(_targetNode) != -1) {
                    while (_current.breadthFirstSearchNode != null) {
                        if (_current.breadthFirstSearchNode == _startNode)
                            return _current;
                        _current = _current.breadthFirstSearchNode;
                    }
                }
            }
            return null;
        }

        public function calcDistence(_startNode:Node, _targetNode:Node):Number {
            // 计算寻路距离
            clearbreadthFirstSearch();
            if (_startNode == _targetNode)
                return 9999;
            if (moveCheckBasic(_startNode, _targetNode))
                return hard_distance(_startNode, _targetNode);
            var _distance:Number = 0;
            var _queue:Array = new Array();
            _queue.push(_startNode);
            var _visited:Array = new Array();
            _visited.push(_startNode);
            while (_queue.length > 0) {
                var _current:Node = _queue.shift();
                for each (var _next:Node in _current.nodeLinks[team]) {
                    if (_visited.indexOf(_next) != -1)
                        continue;
                    if (moveCheckBasic(_current, _next)) {
                        _queue.push(_next);
                        _visited.push(_next);
                        _next.breadthFirstSearchNode = _current;
                    }
                }
                if (_visited.indexOf(_targetNode) != -1) {
                    _distance += hard_distance(_current, _targetNode);
                    while (_current.breadthFirstSearchNode != null) {
                        _distance += hard_distance(_current, _current.breadthFirstSearchNode);
                        if (_current.breadthFirstSearchNode == _startNode)
                            return _distance;
                        _current = _current.breadthFirstSearchNode;
                    }
                }
            }
            return 9999;
        }

        // 清除广度优先搜索父节点
        public function clearbreadthFirstSearch():void {
            for each (var _Node:Node in nodeArray)
                _Node.breadthFirstSearchNode = null;
        }

        public function hard_getTowerAttack(_Node1:Node, _Node2:Node):Number {
            // 高精度估损
            var _Node:Node = null;
            var _start:Point = null;
            var _end:Point = null;
            var _current:Point = null;
            var _Length:Number = 0;
            var _towerAttack:Number = 0;
            var result:Array;
            var resultInside:Boolean; // 线是否在圆内
            var resultIntersects:Boolean; // 线和圆是否相交
            var resultEnter:Point; // 线和圆的第一个交点
            var resultExit:Point; // 线和圆的第二个交点
            if (_Node1.nodeData.type == NodeType.WARP && _Node1.nodeData.team == team)
                return 0; // 对传送门不执行该函数
            for each (_Node in nodeArray) {
                _Length = 0;
                if (_Node.nodeData.team == 0 || _Node.nodeData.team == team)
                    continue;
                if (_Node.attackState.attackRange != 0) {
                    _start = new Point(_Node1.nodeData.x, _Node1.nodeData.y);
                    _end = new Point(_Node2.nodeData.x, _Node2.nodeData.y);
                    _current = new Point(_Node.nodeData.x, _Node.nodeData.y);
                    result = EntityContainer.lineIntersectCircle(_start, _end, _current, _Node.attackState.attackRange);
                    resultInside = result[0], resultIntersects = result[1], resultEnter = result[2], resultExit = result[3];
                    if (resultIntersects) {
                        if (!resultEnter)
                            resultEnter = _start;
                        if (!resultExit)
                            resultExit = _end;
                        _Length += Point.distance(resultEnter, resultExit);
                    } else if (resultInside)
                        _Length += Point.distance(_start, _end);
                    if (_Node.nodeData.type == NodeType.TOWER || _Node.nodeData.type == NodeType.STARBASE || _Node.nodeData.type == NodeType.CAPTURESHIP)
                        _towerAttack += (_Length / Globals.teamShipSpeeds[team]) / _Node.attackState.attackRate;
                }
            }
            return Math.floor(_towerAttack);
        }

        public function hard_distance(_Node1:Node, _Node2:Node):Number {
            // 计算天体距离
            var _dx:Number = _Node2.nodeData.x - _Node1.nodeData.x;
            var _dy:Number = _Node2.nodeData.y - _Node1.nodeData.y;
            return Math.sqrt(_dx * _dx + _dy * _dy);
        }

        override public function get type():String {
            return EnemyAIFactory.HARD;
        }
    }
}
