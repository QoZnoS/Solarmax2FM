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
    import Entity.EntityContainer;
    import utils.Rng;
    import utils.GS;
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
            NodeStaticLogic.changeType(this, data.type, data.size);
            NodeStaticLogic.changeTeam(this, data.team, false);
            nodeData.deserialize(data);
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
            nodeLinks.length = Globals.teamCount;
            for (var i:int = 0; i < Globals.teamCount; i++) {
                var group:int = Globals.teamGroups[i];
                var nodeGroup:int = Globals.teamGroups[nodeData.team];
                if (!nodeLinks[i])
                    nodeLinks[i] = new Vector.<Node>;
                else
                    nodeLinks[i].length = 0;
                if (i != 0 && !(group == nodeGroup && nodeData.isWarp)) {
                    nodeLinks[i] = nodeLinks[0].concat();
                    continue;
                }
                for each (var node:Node in EntityContainer.nodes) {
                    if (node == this || node.nodeData.isUntouchable)
                        continue;
                    if (nodeData.isWarp && nodeGroup == group && i != 0) {
                        nodeLinks[i].push(node);
                        continue;
                    }
                    if (EntityContainer.nodesBlocked(this, node) == null)
                        nodeLinks[i].push(node);
                }
            }
        }

        public function updateShipAction():void {
            for each (var action:Array in shipActions)
                NodeStaticLogic.moveShips(this, action[0], action[1], action[2]);
            shipActions.length = 0;
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
            var nodeArray:Vector.<Node> = EntityContainer.nodes;
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
                ship = node.predictedOppStrength(nodeData.team) * 2 - node.predictedTeamStrength(nodeData.team) * 0.5; // 飞船数：非己方预测强度二倍减去己方预测强度一半
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

        // #region S33加的队伍判断
        // 返回飞船数最多的敌对队伍的总飞船数
        public function oppStrength(team:int):int {
            var strength:int = 0;
            var group:int = Globals.teamGroups[team];
            var groupShips:Vector.<int> = new Vector.<int>(Globals.teamCount);
            for (var i:int = 0; i < ships.length; i++) {
                var oppGroup:int = Globals.teamGroups[i];
                if (oppGroup == group)
                    continue;
                groupShips[oppGroup] += ships[i].length;
            }
            for each(i in groupShips)
                strength = Math.max(i, strength);
            return strength;
        }

        // 估算后续可能面对的非指定势力方最强飞船强度
        public function predictedOppStrength(team:int):int {
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
            for each(i in groupShips)
                strength = Math.max(i, strength);
            return strength;
        }

        // 返回该势力飞船数
        public function teamStrength(team:int):int {
            return Number(ships[team].length);
        }
        // #endregion
        // #region S33添加的函数
        // 返回该队伍飞船数
        public function groupStrength(team:int):int {
            var strength:int = 0;
            var group:int = Globals.teamGroups[team];
            for (var i:int = 0; i < ships.length; i++)
                if (Globals.teamGroups[i] == group)
                    strength += Number(ships[i].length);
            return strength;
        }

        // 预测该势力可能的强度
        public function predictedTeamStrength(team:int):int {
            var group:int = Globals.teamGroups[team]; 
            var strength:Number = ships[team].length + transitGroupShips[group];
            if (buildState.buildRate > 0 && team == nodeData.team)
                strength *= 1.25;
            return strength;
        }

        // 预测该队伍可能的强度
        public function predictedGroupStrength(team:int):int {
            var strength:int = 0;
            var group:int = Globals.teamGroups[team];
            for (var i:int = 0; i < ships.length; i++)
                if (Globals.teamGroups[i] == group)
                    strength += Number(ships[i].length + transitShips[i]);
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
                if (node.nodeData.team == 0 || Globals.teamGroups[node.nodeData.team] != group || node.predictedOppStrength(team) > 0)
                    oppNodeLinks.push(node);
            }
        }
        // #endregion

        // #endregion
        // #region hardAI 特制工具函数

        // 返回飞向自身的最强非己方飞船数
        public function hard_getOppTransitShips(team:int):int {
            var group:int = Globals.teamGroups[team];
            var ships:Array = [];
            for (var i:int = 0; i < Globals.teamCount; i++)
                ships.push([]);
            for each (var ship:Ship in EntityContainer.ships) {
                if (ship.state == 0 || ship.node != this)
                    continue; // 排除未起飞的和不飞向自身的飞船
                ships[ship.team].push(ship);
            }
            var groupShips:Vector.<int> = new Vector.<int>();
            var maxShips:int = 0;
            for (i = 0; i < Globals.teamCount; i++) {
                var oppGroup:int = Globals.teamGroups[i];
                if (oppGroup == group)
                    continue; // 排除己方
                if (groupShips.length < oppGroup + 1) {
                    groupShips.length = oppGroup + 1;
                    groupShips[oppGroup] = ships[i].length;
                    continue;
                }
                groupShips[oppGroup] += ships[i].length;
            }
            for each(i in groupShips)
                maxShips = Math.max(i, maxShips);
            return maxShips;
        }

        // 返回指定势力的飞船数
        public function hard_teamStrength(team:int):int {
            var strength:int = 0;
            for each (var ship:Ship in ships[team])
                if (ship.state == 0)
                    strength++;
            return strength;
        }

        // 返回己方综合强度
        public function hard_AllStrength(team:int):int {
            var group:int = Globals.teamGroups[team];
            var strength:int = 0;
            for each (var ship:Ship in EntityContainer.ships)
                if (ship.node == this && Globals.teamGroups[ship.team] == group)
                    strength++;
            return strength;
        }

        // 返回敌方综合强度
        public function hard_oppAllStrength(team:int):int {
            var group:int = Globals.teamGroups[team];
            var ships:Array = [];
            for (var i:int = 0; i < Globals.teamCount; i++)
                ships.push([]);
            for each (var ship:Ship in EntityContainer.ships)
                if (ship.node == this && Globals.teamGroups[ship.team] != group)
                    ships[ship.team].push(ship);
            var groupShips:Vector.<int> = new Vector.<int>();
            var maxShips:int = 0;
            for (i = 0; i < ships.length; i++) {
                var oppGroup:int = Globals.teamGroups[i];
                if (oppGroup == group)
                    continue; // 排除己方
                if (groupShips.length < oppGroup + 1) {
                    groupShips.length = oppGroup + 1;
                    groupShips[oppGroup] = ships[i].length;
                    continue;
                }
                groupShips[oppGroup] += ships[i].length;
            }
            for each(i in groupShips)
                maxShips = Math.max(i, maxShips);
            return maxShips;
        }

        // 检查撤退时机是否合理
        public function hard_retreatCheck(team:int):Boolean {
            var ships:Array = [];
            var group:int = Globals.teamGroups[team];
            for (var i:int = 0; i < Globals.teamCount; i++)
                ships.push([]);
            for each (var ship:Ship in EntityContainer.ships) {
                if (ship.node != this || Globals.teamGroups[ship.team] == group)
                    continue; // 排除不飞向自身的飞船和己方飞船
                if (ship.targetDist / ship.jumpSpeed < 1 || ship.state == 0)
                    ships[ship.team].push(ship); // 记录一秒后抵达的和已经抵达的飞船数
            }
            var groupShips:Vector.<int> = new Vector.<int>();
            var maxShips:int = 0;
            for (i = 0; i < ships.length; i++) {
                var oppGroup:int = Globals.teamGroups[i];
                if (oppGroup == group)
                    continue; // 排除己方
                if (groupShips.length < oppGroup + 1) {
                    groupShips.length = oppGroup + 1;
                    groupShips[oppGroup] = ships[i].length;
                    continue;
                }
                groupShips[oppGroup] += ships[i].length;
            }
            for each(i in groupShips)
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
    }
}
