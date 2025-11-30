package Entity.Node.States {
    import Entity.Node;
    import starling.display.Image;
    import starling.text.TextField;
    import Entity.Node.NodeData;
    import Entity.EntityContainer;
    import UI.UIContainer;
    import utils.Drawer;
    import starling.animation.Transitions;

    public class NodeMoveState implements INodeState {
        public var node:Node;
        public var nodeData:NodeData;
        public var glow:Image; // 光效图片
        public var image:Image; // 天体图片
        public var halo:Image; // 光圈图片
        public var label:TextField; // 非战斗状态下的兵力文本
        public var captureLabels:Vector.<TextField>; // 驻留飞船兵力文本
        public var conflictLabels:Vector.<TextField>; // 战争飞船兵力文本
        public var labels:Vector.<TextField>; // 战斗状态下的兵力文本列表
        public var labelDist:Number; // 文本圈大小
        public var glowing:Boolean; // 是否正在发光（天体改变势力时的特效

        public var orbitNode:Node; // 轨道中心天体
        public var orbitDist:Number; // 轨道半径
        public var orbitSpeed:Number; // 轨道运转速度
        public var orbitAngle:Number; // 轨道旋转角度

        public function NodeMoveState(node:Node) {
            this.node = node;
            var color:uint = uint(Globals.teamColors[0]);
            image = new Image(Root.assets.getTexture("planet01")); // 设定默认天体
            image.pivotX = image.pivotY = image.width * 0.5;
            halo = new Image(Root.assets.getTexture("halo"));
            halo.pivotX = halo.pivotY = halo.width * 0.5;
            glow = new Image(Root.assets.getTexture("planet_shape"));
            glow.pivotX = glow.pivotY = glow.width * 0.5;
            image.scaleX = image.scaleY = halo.scaleX = halo.scaleY = glow.scaleX = glow.scaleY = 0.5;
            image.color = halo.color = color;
            halo.alpha = 0.75;
            label = new TextField(60, 48, "00", "Downlink12", -1, Globals.teamColors[0]); // 默认兵力文本
            label.vAlign = label.hAlign = "center";
            label.pivotX = 30;
            label.pivotY = 24;
            glowing = false;
            labels = new Vector.<TextField>;
            captureLabels = new Vector.<TextField>;
            conflictLabels = new Vector.<TextField>;
        }

        public function init():void {
            this.nodeData = node.nodeData;
            if (nodeData.orbitNode != -1)
                orbitNode = EntityContainer.nodes[nodeData.orbitNode]
            labels.length = 0;
            captureLabels.length = 0;
            conflictLabels.length = 0;
            var textField:TextField;
            for (var i:int = 0; i < Globals.teamCount; i++) {
                addTextField(captureLabels, i);
                addTextField(conflictLabels, i);
            }
            for (i = 0; i < Globals.teamCount; i++) {
                textField = new TextField(60, 48, "00", "Downlink12", -1, Globals.teamColors[i]);
                textField.vAlign = textField.hAlign = "center";
                textField.pivotX = 30;
                textField.pivotY = 24;
                labels.push(textField);
            }
            for (i = 0; i < labels.length; i++)
                UIContainer.entityLayer.labelLayer.addChild(labels[i]);
            image.visible = halo.visible = true;
            UIContainer.entityLayer.addNode(image, halo, glow);
            UIContainer.entityLayer.labelLayer.addChild(label);
            if (orbitNode) {
                var dx:Number = nodeData.x - orbitNode.nodeData.x;
                var dy:Number = nodeData.y - orbitNode.nodeData.y;
                orbitDist = Math.sqrt(dx * dx + dy * dy);
                orbitAngle = Math.atan2(dy, dx);
            }
            _originalImageScale = image.scaleX;
            _originalHaloScale = halo.scaleX;
            _originalGlowScale = glow.scaleX;
        }

        private function addTextField(vec:Vector.<TextField>, team:int):void {
            var textField:TextField = new TextField(60, 48, "00", "Downlink12", -1, Globals.teamColors[team]);
            textField.vAlign = textField.hAlign = "center";
            textField.pivotX = 30;
            textField.pivotY = 24;
            vec.push(textField);
            UIContainer.entityLayer.labelLayer.addChild(textField);
        }

        public function deinit():void {
            UIContainer.entityLayer.removeNode(image, halo, glow);
            UIContainer.entityLayer.labelLayer.removeChild(label);
            for (var i:int = 0; i < Globals.teamCount; i++){
                UIContainer.entityLayer.labelLayer.removeChild(labels[i]);
                UIContainer.entityLayer.labelLayer.removeChild(captureLabels[i]);
                UIContainer.entityLayer.labelLayer.removeChild(conflictLabels[i]);
            }
            orbitNode = null;
        }

        // #region update
        public function update(dt:Number):void {
            if (nodeData.orbitNode != -1)
                orbitNode = EntityContainer.nodes[nodeData.orbitNode];
            orbitSpeed = nodeData.orbitSpeed;
            updateImagePositions();
            label.visible = false;
            if (orbitNode)
                updateOrbit(dt);
            updateGrow(dt)
        }

        public function updateImagePositions():void {
            image.x = halo.x = glow.x = nodeData.x;
            image.y = halo.y = glow.y = nodeData.y;
            label.x = nodeData.x + 30 * nodeData.size;
            label.y = nodeData.y + 50 * nodeData.size;
        }

        public function updateOrbit(dt:Number):void {
            orbitAngle += orbitSpeed * dt; // 将轨道角度加上轨道速度*游戏速度
            if (orbitAngle > Math.PI * 2)
                orbitAngle -= Math.PI * 2; // 重置角度
            nodeData.x = orbitNode.nodeData.x + Math.cos(orbitAngle) * orbitDist; // 计算更新后的x坐标
            nodeData.y = orbitNode.nodeData.y + Math.sin(orbitAngle) * orbitDist; // 计算更新后的y坐标
        }

        public function updateGrow(dt:Number):void {
            if (glowing) { // 处理势力改变时的光效，先亮度拉满
                glow.alpha += dt * 4; // 不透明度增加
                if (glow.alpha >= 1 || glow.visible == false) { // 亮度满时换贴图颜色
                    glow.alpha = 1;
                    glowing = false;
                    image.color = halo.color = glow.color = Globals.teamColors[nodeData.team];
                    UIContainer.entityLayer.addGlow(halo);
                }
            } else if (glow.alpha > 0) { // 再归零
                glow.alpha -= dt * 2; // 不透明度减少
                if (glow.alpha <= 0)
                    glow.alpha = 0;
            }
        }

        private static const START_ANGLE:Number = -Math.PI / 2; // 起始角度（12点钟方向）
        private static const ARC_ADJUSTMENT:Number = 0.006366197723675814; // 弧线绘制微调值

        public function updateConflictLabels(activeTeams:Vector.<int>, totalShips:int):void {
            var currentAngle:Number = START_ANGLE - Math.PI * node.ships[activeTeams[0]].length / totalShips;
            var labelAngleStep:Number = Math.PI * 2 / activeTeams.length;
            hideCaptureLabels()
            for (var i:int = 0; i < Globals.teamCount; i++) {
                if (activeTeams.indexOf(i) == -1) {
                    conflictLabels[i].visible = false;
                    continue;
                }
                var teamId:int = i;
                var shipCount:int = node.ships[teamId].length;
                var arcRatio:Number = shipCount / totalShips;
                Drawer.drawCircle(UIContainer.behaviorBatch, nodeData.x, nodeData.y, Globals.teamColors[teamId], nodeData.lineDist, nodeData.lineDist - 2, false, 1, arcRatio - ARC_ADJUSTMENT, currentAngle + 0.01);
                var labelAngle:Number = START_ANGLE + activeTeams.indexOf(i) * labelAngleStep;
                node.moveState.updateConflictLabel(teamId, labelAngle, shipCount);
                currentAngle += Math.PI * 2 * arcRatio;
            }
        }

        private function updateConflictLabel(teamId:int, labelAngle:Number, shipCount:int):void {
            var teamLabel:TextField = conflictLabels[teamId];
            teamLabel.x = nodeData.x + Math.cos(labelAngle) * labelDist;
            teamLabel.y = nodeData.y + Math.sin(labelAngle) * labelDist;
            teamLabel.text = shipCount.toString();
            teamLabel.visible = Globals.teamShowLabels[teamId];
        }

        public function updateCaptureLabel(capturingTeams:Vector.<int>, captureTeam:int, shipCounts:Array, hpRate:Number):void {
            updateCooperateLabels(capturingTeams)
            label.visible = false;
            if (hpRate != 0) {
                var arcAngle:Number = START_ANGLE - Math.PI * hpRate;
                Drawer.drawCircle(UIContainer.behaviorBatch, nodeData.x, nodeData.y, Globals.teamColors[captureTeam], nodeData.lineDist, nodeData.lineDist - 2, false, 0.1);
                Drawer.drawCircle(UIContainer.behaviorBatch, nodeData.x, nodeData.y, Globals.teamColors[captureTeam], nodeData.lineDist, nodeData.lineDist - 2, false, 0.7, hpRate, arcAngle);
            }
        }

        public function updateCooperateLabels(activeTeams:Vector.<int>):void {
            const labelAngleStep:Number = Math.min(Math.PI * 2 / Globals.maxMarginTeam, Math.PI * 2 / activeTeams.length);
            const startAngle:Number = 1.03037682652;
            for (var teamId:int = 0; teamId < Globals.teamCount; teamId++) {
                if (activeTeams.indexOf(teamId) == -1) {
                    captureLabels[teamId].visible = false;
                    continue;
                }
                var shipCount:int = node.ships[teamId].length;
                var labelAngle:Number = startAngle + activeTeams.indexOf(teamId) * labelAngleStep - Math.PI * (activeTeams.length - 1) / Globals.maxMarginTeam;
                node.moveState.updateCooperateLabel(teamId, labelAngle, shipCount, activeTeams.length);
            }
        }
        private const startEaseX:Number = 100 - Transitions.getTransition(Transitions.EASE_OUT)(1 / Globals.maxMarginTeam) * 80;
        private const startEaseY:Number = 60 - Transitions.getTransition(Transitions.EASE_OUT)(1 / Globals.maxMarginTeam) * 120;
        private function updateCooperateLabel(teamId:int, labelAngle:Number, shipCount:int, teamCount:int):void {
            var teamLabel:TextField = captureLabels[teamId];
            var easeX:Number = Math.min(180, Transitions.getTransition(Transitions.EASE_OUT)(teamCount / Globals.maxMarginTeam) * 80 + startEaseX);
            var easeY:Number = Math.min(180, Transitions.getTransition(Transitions.EASE_OUT)(teamCount / Globals.maxMarginTeam) * 120 + startEaseY);
            teamLabel.x = nodeData.x + Math.cos(labelAngle) * easeX * nodeData.size;
            teamLabel.y = nodeData.y + Math.sin(labelAngle) * easeY * nodeData.size;
            teamLabel.text = shipCount.toString();
            teamLabel.visible = Globals.teamShowLabels[teamId];
        }

        public function hideCaptureLabels():void {
            for (var i:int = 0; i < captureLabels.length; i++)
                captureLabels[i].visible = false;
        }

        public function hideConflictLabels():void {
            for (var i:int = 0; i < conflictLabels.length; i++)
                conflictLabels[i].visible = false;
        }

        // #endregion

        public function setOrbitNode(nodeTag:int, orbitSpeed:Number = 0.1, clockwise:Boolean = true):void {
            this.orbitNode = EntityContainer.nodes[nodeTag];
            var dx:Number = nodeData.x - orbitNode.nodeData.x;
            var dy:Number = nodeData.y - orbitNode.nodeData.y;
            this.orbitDist = Math.sqrt(dx * dx + dy * dy);
            this.orbitAngle = Math.atan2(dy, dx);
            this.orbitSpeed = orbitSpeed;
            if (!clockwise)
                orbitSpeed = -1 * orbitSpeed;
        }

        public function toJSON(k:String):* {
            throw new Error("Method not implemented.");
        }

        public function get enable():Boolean {
            return true;
        }

        public function get stateType():String {
            return NodeStateFactory.MOVE;
        }

        private var _scale:Number = 1;

        public function get scale():Number {
            return _scale;
        }
        private var _originalImageScale:Number;
        private var _originalHaloScale:Number;
        private var _originalGlowScale:Number;

        public function set scale(val:Number):void {
            _scale = val;
            image.scaleX = image.scaleY = _originalImageScale * _scale;
            halo.scaleX = halo.scaleY = _originalHaloScale * _scale;
            glow.scaleX = glow.scaleY = _originalGlowScale * _scale;
        }

        public function set visible(val:Boolean):void {
            image.visible = halo.visible = glow.visible = val;
        }
    }
}
