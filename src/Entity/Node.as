/* 计时器基本原理：取一个初始值，每帧为其减去这一帧的时间，计时归零时执行相应函数并重置计时器
   需要的新功能：天体实时生成与摧毁

   ai计时器：具有同等于势力数的项数，每一项均为倒计时
   发送ai飞船时重置计时器为1s，ai统计出兵天体时只统计计时器为0的天体（存在特例）
   相当于单个天体的AI出兵冷却时间，由 EnemyAI.as 决定是否采用

   障碍机制：障碍生成时执行getBarrierLinks()计算需连接的障碍存进barrierLinks，这是单个障碍的一维数组
   接着GameScene.as中执行getBarrierLines()计算所有障碍连接并存进barrierLines，这是单局游戏的二维数组，每一项均为需连接的[障碍A，障碍B]
   接着GameScene.as中执行addBarriers()绘制障碍线

   天体状态：
   conflict：战争，存在两方及以上势力飞船时判定
   capturing：占据，仅存在非己方势力飞船时判定

   warps数组用于处理传送门目的地的特效，原理如下：
   sendShips()或sendAIShips()中执行Ship.as中的warpTo()，飞船依次经过12阶段
   在起飞阶段到达目的地后将目的地天体的warps中对应势力项改为true，接着天体在update()中检测warps数组播放特效
 */
