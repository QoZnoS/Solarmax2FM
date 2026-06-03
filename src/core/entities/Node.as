package core.entities {
    import core.EntityContainer;
    import core.factories.NodeStateFactory;
    import core.node.NodeData;
    import core.node.NodeStaticLogic;
    import core.node.states.*;

    import flash.utils.Dictionary;

    import managers.Globals;

    import scenes.GameScene;

    import starling.text.TextField;

    import utils.Rng;
    import core.ai.SituationAssessor;

    public class Node extends GameEntity {
        // #region 类变量
        // 基本变量
        public var tag:int; // 标记符，debug用
        public var statePool:Dictionary;
        // 状态变量
        public var ships:Vector.<Vector.<Ship>>; // 第一维储存的每个数组对应一个势力，第二维数组用于储存飞船的引用，一个值指代一个飞船，二维数组的长度表示该天体上该势力的飞船总数
        public var nodeLinks:Vector.<Vector.<Node>>; // 各个势力在该天体上的飞船可到达的其他天体
        public var transitShips:Vector.<int>; // 飞向自身的飞船
        public var transitGroupShips:Vector.<int>; // 飞向自身的队伍的飞船
        public var rng:Rng;
        // AI相关变量
        public var aiValue:Number; // ai价值
        public var aiStrength:Number; // ai强度
        public var aiTimers:Array; // ai计时器
        public var oppNodeLinks:Vector.<Vector.<Node>>; // 各个势力可到达的有前往价值的天体
        public var breadthFirstSearchNode:Node; // hardAI 寻路，标记父节点
        public var senderType:String; // hardAI 出兵动机
        public var targetType:String; // hardAI 需求动机

        public var triggerTimer:Number; // 用于特殊事件
        public var linked:Boolean; // 是否被连接
        public var conflict:Boolean; // 战斗状态，判断天体上是否有战斗
        public var capturing:Boolean; // 占据状态

        public var nodeData:NodeData;
        public var shipActions:Vector.<Array>;

        // #endregion
        public function Node() {
            super();
            nodeLinks = new Vector.<Vector.<Node>>;
            shipActions = new Vector.<Array>;
            oppNodeLinks = new Vector.<Vector.<Node>>;
            statePool = NodeStateFactory.createStatePool(this);
        }

        private function resetArray():void {
            var textField:TextField = null; // 文本
            ships = new Vector.<Vector.<Ship>>; // 第一维储存的每个数组对应一个势力，第二维数组用于储存飞船的引用，一个值指代一个飞船，二维数组的长度表示该天体上该势力的飞船总数
            transitShips = new Vector.<int>();
            transitGroupShips = new Vector.<int>();
            aiTimers = [];
            for (var i:int = 0; i < Globals.teamCount; i++) {
                ships.push(new Vector.<Ship>);
                transitShips.push(0);
                transitGroupShips.push(0);
                aiTimers.push(0);
            }
        }

        // #region 生成天体 移除天体
        public function initNode(gameScene:GameScene, rng:Rng, data:Object):void {
            super.init(gameScene);
            this.rng = rng;
            resetArray();
            nodeData = new NodeData(true);
            NodeStaticLogic.changeType(this, data.type, data.size, data.rotation);
            NodeStaticLogic.changeTeam(this, data.team, false);
            nodeData.deserialize(data);
            deserializeState(data);
            aiValue = 0;
            triggerTimer = 0;
            linked = false;
            var i:int = 0;
            for (i = 0; i < aiTimers.length; i++)
                aiTimers[i] = 0;
            for (i = 0; i < transitShips.length; i++)
                transitShips[i] = 0;
            for each (var state:INodeState in statePool)
                state.init();
            NodeStaticLogic.updateLabelSizes(this);
        }

        private function deserializeState(data:Object):void {
            if (data.statePool == undefined)
                return;
            var registerState:Array = NodeStateFactory.registerStateArray;
            for (var key:String in data.statePool)
                if (registerState.indexOf(key) != -1)
                    statePool[key].deserialize(data.statePool[key])
        }

        override public function deInit():void {
            var i:int = 0;
            for (i = 0; i < ships.length; i++) { // 循环移除每个势力的飞船
                ships[i].length = 0; // 移除遍历势力飞船
                transitShips[i] = 0;
            }
            // 移除其他参数
            nodeLinks.length = 0;
            oppNodeLinks.length = 0;
            for each (var state:INodeState in statePool)
                state.deinit();
        }

        // #endregion
        // #region 更新
        override public function update(dt:Number):void {
            for each (var state:INodeState in statePool)
                if (state.enable)
                    state.update(dt);
            updateTimer(dt); // 更新各种计时器
            updateNodeLinks();
            updateShipAction();
            updateTransitShips();
            updateOppLinks();
            resetCache();
        }

        public function updateTimer(dt:Number):void {
            for (var i:int = 0; i < aiTimers.length; i++) // 计算AI计时器
                if (aiTimers[i] > 0)
                    aiTimers[i] = Math.max(0, aiTimers[i] - dt);
            if (triggerTimer > 0)
                triggerTimer = Math.max(0, triggerTimer - dt);
        }

        public function updateNodeLinks():void {
            if (nodeData.isBarrier)
                return;

            var globalNodes:Vector.<GameEntity> = EntityContainer.nodes;
            var teamCount:int = Globals.teamCount;
            var teamGroups:Array = Globals.teamGroups;
            var nodesLength:int = globalNodes.length;
            var nodeTeamGroup:int = teamGroups[nodeData.team];
            var isWarp:Boolean = nodeData.isWarp;

            // 确保数组长度正确
            while (nodeLinks.length < teamCount)
                nodeLinks.push(new Vector.<Node>);

            // 预计算nodeLinks[0]（基准列表）
            var baseLinks:Vector.<Node> = nodeLinks[0];
            var i:int, j:int, node:Node;
            // 填充基准列表
            for (j = 0; j < nodesLength; j++) {
                node = globalNodes[j] as Node;
                if (node == this || node.nodeData.isUntouchable)
                    continue;
                if (!EntityContainer.isBlocked(this, node))
                    baseLinks[baseLinks.length] = node; // 避免push调用
            }

            var baseLength:int = baseLinks.length;

            // 处理其他team
            for (i = 1; i < teamCount; i++) {
                var group:int = teamGroups[i];

                // 检查是否需要复制基准列表
                if (!(group == nodeTeamGroup && isWarp)) {
                    var targetLinks:Vector.<Node> = nodeLinks[i];
                    if (targetLinks.length != baseLength)
                        targetLinks.length = baseLength;
                    for (j = 0; j < baseLength; j++)
                        targetLinks[j] = baseLinks[j];
                    continue;
                }

                // 构建warp条件下的特殊列表
                nodeLinks[i].length = 0;
                var warpLinks:Vector.<Node> = nodeLinks[i];
                for (j = 0; j < nodesLength; j++) {
                    node = globalNodes[j] as Node;
                    if (node == this || node.nodeData.isUntouchable)
                        continue;
                    warpLinks[warpLinks.length] = node;
                }
            }
        }

        public function updateShipAction():void {
            for each (var action:Array in shipActions)
                NodeStaticLogic.moveShips(this, action[0], action[1], action[2]);
            shipActions.length = 0;
        }

        public function updateTransitShips():void {
            var group:int = Globals.teamGroups[nodeData.team];
            for (var i:int = 0; i < transitShips.length; i++) // 重置数组
                transitShips[i] = 0;
            for (i = 0; i < transitGroupShips.length; i++) // 重置数组
                transitGroupShips[i] = 0;
            for each (var ship:Ship in EntityContainer.ships) {
                var shipGroup:int = Globals.teamGroups[ship.team];
                if (!(ship.node == this && ship.state == 3))
                    continue; // 飞船在飞行中且飞向自身
                if (ship.jumpDist <= 50)
                    continue;
                transitShips[ship.team]++;
                transitGroupShips[shipGroup]++;
            }
        }

        private function hasOppStrength(node:Node, targetGroup:int):Boolean {
            var teamCount:int = Globals.teamCount;
            var teamGroups:Array = Globals.teamGroups;
            var shipsVec:Vector.<Vector.<Ship>> = node.ships;
            var transitVec:Vector.<int> = node.transitShips;
            for (var team:int = 0; team < teamCount; team++) {
                var oppGroup:int = teamGroups[team];
                if (oppGroup == targetGroup)
                    continue;
                if (shipsVec[team].length + transitVec[team] > 0)
                    return true;
            }
            return false;
        }
        // TODO: 按需调用
        public function updateOppLinks():void {
            if (nodeData.isBarrier)
                return;
            var group:int = Globals.teamGroups[nodeData.team];
            var teamCount:int = Globals.teamCount;
            var teamGroups:Array = Globals.teamGroups;
            while (oppNodeLinks.length < teamCount)
                oppNodeLinks.push(new Vector.<Node>);
            for (var i:int = 0; i < oppNodeLinks.length; i++)
                oppNodeLinks[i].length = 0;

            for (var t:int = 0; t < teamCount; t++) {
                var targetGroup:int = teamGroups[t];
                var links:Vector.<Node> = nodeLinks[t];
                var oppVec:Vector.<Node> = oppNodeLinks[t];
                var linkLen:int = links.length;
                for (var j:int = 0; j < linkLen; j++) {
                    var targetNode:Node = links[j];
                    if (targetNode == this)
                        continue;
                    var targetTeam:int = targetNode.nodeData.team;
                    var targetNodeGroup:int = teamGroups[targetTeam];
                    // 中立 或 不同组 → 直接加入
                    if (targetTeam == 0 || targetNodeGroup != group) {
                        oppVec.push(targetNode);
                        continue;
                    }
                    // 同组且非中立 → 需计算敌对强度
                    if (hasOppStrength(targetNode, targetGroup)) {
                        oppVec.push(targetNode);
                    }
                }
            }
        }

        public function resetCache():void {
            if (!nodeData.hard_oppAllStrengthCache)
                nodeData.hard_oppAllStrengthCache = new Vector.<int>(Globals.teamCount, true);
            for (var i:int = 0; i < Globals.teamCount; i++)
                nodeData.hard_oppAllStrengthCache[i] = -1;
        }

        // #endregion
        // #region AI工具及相关计算工具函数
        // 将飞船分配到周围天体上，按距离依次，兵力用完为止（传 送 门 分 兵
        public function unloadShips():void {
            var node:Node = null;
            var dx:Number = NaN;
            var dy:Number = NaN;
            var distance:Number = NaN;
            var ship:Number = NaN;
            var nodeArray:Vector.<GameEntity> = EntityContainer.nodes;
            var targetNode:Array = [];
            var shipArray:Array = [];
            for each (node in nodeArray) { // 按距离计算每个目标天体的价值
                if (node != this && !node.nodeData.isUntouchable) {
                    dx = node.nodeData.x - this.nodeData.x;
                    dy = node.nodeData.y - this.nodeData.y;
                    distance = Math.sqrt(dx * dx + dy * dy);
                    targetNode.push(node);
                }
            }
            targetNode.sortOn("aiValue", 16); // 按价值从小到大对目标天体排序
            var shipCount:int = int(ships[nodeData.team].length);
            for each (node in targetNode) {
                ship = SituationAssessor.predictedOppStrength(this, nodeData.team, false) * 2 - SituationAssessor.predictedTeamStrength(this, nodeData.team, false) * 0.5; // 飞船数：非己方预测强度二倍减去己方预测强度一半
                if (ship < node.nodeData.size * 200)
                    ship = node.nodeData.size * 200; // 不足200倍size时补齐到200倍size
                if (ship < shipCount) { // 未达到总飞船数时，从总飞船数中抽去这部分飞船
                    shipCount -= ship;
                    shipArray.push(ship);
                } else { // 达到或超过总飞船数时
                    if (shipArray.length > 0)
                        shipArray[shipArray.length - 1] += shipCount; // 将剩余飞船加在最后一项
                    else
                        shipArray.push(shipCount); // 没有项时添加这一项
                    shipCount = 0; // 清空总飞船数
                }
                if (shipCount == 0)
                    break; // 总飞船数耗尽时跳出循环
            }
            for (var i:int = 0; i < shipArray.length; i++)
                NodeStaticLogic.sendAIShips(this, nodeData.team, targetNode[i], shipArray[i]);
        }

        public function divideShips():void { // 均匀分散飞船
            var nodeArray:Vector.<GameEntity> = EntityContainer.nodes;
            var shipCount:int = int(ships[nodeData.team].length);
            var nodeCount:int = nodeArray.length - 1;
            for (var i:int = 0; i < nodeArray.length; i++) {
                if ((nodeArray[i] as Node).nodeData.isBarrier)
                    nodeCount--;
            }
            var shipNum:int = Math.max(int(shipCount / nodeCount), 1)
            if (shipCount > 0) {
                for (i = 0; i < nodeArray.length; i++) {
                    if (!(nodeArray[i] as Node).nodeData.isBarrier)
                        NodeStaticLogic.sendAIShips(this, nodeData.team, (nodeArray[i] as Node), shipNum);
                }
            }
        }

        // #endregion
        public function get basicState():NodeBasicState {
            return statePool[NodeStateFactory.BASIC] as NodeBasicState;
        }

        public function get moveState():NodeMoveState {
            return statePool[NodeStateFactory.MOVE] as NodeMoveState;
        }

        public function get attackState():NodeAttackState {
            return statePool[NodeStateFactory.ATTACK] as NodeAttackState;
        }

        public function get conflictState():NodeConflictState {
            return statePool[NodeStateFactory.CONFLICT] as NodeConflictState;
        }

        public function get captureState():NodeCaptureState {
            return statePool[NodeStateFactory.CAPTURE] as NodeCaptureState;
        }

        public function get buildState():NodeBuildState {
            return statePool[NodeStateFactory.BUILD] as NodeBuildState;
        }

        public function toJSON():* {
            var statePoolData:Object = {};
            for (var key:String in statePool)
                statePoolData[key] = statePool[key].toJSON(null);
            return {tag: tag,
                    nodeData: nodeData.toJSON(),
                    statePool: statePoolData,
                    aiTimers: aiTimers.concat(),
                    rng: rng.toJSON()};
        }
    }
}
