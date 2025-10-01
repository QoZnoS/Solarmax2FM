package Entity.Node.States {
    import Entity.Node;
    import Entity.Node.NodeData;
    import Entity.Ship;
    import Entity.Node.NodeType;
    import utils.Drawer;
    import Entity.Node.NodeStaticLogic;
    import UI.UIContainer;

    public class NodeCaptureState implements INodeState {

        private var node:Node;
        private var nodeData:NodeData;
        private var ships:Vector.<Vector.<Ship>>;
        private var capturingTeam:int; // 占据势力
        public var captureTeam:int; // 占领条势力
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
            processTeamChange(capturingTeam);
            captureRate = calculateCaptureRate(capturingTeam);
            updateNodeHP(capturingTeam, captureRate, dt);
            updateCaptureUI(capturingTeam);
        }

        private static const MAX_HP:Number = 100;
        private static const NEUTRAL_TEAM:int = 0;
        private static const CAPTURE_RATE_MULTIPLIER:Number = 10;
        private static const START_ANGLE:Number = -Math.PI / 2;

        private function checkCaptureState():Boolean {
            for (var teamId:int = 0; teamId < ships.length; teamId++) {
                if (ships[teamId].length == 0)
                    continue;
                node.capturing = (teamId != nodeData.team);
                capturingTeam = teamId;
                if (nodeData.team == NEUTRAL_TEAM && nodeData.hp == 0)
                    captureTeam = teamId;
                return true;
            }
            return node.capturing = false;
        }

        private function calculateCaptureRate(capturingTeam:int):Number {
            // 基础占领速率 = 飞船数 / (天体大小 * 100) * 10
            var rate:Number = (ships[capturingTeam].length / (nodeData.size * 100)) * CAPTURE_RATE_MULTIPLIER;
            // 应用占领速度加权
            rate /= nodeData.hpMult * Globals.teamConstructionStrengths[nodeData.team];
            return Math.min(rate, MAX_HP);
        }

        private function updateNodeHP(capturingTeam:int, captureRate:Number, dt:Number):void {
            var hpChange:Number = 0;
            if (nodeData.team == NEUTRAL_TEAM) { // 中立天体占领逻辑
                if (captureTeam == capturingTeam) {
                    hpChange = Globals.teamColonizingSpeeds[capturingTeam] * captureRate * dt;
                    nodeData.hp = nodeData.hp + hpChange;
                } else {
                    hpChange = Globals.teamDecolonizingSpeeds[capturingTeam] * captureRate * dt;
                    nodeData.hp = nodeData.hp - hpChange;
                }
            } else { // 非中立天体占领逻辑
                if (captureTeam == capturingTeam) {
                    hpChange = Globals.teamRepairingSpeeds[capturingTeam] * captureRate * dt;
                    nodeData.hp = nodeData.hp + hpChange;
                } else {
                    hpChange = Globals.teamDestroyingSpeeds[capturingTeam] * captureRate * dt;
                    nodeData.hp = nodeData.hp - hpChange;
                }
            }
            nodeData.hp = Math.max(0, Math.min(MAX_HP, nodeData.hp));
        }

        private function updateCaptureUI(capturingTeam:int):void {
            if (shouldDrawCaptureArc()) {
                var arcAngle:Number = START_ANGLE - Math.PI * (nodeData.hp / MAX_HP);
                Drawer.drawCircle(UIContainer.behaviorBatch, nodeData.x, nodeData.y, Globals.teamColors[captureTeam], nodeData.lineDist, nodeData.lineDist - 2, false, 0.1);
                Drawer.drawCircle(UIContainer.behaviorBatch, nodeData.x, nodeData.y, Globals.teamColors[captureTeam], nodeData.lineDist, nodeData.lineDist - 2, false, 0.7, nodeData.hp / MAX_HP, arcAngle);
            }
            node.moveState.updateCaptureLabel(capturingTeam, ships[capturingTeam].length);
        }

        private function shouldDrawCaptureArc():Boolean {
            return node.capturing || (nodeData.hp != MAX_HP && captureTeam == capturingTeam && nodeData.team != NEUTRAL_TEAM);
        }

        private function processTeamChange(capturingTeam:int):void {
            if (nodeData.team == NEUTRAL_TEAM && nodeData.hp == MAX_HP)
                NodeStaticLogic.changeTeam(node, captureTeam); // 中立天体完全占领
            else if (nodeData.team != NEUTRAL_TEAM && nodeData.hp == 0 && node.game.winningTeam == -1)
                NodeStaticLogic.changeTeam(node, NEUTRAL_TEAM);// 非中立天体完全失去占领
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