package Entity {
    import Game.GameScene;
    import Entity.GameEntity;
    import starling.text.TextField;
    import Entity.EntityHandler;
    import Entity.EntityContainer;
    import utils.Rng;
    import utils.GS;
    import utils.Drawer;
    import Entity.Node.NodeStaticLogic;
    import Entity.Node.NodeData;
    import Entity.Node.NodeType;
    import flash.utils.Dictionary;
    import Entity.Node.States.*;

    public class Node extends GameEntity {
        // #region 类变量
        // 基本变量
        public var tag:int; // 标记符，debug用
        public var statePool:Dictionary;
        // 状态变量
        public var ships:Vector.<Vector.<Ship>>; // 第一维储存的每个数组对应一个势力，第二维数组用于储存飞船的引用，一个值指代一个飞船，二维数组的长度表示该天体上该势力的飞船总数
        public var nodeLinks:Vector.<Vector.<Node>>; // 
        public var rng:Rng;
        // AI相关变量
        public var aiValue:Number; // ai价值
        public var aiStrength:Number; // ai强度
        public var aiTimers:Array; // ai计时器
        public var transitShips:Array; // 
        public var oppNodeLinks:Array; // 
        public var breadthFirstSearchNode:Node; // hardAI 寻路，标记父节点
        public var senderType:String; // hardAI 出兵动机
        public var targetType:String; // hardAI 需求动机
        // 贴图相关变量
        public var triggerTimer:Number; // 用于特殊事件
        // 其他变量
        public var linked:Boolean; // 是否被连接
        public var conflict:Boolean; // 战斗状态，判断天体上是否有战斗
        public var capturing:Boolean; // 占据状态

        public var nodeData:NodeData;

        // #endregion
        public function Node() {
            super();
            nodeLinks = new Vector.<Vector.<Node>>;
            oppNodeLinks = [];
            statePool = NodeStateFactory.createStatePool(this);
        }

        private function resetArray():void {
            var textField:TextField = null; // 文本
            ships = new Vector.<Vector.<Ship>>; // 第一维储存的每个数组对应一个势力，第二维数组用于储存飞船的引用，一个值指代一个飞船，二维数组的长度表示该天体上该势力的飞船总数
            transitShips = [];
            aiTimers = [];
            for (var i:int = 0; i < Globals.teamCount; i++) {
                ships.push(new Vector.<Ship>);
                transitShips.push(0);
                aiTimers.push(0);
            }
        }

        // #region 生成天体 移除天体
        public function oldInitNode(_GameScene:GameScene, _rng:Rng, _x:Number, _y:Number, _type:int, _size:Number, _team:int, _OrbitNode:Node = null, _Clockwise:Boolean = true, _OrbitSpeed:Number = 0.1):void {
            super.init(_GameScene);
            nodeData = new NodeData(true);
            nodeData.size = _size;
            NodeStaticLogic.changeTeam(this, _team, false)
            nodeData.type = NodeType.switchType(_type);
            nodeData.x = _x;
            nodeData.y = _y;
            if (_OrbitNode)
                nodeData.orbitNode = _OrbitNode.tag;
            else
                nodeData.orbitNode = -1;
            if (_Clockwise)
                nodeData.orbitSpeed = _OrbitSpeed;
            else
                nodeData.orbitSpeed = -_OrbitSpeed;
            this.rng = _rng;
            resetArray()
            aiValue = 0;
            triggerTimer = 0;
            NodeStaticLogic.updateLabelSizes(this);
            linked = false;
            NodeStaticLogic.changeType(this, NodeType.switchType(_type), _size);
            var i:int = 0;
            for (i = 0; i < aiTimers.length; i++)
                aiTimers[i] = 0;
            for (i = 0; i < transitShips.length; i++)
                transitShips[i] = 0;
            for each(var state:INodeState in statePool)
                state.init()
        }

        public function initNode(gameScene:GameScene, rng:Rng, data:Object):void {
            super.init(gameScene);
            this.rng = rng;
            resetArray();
            nodeData = new NodeData(true);
            NodeStaticLogic.changeType(this, data.type, data.size);
            NodeStaticLogic.changeTeam(this, data.team, false);
            NodeStaticLogic.updateLabelSizes(this);
            nodeData.deserialize(data);
            aiValue = 0;
            triggerTimer = 0;
            linked = false;
            var i:int = 0;
            for (i = 0; i < aiTimers.length; i++)
                aiTimers[i] = 0;
            for (i = 0; i < transitShips.length; i++)
                transitShips[i] = 0;
            for each(var state:INodeState in statePool)
                state.init();
        }

        public function initBoss(_GameScene:GameScene, _rng:Rng, _x:Number, _y:Number):void {
            var i:int = 0;
            super.init(_GameScene);
            nodeData = new NodeData(true);
            nodeData.size = 0.4;
            nodeData.type = NodeType.DILATOR;
            nodeData.team = 6;
            this.rng = _rng;
            nodeData.hp = 100;
            resetArray()
            aiValue = 0;
            triggerTimer = 0;
            NodeStaticLogic.updateLabelSizes(this);
            nodeData.x = _x;
            nodeData.y = _y;
            nodeData.lineDist = 150 * nodeData.size;
            linked = false;
            NodeStaticLogic.changeType(this, NodeType.DILATOR, 0.4);
            nodeData.popVal = 0;
            nodeData.startShips[6] = 300;
            for (i = 0; i < aiTimers.length; i++) {
                aiTimers[i] = 0;
            }
            for (i = 0; i < transitShips.length; i++) {
                transitShips[i] = 0;
            }
        }

        override public function deInit():void {
            var i:int = 0;
            for (i = 0; i < ships.length; i++) // 循环移除每个势力的飞船
            {
                ships[i].length = 0; // 移除遍历势力飞船
                transitShips[i] = 0;
            }
            // 移除其他参数
            nodeLinks.length = 0;
            oppNodeLinks.length = 0;
            for each(var state:INodeState in statePool)
                state.deinit();
        }

        // #endregion
        // #region 更新
        override public function update(dt:Number):void {
            for each(var state:INodeState in statePool)
                if (state.enable)
                    state.update(dt);
            updateTimer(dt); // 更新各种计时器
            updateNodeLinks();
        }

        public function updateTimer(_dt:Number):void {
            for (var i:int = 0; i < aiTimers.length; i++) // 计算AI计时器
                if (aiTimers[i] > 0)
                    aiTimers[i] = Math.max(0, aiTimers[i] - _dt);
            if (triggerTimer > 0)
                triggerTimer = Math.max(0, triggerTimer - _dt);
        }

        public function updateAttack(_dt:Number):void {
            if (nodeData.team == 0 && Globals.level != 31)
                return; // 排除32关以外的中立和无范围天体
        }
        
        public function updateNodeLinks():void {
            if (nodeData.isUntouchable)
                return;
            nodeLinks.length = Globals.teamCount;
            for (var i:int = 0; i < Globals.teamCount; i++) {
                if (!nodeLinks[i])
                    nodeLinks[i] = new Vector.<Node>;
                else
                    nodeLinks[i].length = 0;
                if (i != 0 && !(i == nodeData.team && nodeData.isWarp)){
                    nodeLinks[i] = nodeLinks[0].concat();
                    continue;
                }
                for each (var _Node:Node in EntityContainer.nodes) {
                    if (_Node == this || _Node.nodeData.isUntouchable || (_Node.nodeData.type == NodeType.DILATOR && Globals.level != 35))
                        continue;
                    if (nodeData.isWarp && nodeData.team == i && i != 0){
                        nodeLinks[i].push(_Node);
                        continue;
                    }
                    if (EntityContainer.nodesBlocked(this, _Node) == null)
                        nodeLinks[i].push(_Node);
                }
            }
        }

        // #endregion
        // #region AI工具及相关计算工具函数

        // 将飞船分配到周围天体上，按距离依次，兵力用完为止（传 送 门 分 兵
        public function unloadShips():void {
            var _Node:Node = null;
            var _dx:Number = NaN;
            var _dy:Number = NaN;
            var _Distance:Number = NaN;
            var _Ship:Number = NaN;
            var _NodeArray:Vector.<Node> = EntityContainer.nodes;
            var _targetNode:Array = [];
            var _ShipArray:Array = [];
            for each (_Node in _NodeArray) // 按距离计算每个目标天体的价值
            {
                if (_Node != this && !_Node.nodeData.isUntouchable) {
                    _dx = _Node.nodeData.x - this.nodeData.x;
                    _dy = _Node.nodeData.y - this.nodeData.y;
                    _Distance = Math.sqrt(_dx * _dx + _dy * _dy);
                    _Node.aiValue = _Distance;
                    _targetNode.push(_Node);
                }
            }
            _targetNode.sortOn("aiValue", 16); // 按价值从小到大对目标天体排序
            var _ShipCount:int = int(ships[nodeData.team].length);
            for each (_Node in _targetNode) {
                _Ship = _Node.predictedOppStrength(nodeData.team) * 2 - _Node.predictedTeamStrength(nodeData.team) * 0.5; // 飞船数：非己方预测强度二倍减去己方预测强度一半
                if (_Ship < _Node.nodeData.size * 200)
                    _Ship = _Node.nodeData.size * 200; // 不足200倍size时补齐到200倍size
                if (_Ship < _ShipCount) // 未达到总飞船数时，从总飞船数中抽去这部分飞船
                {
                    _ShipCount -= _Ship;
                    _ShipArray.push(_Ship);
                } else // 达到或超过总飞船数时
                {
                    if (_ShipArray.length > 0)
                        _ShipArray[_ShipArray.length - 1] += _ShipCount; // 将剩余飞船加在最后一项
                    else
                        _ShipArray.push(_ShipCount); // 没有项时添加这一项
                    _ShipCount = 0; // 清空总飞船数
                }
                if (_ShipCount == 0)
                    break; // 总飞船数耗尽时跳出循环
            }
            for (var i:int = 0; i < _ShipArray.length; i++) {
                NodeStaticLogic.sendAIShips(this, nodeData.team, _targetNode[i], _ShipArray[i]);
            }
        }

        // 统计飞向自身的飞船，包括指定势力的和移动距离大于50px的
        public function getTransitShips(_team:int):void {
            for (var i:int = 0; i < transitShips.length; i++) // 重置数组
                transitShips[i] = 0;
            for each (var _Ship:Ship in EntityContainer.ships) {
                if (!(_Ship.node == this && _Ship.state == 3))
                    continue; // 飞船在飞行中且飞向自身
                if (_Ship.team == _team || _Ship.jumpDist > 50)
                    transitShips[_Ship.team]++; // 为参数势力或移动距离大于50px
            }
        }

        // 返回飞船数最多的势力的总飞船数
        public function oppStrength(_team:int):int {
            var _Strength:int = 0;
            for (var i:int = 0; i < ships.length; i++) {
                if (i != _team) {
                    if (ships[i].length > _Strength)
                        _Strength = int(ships[i].length);
                }
            }
            return _Strength;
        }

        // 估算后续可能面对的非指定势力方最强飞船强度
        public function predictedOppStrength(_team:int):int {
            var _Strength:Number = NaN;
            var _preStrength:int = 0;
            for (var i:int = 0; i < ships.length; i++) {
                if (i == _team)
                    continue;
                _Strength = ships[i].length + transitShips[i];
                if (buildState.buildRate > 0 && nodeData.team == i)
                    _Strength *= 1.25;
                if (_Strength > _preStrength)
                    _preStrength = _Strength;
            }
            return _preStrength;
        }

        // 返回该势力飞船数
        public function teamStrength(_team:int):int {
            return Number(ships[_team].length);
        }

        // 预测该势力可能的强度
        public function predictedTeamStrength(_team:int):int {
            var _Strength:Number = ships[_team].length + transitShips[_team];
            if (buildState.buildRate > 0 && _team == nodeData.team)
                _Strength *= 1.25;
            return _Strength;
        }

        // 计算可到达的有前往价值的天体
        public function getOppLinks(_team:int):void {
            oppNodeLinks.length = 0;
            for each (var _Node:Node in nodeLinks[_team]) {
                if (_Node == this)
                    continue;
                if (_Node.nodeData.team == 0 || _Node.nodeData.team != _team || _Node.predictedOppStrength(_team) > 0)
                    oppNodeLinks.push(_Node);
            }
        }

        // #endregion
        // #region hardAI 特制工具函数

        // 返回飞向自身的最强非己方飞船数
        public function hard_getOppTransitShips(_team:int):int {
            var _ships:Array = [];
            for (var i:int = 0; i < Globals.teamCount; i++) {
                _ships.push([]);
            }
            for each (var _Ship:Ship in EntityContainer.ships) {
                if (_Ship.state == 0 || _Ship.node != this)
                    continue; // 排除未起飞的和不飞向自身的飞船
                _ships[_Ship.team].push(_Ship);
            }
            var _maxShips:int = 0;
            for (i = 0; i < Globals.teamCount; i++) {
                if (i == _team)
                    continue; // 排除己方
                _maxShips = Math.max(_maxShips, _ships[i].length); // 取最强的非己方飞船
            }
            return _maxShips;
        }

        // 返回指定势力的飞船数
        public function hard_teamStrength(_team:int):int {
            var _Strength:int = 0;
            for each (var _Ship:Ship in ships[_team]) {
                if (_Ship.state == 0)
                    _Strength++;
            }
            return _Strength;
        }

        // 返回自身综合强度
        public function hard_AllStrength(_team:int):int {
            var _Strength:int = 0;
            for each (var _Ship:Ship in EntityContainer.ships) {
                if (_Ship.node == this && _Ship.team == _team)
                    _Strength++;
            }
            return _Strength;
        }

        // 返回敌方综合强度
        public function hard_oppAllStrength(_team:int):int {
            var _ships:Array = [];
            for (var i:int = 0; i < Globals.teamCount; i++) {
                _ships.push([]);
            }
            for each (var _Ship:Ship in EntityContainer.ships) {
                if (_Ship.node == this && _Ship.team != _team)
                    _ships[_Ship.team].push(_Ship);
            }
            _ships.sortOn("length", 16); // 按飞船数从小到大排序
            return _ships[_ships.length - 1].length; // 取最强的非己方势力的飞船数
        }

        // 检查撤退时机是否合理
        public function hard_retreatCheck(_team:int):Boolean {
            var _ships:Array = [];
            for (var i:int = 0; i < Globals.teamCount; i++) {
                _ships.push([]);
            }
            for each (var _Ship:Ship in EntityContainer.ships) {
                if (_Ship.node != this || _Ship.team == _team)
                    continue; // 排除不飞向自身的飞船和己方飞船
                if (_Ship.targetDist / _Ship.jumpSpeed < 1 || _Ship.state == 0)
                    _ships[_Ship.team].push(_Ship); // 记录一秒后抵达的和已经抵达的飞船数
            }
            _ships.sortOn("length", 16); // 按飞船数从小到大排序
            if (_ships[_ships.length - 1].length > hard_AllStrength(_team))
                return true;
            return false;
        }

        // #endregion
        // 计算需连接的障碍
        public function getBarrierLinks():void {
            var _dx:Number = NaN;
            var _dy:Number = NaN;
            for each (var _Node:Node in EntityContainer.nodes) {
                if (_Node == this || !_Node.nodeData.isBarrier)
                    continue;
                if (_Node.nodeData.x != nodeData.x && _Node.nodeData.y != nodeData.y)
                    continue; // 横纵坐标至少有一个相等
                _dx = _Node.nodeData.x - nodeData.x;
                _dy = _Node.nodeData.y - nodeData.y;
                if (Math.sqrt(_dx * _dx + _dy * _dy) < 180)
                    nodeData.barrierLinks.push(_Node.tag);
            }
        }
        // #region 特效与绘图
        public function bossAppear():void {
            moveState.image.visible = false;
            moveState.halo.visible = false;
            moveState.glow.visible = false;
            var _delay:Number = 0;
            var _rate:Number = 1;
            var _delayStep:Number = 0.5;
            var _angle:Number = 1.5707963267948966;
            var _maxSize:Number = 2;
            for (var i:int = 0; i < 24; i++) {
                FXHandler.addDarkPulse(this, 0, 1, _maxSize, _rate, _angle, _delay);
                _delay += _delayStep;
                _angle += 2.0943951023931953;
                FXHandler.addDarkPulse(this, 0, 1, _maxSize, _rate, _angle, _delay);
                _delay += _delayStep;
                _angle += 2.0943951023931953;
                FXHandler.addDarkPulse(this, 0, 1, _maxSize, _rate, _angle, _delay);
                _delay += _delayStep;
                _angle += 2.0943951023931953;
                _rate *= 1.15;
                _delayStep *= 0.75;
                _maxSize *= 0.9;
            }
            FXHandler.addDarkPulse(this, 0, 2, 2, 2, 0, _delay - 0.75);
            FXHandler.addDarkPulse(this, 0, 2, 2, 2, 0, _delay - 0.4);
            triggerTimer = _delay;
        }

        public function bossReady():void {
            moveState.image.visible = true;
            moveState.halo.visible = true;
            moveState.glow.visible = true;
            var _delay:Number = 0;
            var _angle:Number = 1.5707963267948966;
            var _maxSize:Number = 1;
            for (var i:int = 0; i < 3; i++) {
                FXHandler.addDarkPulse(this, 0, 0, _maxSize, 2, _angle, _delay);
                _delay += 0.05;
                _angle += 2.0943951023931953;
                FXHandler.addDarkPulse(this, 0, 0, _maxSize, 2, _angle, _delay);
                _delay += 0.05;
                _angle += 2.0943951023931953;
                FXHandler.addDarkPulse(this, 0, 0, _maxSize, 2, _angle, _delay);
                _delay += 0.05;
                _angle += 2.0943951023931953;
                _maxSize *= 1.5;
            }
            aiTimers[6] = 0.5;
        }

        public function bossDisappear():void {
            var _delay:Number = 0;
            var _rate:Number = 1;
            var _delayStep:Number = 0.5;
            var _angle:Number = 1.5707963267948966;
            var _maxSize:Number = 2;
            for (var i:int = 0; i < 12; i++) {
                FXHandler.addDarkPulse(this, 0, 1, _maxSize, _rate, _angle, _delay);
                _delay += _delayStep;
                _angle += 2.0943951023931953;
                FXHandler.addDarkPulse(this, 0, 1, _maxSize, _rate, _angle, _delay);
                _delay += _delayStep;
                _angle += 2.0943951023931953;
                FXHandler.addDarkPulse(this, 0, 1, _maxSize, _rate, _angle, _delay);
                _delay += _delayStep;
                _angle += 2.0943951023931953;
                _rate *= 1.5;
                _delayStep *= 0.5;
                _maxSize *= 0.7;
            }
            FXHandler.addDarkPulse(this, 0, 2, 2, 2, 0, _delay - 0.75);
            triggerTimer = _delay;
        }

        public function bossHide():void {
            moveState.image.visible = false;
            moveState.halo.visible = false;
            moveState.glow.visible = false;
            active = false;
        }

        public function fireBeam(_Ship:Ship):void {
            FXHandler.addBeam(this, _Ship); // 播放攻击特效
            GS.playLaser(nodeData.x); // 播放攻击音效
        }
        // #endregion

        public function get basicState():NodeBasicState{
            return statePool[NodeStateFactory.BASIC] as NodeBasicState;
        }

        public function get moveState():NodeMoveState{
            return statePool[NodeStateFactory.MOVE] as NodeMoveState;
        }

        public function get attackState():NodeAttackState{
            return statePool[NodeStateFactory.ATTACK] as NodeAttackState;
        }

        public function get conflictState():NodeConflictState{
            return statePool[NodeStateFactory.CONFLICT] as NodeConflictState; 
        }

        public function get captureState():NodeCaptureState{
            return statePool[NodeStateFactory.CAPTURE] as NodeCaptureState;
        }

        public function get buildState():NodeBuildState{
            return statePool[NodeStateFactory.BUILD] as NodeBuildState;
        }
    }
}
