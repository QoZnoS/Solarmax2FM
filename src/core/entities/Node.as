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
    import flash.geom.Point;

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
        public var transitShips:Vector.<int>; //
        public var transitGroupShips:Vector.<int>;
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
        public var shipActions:Vector.<Array>;

        // #endregion
        public function Node() {
            super();
            nodeLinks = new Vector.<Vector.<Node>>;
            shipActions = new Vector.<Array>;
            oppNodeLinks = [];
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
                if (transitGroupShips.length < Globals.teamGroups[i] + 1) {
                    transitGroupShips.length = Globals.teamGroups[i] + 1;
                }
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
            if (nodeLinks.length != teamCount)
                nodeLinks.length = teamCount;

            // 预计算nodeLinks[0]（基准列表）
            if (!nodeLinks[0])
                nodeLinks[0] = new Vector.<Node>();
            else
                nodeLinks[0].length = 0;

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
                    // 复制基准列表，重用现有Vector
                    if (!nodeLinks[i]) {
                        nodeLinks[i] = new Vector.<Node>(baseLength);
                        // 直接复制元素
                        for (j = 0; j < baseLength; j++)
                            nodeLinks[i][j] = baseLinks[j];
                    } else {
                        // 重用现有数组，调整大小并复制
                        var targetLinks:Vector.<Node> = nodeLinks[i];
                        if (targetLinks.length != baseLength)
                            targetLinks.length = baseLength;
                        for (j = 0; j < baseLength; j++)
                            targetLinks[j] = baseLinks[j];
                    }
                    continue;
                }

                // 需要构建特殊列表
                if (!nodeLinks[i])
                    nodeLinks[i] = new Vector.<Node>();
                else
                    nodeLinks[i].length = 0;

                var warpLinks:Vector.<Node> = nodeLinks[i];

                // 构建warp条件下的特殊列表
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
                    node.aiValue = distance;
                    targetNode.push(node);
                }
            }
            targetNode.sortOn("aiValue", 16); // 按价值从小到大对目标天体排序
            var shipCount:int = int(ships[nodeData.team].length);
            for each (node in targetNode) {
                ship = node.predictedOppShipCount(nodeData.team) * 2 - node.predictedTeamShipCount(nodeData.team) * 0.5; // 飞船数：非己方预测强度二倍减去己方预测强度一半
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

        // 统计飞向自身的飞船，包括指定势力的队伍的和移动距离大于50px的
        public function getTransitShips(team:int):void {
            var group:int = Globals.teamGroups[team];
            for (var i:int = 0; i < transitShips.length; i++) // 重置数组
                transitShips[i] = 0;
            for (i = 0; i < transitGroupShips.length; i++) // 重置数组
                transitGroupShips[i] = 0;
            for each (var ship:Ship in EntityContainer.ships) {
                var shipGroup:int = Globals.teamGroups[ship.team];
                if (!(ship.node == this && ship.state == 3))
                    continue; // 飞船在飞行中且飞向自身
                if (ship.team == team || ship.jumpDist > 50)
                    transitShips[ship.team]++; // 为参数势力或移动距离大于50px    
                if (shipGroup == group || ship.jumpDist > 50)
                    transitGroupShips[shipGroup]++; // 为参数势力或移动距离大于50px
            }
        }

        // 返回飞船数最多的敌对队伍的总飞船数（无属性差分）
        public function oppShipCount(team:int):int {
            var strength:int = 0;
            var group:int = Globals.teamGroups[team];
            var groupShips:Vector.<int> = new Vector.<int>(Globals.teamCount);
            for (var i:int = 0; i < ships.length; i++) {
                var oppGroup:int = Globals.teamGroups[i];
                if (oppGroup == group)
                    continue;
                groupShips[oppGroup] += ships[i].length;
            }
            for each (i in groupShips)
                strength = Math.max(i, strength);
            return strength;
        }

        // 返回飞船数最多的敌对队伍的总飞船数（考虑属性）
        public function oppStrength(team:int):int {
            var strength:int = 0;
            var group:int = Globals.teamGroups[team];
            var groupStrengths:Vector.<int> = new Vector.<int>(Globals.teamCount);
            for (var i:int = 0; i < ships.length; i++) {
                var oppGroup:Number = Globals.teamGroups[i];
                if (oppGroup == group)
                    continue;
                groupStrengths[oppGroup] += ships[i].length * Math.sqrt(Globals.teamShipAttacks[i] * Globals.teamShipDefences[i]);
            }
            for each (i in groupStrengths)
                strength = Math.max(i, strength);
            return strength;
        }

        // 估算后续可能面对的非指定势力方最快占领速度（考虑属性）
        public function predictedOppCaptureRisk(team:int):Number {
            var risk:Number = 0;
            var group:int = Globals.teamGroups[team];
            var groupRisks:Vector.<int> = new Vector.<int>(Globals.teamCount);
            for (var i:int = 0; i < ships.length; i++) {
                var oppGroup:int = Globals.teamGroups[i];
                if (oppGroup == group)
                    continue;
                var addRisk:Number = (ships[i].length + transitShips[i]) * Globals.teamDestroyingSpeeds[i];
                groupRisks[oppGroup] += addRisk;
            }
            for each (i in groupRisks)
                risk = Math.max(i, risk);
            return risk;
        }

        // 估算后续可能面对的非指定势力方最强飞船强度（无属性差分）
        public function predictedOppShipCount(team:int):int {
            var strength:int = 0;
            var group:int = Globals.teamGroups[team];
            var groupShips:Vector.<int> = new Vector.<int>(Globals.teamCount);
            for (var i:int = 0; i < ships.length; i++) {
                var oppGroup:int = Globals.teamGroups[i];
                if (oppGroup == group)
                    continue;
                var addStrength:int = ships[i].length + transitShips[i];
                if (buildState.buildRate > 0 && (Globals.teamGroups[nodeData.team] == Globals.teamGroups[i]))
                    addStrength *= 1.25;
                groupShips[oppGroup] += addStrength;
            }
            for each (i in groupShips)
                strength = Math.max(i, strength);
            return strength;
        }

        // 估算后续可能面对的非指定势力方最强飞船强度（考虑属性）
        public function predictedOppStrength(team:int):int {
            var strength:int = 0;
            var group:int = Globals.teamGroups[team];
            var groupStrengths:Vector.<int> = new Vector.<int>(Globals.teamCount);
            for (var i:int = 0; i < ships.length; i++) {
                var oppGroup:int = Globals.teamGroups[i];
                if (oppGroup == group)
                    continue;
                var addStrength:Number = Number(ships[i].length + transitShips[i]) * Math.sqrt(Globals.teamShipAttacks[i] * Globals.teamShipDefences[i]);
                if (buildState.buildRate > 0 && (Globals.teamGroups[nodeData.team] == Globals.teamGroups[i]))
                    addStrength *= 1.25;
                groupStrengths[oppGroup] += addStrength;
            }
            for each (i in groupStrengths)
                strength = Math.max(i, strength);
            return strength;
        }

        // 返回该势力飞船数（无属性差分）
        public function teamShipCount(team:int):int {
            return Number(ships[team].length);
        }

        // 返回该势力飞船数（考虑属性）
        public function teamStrength(team:int):int {
            return Number(ships[team].length) * Math.sqrt(Globals.teamShipAttacks[team] * Globals.teamShipDefences[team]);
        }

        // 返回该队伍飞船数（无属性差分）
        public function groupShipCount(team:int):int {
            var strength:int = 0;
            var group:int = Globals.teamGroups[team];
            for (var i:int = 0; i < ships.length; i++)
                if (Globals.teamGroups[i] == group)
                    strength += Number(ships[i].length);
            return strength;
        }

        // 返回该队伍飞船数（考虑属性）
        public function groupStrength(team:int):int {
            var strength:int = 0;
            var group:int = Globals.teamGroups[team];
            for (var i:int = 0; i < ships.length; i++)
                if (Globals.teamGroups[i] == group)
                    strength += Number(ships[i].length) * Math.sqrt(Globals.teamShipAttacks[i] * Globals.teamShipDefences[i]);
            return strength;
        }

        // 预测该势力可能的强度（无属性差分）
        public function predictedTeamShipCount(team:int):int {
            var group:int = Globals.teamGroups[team];
            var strength:Number = ships[team].length + transitGroupShips[group];
            if (buildState.buildRate > 0 && team == nodeData.team)
                strength *= 1.25;
            return strength;
        }

        // 预测该势力可能的强度（考虑属性）
        public function predictedTeamStrength(team:int):int {
            var group:int = Globals.teamGroups[team];
            var strength:Number = Number(ships[team].length + transitGroupShips[group]) * Math.sqrt(Globals.teamShipAttacks[team] * Globals.teamShipDefences[team]);
            if (buildState.buildRate > 0 && team == nodeData.team)
                strength *= 1.25;
            return strength;
        }

        // 预测该队伍可能的强度（无属性差分）
        public function predictedGroupShipCount(team:int):int {
            var strength:int = 0;
            var group:int = Globals.teamGroups[team];
            for (var i:int = 0; i < ships.length; i++)
                if (Globals.teamGroups[i] == group)
                    strength += Number(ships[i].length + transitShips[i]);
            if (buildState.buildRate > 0 && group == Globals.teamGroups[nodeData.team])
                strength *= 1.25;
            return strength;
        }

        // 预测该队伍可能的强度（考虑属性）
        public function predictedGroupStrength(team:int):int {
            var strength:int = 0;
            var group:int = Globals.teamGroups[team];
            for (var i:int = 0; i < ships.length; i++)
                if (Globals.teamGroups[i] == group)
                    strength += Number(ships[i].length + transitShips[i]) * Math.sqrt(Globals.teamShipAttacks[i] * Globals.teamShipDefences[i]);
            if (buildState.buildRate > 0 && group == Globals.teamGroups[nodeData.team])
                strength *= 1.25;
            return strength;
        }

        // 计算可到达的有前往价值的天体
        public function getOppLinks(team:int):void {
            var group:int = Globals.teamGroups[team];
            oppNodeLinks.length = 0;
            for each (var node:Node in nodeLinks[team]) {
                if (node == this)
                    continue;
                if (node.nodeData.team == 0 || Globals.teamGroups[node.nodeData.team] != group || node.predictedOppShipCount(team) > 0)
                    oppNodeLinks.push(node);
            }
        }

        // 返回值越大，天体离作战前线越近
        public function getOppCloseLinks(team:int):Number {
            var group:int = Globals.teamGroups[team];
            var link:Number = 0;
            var dx:Number = 0;
            var dy:Number = 0;
            var distance:Number = 0;
            if (this.nodeData.isWarp) {
                return Infinity;
            }
            for each (var node:Node in nodeLinks[team]) {
                if (node == this)
                    continue;
                if (Globals.teamGroups[node.nodeData.team] != group) {
                    dx = node.nodeData.x - this.nodeData.x;
                    dy = node.nodeData.y - this.nodeData.y;
                    distance = Math.sqrt(dx * dx + dy * dy) + rng.nextNumber() * 32;
                    if (distance)
                        link += 64 / distance;
                    else
                        link = Infinity;
                }
            }
            return link;
        }

        // #endregion
        // #region hardAI 特制工具函数
        // 返回飞向自身的最强非己方飞船数
        public function hard_getOppTransitShips(team:int):int {
            var group:int = Globals.teamGroups[team];
            if (!nodeData.hard_ships)
                nodeData.hard_ships = [];
            while (nodeData.hard_ships.length < Globals.teamCount)
                nodeData.hard_ships.push([]);
            for each (var arr:Array in nodeData.hard_ships)
                arr.length = 0;
            for each (var ship:Ship in EntityContainer.ships) {
                if (ship.state == 0 || ship.node != this)
                    continue; // 排除未起飞的和不飞向自身的飞船
                nodeData.hard_ships[ship.team].push(ship);
            }
            var groupShips:Vector.<int> = new Vector.<int>();
            var maxShips:int = 0;
            for (var i:int = 0; i < Globals.teamCount; i++) {
                var oppGroup:int = Globals.teamGroups[i];
                if (oppGroup == group)
                    continue; // 排除己方
                if (groupShips.length < oppGroup + 1) {
                    groupShips.length = oppGroup + 1;
                    groupShips[oppGroup] = nodeData.hard_ships[i].length;
                    continue;
                }
                groupShips[oppGroup] += nodeData.hard_ships[i].length;
            }
            for each (i in groupShips)
                maxShips = Math.max(i, maxShips);
            return maxShips;
        }

        // 返回指定势力的强度
        public function hard_teamStrength(team:int):Number {
            var strength:Number = 0;
            var step:Number = Math.sqrt(Globals.teamShipAttacks[team] * Globals.teamShipDefences[team])
            for each (var ship:Ship in ships[team])
                if (ship.state == 0)
                    strength += step;
            return strength;
        }

        // 返回己方综合强度
        public function hard_AllStrength(team:int):Number {
            var group:int = Globals.teamGroups[team];
            var strength:Number = 0;
            for each (var ship:Ship in EntityContainer.ships)
                if (ship.node == this && Globals.teamGroups[ship.team] == group)
                    strength += Math.sqrt(Globals.teamShipAttacks[ship.team] * Globals.teamShipDefences[ship.team]);
            return strength;
        }
        private var TEMP_INT:Vector.<int> = new Vector.<int>();

        // 返回敌方综合强度
        public function hard_oppAllStrength(team:int):Number {
            if (nodeData.hard_oppAllStrengthCache[team] != -1)
                return nodeData.hard_oppAllStrengthCache[team];
            var group:int = Globals.teamGroups[team];
            var maxStrength:Number = 0;
            var teamGroups:Array = Globals.teamGroups;
            var globalShips:Vector.<GameEntity> = EntityContainer.ships;
            var globalShipsLength:int = globalShips.length;
            var groupStrengths:Vector.<int> = TEMP_INT;
            groupStrengths.length = Globals.teamCount;
            for (var i:int = 0; i < Globals.teamCount; i++)
                groupStrengths[i] = 0;
            for (i = 0; i < globalShipsLength; i++) {
                var ship:Ship = globalShips[i] as Ship;
                if (ship.node != this)
                    continue;
                var shipGroup:int = teamGroups[ship.team];
                var teamStrength:Number = Math.sqrt(Globals.teamShipAttacks[ship.team] * Globals.teamShipDefences[ship.team]);
                if (shipGroup == group)
                    continue;
                var newStrength:Number = groupStrengths[shipGroup] + teamStrength;
                groupStrengths[shipGroup] = newStrength;
                if (newStrength > maxStrength)
                    maxStrength = newStrength;
            }
            nodeData.hard_oppAllStrengthCache[team] = maxStrength;
            return maxStrength;
        }

        // 检查撤退时机是否合理
        public function hard_retreatCheck(team:int):Boolean {
            var group:int = Globals.teamGroups[team];
            if (!nodeData.hard_ships)
                nodeData.hard_ships = [];
            while (nodeData.hard_ships.length < Globals.teamCount)
                nodeData.hard_ships.push([]);
            for each (var arr:Array in nodeData.hard_ships)
                arr.length = 0;
            for each (var ship:Ship in EntityContainer.ships) {
                if (ship.node != this || Globals.teamGroups[ship.team] == group)
                    continue; // 排除不飞向自身的飞船和己方飞船
                if (ship.targetDist / ship.jumpSpeed < 1 || ship.state == 0)
                    nodeData.hard_ships[ship.team].push(ship); // 记录一秒后抵达的和已经抵达的飞船数
            }
            var groupShips:Vector.<int> = new Vector.<int>();
            var maxShips:int = 0;
            for (var i:int = 0; i < nodeData.hard_ships.length; i++) {
                var oppGroup:int = Globals.teamGroups[i];
                if (oppGroup == group)
                    continue; // 排除己方
                if (groupShips.length < oppGroup + 1) {
                    groupShips.length = oppGroup + 1;
                    groupShips[oppGroup] = nodeData.hard_ships[i].length;
                    continue;
                }
                groupShips[oppGroup] += nodeData.hard_ships[i].length;
            }
            for each (i in groupShips)
                maxShips = Math.max(i, maxShips);
            if (maxShips > hard_AllStrength(team))
                return true;
            return false;
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
                statePoolData[key] = statePool[key].toJSON();
            return {
                tag:tag,
                nodeData:nodeData.toJSON(),
                statePool:statePoolData,
                ships:ships.map(function (teamShips:Vector.<Ship>):Vector.<Ship> {
                    return teamShips.map(function (ship:Ship):Object {
                        return ship.toJSON();
                    });
                }),
                 nodeLinks:nodeLinks.map(function (links:Vector.<Node>):Vector.<Node> {
                    return links.map(function (node:Node):int {
                        return EntityContainer.nodes.indexOf(node);
                    });
                }),
                 oppNodeLinks:oppNodeLinks.map(function (node:Node):int {
                    return node.tag;
                }),
                aiTimers:aiTimers.concat(),
                transitShips:transitShips.concat(),
                rng:rng.toJSON()
            };
        }
    }
}
