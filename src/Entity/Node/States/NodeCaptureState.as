package Entity.Node.States {
    import Entity.Node;
    import Entity.Node.NodeData;
    import Entity.Ship;
    import Entity.Node.NodeStaticLogic;
    import utils.Rng;

// #region 这个是S33改过的
    public class NodeCaptureState implements INodeState {

        private var node:Node;
        private var nodeData:NodeData;
        private var ships:Vector.<Vector.<Ship>>;
        private var capturingTeams:Vector.<int>; // 占据势力（们）
        private var capturingGroup:int; // 占据队伍
        public var captureTeam:int; // 占领条势力
        public var captureGroup:int; // 占领条队伍
        public var captureRate:Number; // 占领速度

        public function NodeCaptureState(node:Node) {
            this.node = node;
        }

        public function init():void {
            this.nodeData = node.nodeData;
            this.ships = node.ships;
        }

        public function deinit():void {
        }

        public function update(dt:Number):void {
            processTeamChange();
            captureRate = calculateCaptureRate(capturingGroup);
            updateNodeHP(capturingGroup, captureRate, dt);
            var hpRate:Number = 0;
            if (node.capturing || (nodeData.hp != MAX_HP && captureGroup == capturingGroup && nodeData.team != NEUTRAL_TEAM))
                hpRate = nodeData.hp / MAX_HP;
            var shipCounts:Array = new Array();
            for each (var team:int in capturingTeams)
                shipCounts.push(ships[team].length);
            node.moveState.updateCaptureLabel(capturingTeams, captureTeam, shipCounts, hpRate);
        }

        private static const MAX_HP:Number = 100;
        private static const NEUTRAL_TEAM:int = 0;
        private static const CAPTURE_RATE_MULTIPLIER:Number = 10;

        private function checkCaptureState():Boolean {
            var teams:Vector.<int> = new Vector.<int>();
            var group:int = -1;
            var shipNum:int = 0;
            captureGroup = Globals.teamGroups[captureTeam];
            for (var teamId:int = 0; teamId < ships.length; teamId++) { // 判断占领该天体的队伍
                if (ships[teamId].length == 0)
                    continue;
                teams.push(teamId);
                shipNum += ships[teamId].length;
                if (group == -1)
                    capturingGroup = group = Globals.teamGroups[teamId];
            }
            if (teams.length > 0) {
                node.capturing = (group != Globals.teamGroups[nodeData.team]);
                capturingTeams = teams;
                if (nodeData.team == NEUTRAL_TEAM && (nodeData.hp == 0 || capturingGroup == captureGroup && capturingTeams.indexOf(captureTeam) == -1)) {
                        var r:Number = node.rng.nextNumber(); //  根据飞船数随机选择占领势力
                        var lowerBound:Number = 0; // 随机数因子下界
                        for each (var i:int in teams) {
                            var upperBound:Number = lowerBound + ships[i].length / shipNum; // 因子上界
                            if (r >= lowerBound && r < upperBound)
                                captureTeam = i;
                            lowerBound = upperBound; // 新的因子下界
                        }
                }
                return true;
            }
            return node.capturing = false;
        }

        private function calculateCaptureRate(capturingGroup:int):Number {
            // 基础占领速率 = (飞船数1 * 占领速度倍率1 + 飞船数2 * 占领速度倍率2 + ...) / (天体大小 * 100) * 10
            var captureStrength:Number = 0;
            for (var teamId:int = 0; teamId < ships.length; teamId++) {
                if (Globals.teamGroups[teamId] == capturingGroup)
                    if (nodeData.team == NEUTRAL_TEAM) { // 中立天体占领逻辑
                        if (captureGroup == capturingGroup)
                            captureStrength += ships[teamId].length * Globals.teamColonizingSpeeds[teamId];
                        else
                            captureStrength += ships[teamId].length * Globals.teamDecolonizingSpeeds[teamId];
                    } else { // 非中立天体占领逻辑
                        if (captureGroup == capturingGroup)
                            captureStrength += ships[teamId].length * Globals.teamRepairingSpeeds[teamId];
                        else
                            captureStrength += ships[teamId].length * Globals.teamDestroyingSpeeds[teamId];
                    }
            }
            var rate:Number = (captureStrength / (nodeData.size * 100)) * CAPTURE_RATE_MULTIPLIER;
            // 应用占领速度加权
            rate /= nodeData.hpMult * Globals.teamConstructionStrengths[nodeData.team];
            return Math.min(rate, MAX_HP);
        }

        private function updateNodeHP(capturingGroup:int, captureRate:Number, dt:Number):void {
            var hpChange:Number = 0;
            if (nodeData.team == NEUTRAL_TEAM) { // 中立天体占领逻辑
                if (captureGroup == capturingGroup) {
                    hpChange = captureRate * dt;
                    nodeData.hp = nodeData.hp + hpChange;
                } else {
                    hpChange = captureRate * dt;
                    nodeData.hp = nodeData.hp - hpChange;
                }
            } else { // 非中立天体占领逻辑
                if (captureGroup == capturingGroup) {
                    hpChange = captureRate * dt;
                    nodeData.hp = nodeData.hp + hpChange;
                } else {
                    hpChange = captureRate * dt;
                    nodeData.hp = nodeData.hp - hpChange;
                }
            }
            nodeData.hp = Math.max(0, Math.min(MAX_HP, nodeData.hp));
        }

        private function processTeamChange():void {
            if (nodeData.team == NEUTRAL_TEAM && nodeData.hp == MAX_HP)
                NodeStaticLogic.changeTeam(node, captureTeam); // 中立天体完全占领
            else if (nodeData.team != NEUTRAL_TEAM && nodeData.hp == 0 && node.game.winningGroup == -1)
                NodeStaticLogic.changeTeam(node, NEUTRAL_TEAM); // 非中立天体完全失去占领
        }

        public function toJSON(k:String):* {
            throw new Error("Method not implemented.");
        }

        public function get enable():Boolean {
            if (node.conflict)
                return node.capturing = false;
            else
                return checkCaptureState();
        }

        public function get stateType():String {
            return NodeStateFactory.CAPTURE;
        }
    }
}
