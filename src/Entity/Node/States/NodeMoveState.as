package Entity.Node.States {
    import Entity.Node;
    import starling.display.Image;
    import starling.text.TextField;
    import Entity.Node.NodeData;
    import Entity.EntityContainer;
    import UI.EntityLayer;

    public class NodeMoveState implements INodeState {
        public var node:Node;
        public var entityL:EntityLayer;
        public var nodeData:NodeData;
        public var glow:Image; // 光效图片
        public var image:Image; // 天体图片
        public var halo:Image; // 光圈图片
        public var label:TextField; // 非战斗状态下的兵力文本
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
        }

        public function init():void {
            this.entityL = node.entityL;
            this.nodeData = node.nodeData;
            labels.length = 0;
            var textField:TextField;
            for (var i:int = 0; i < Globals.teamCount; i++) {
                textField = new TextField(60, 48, "00", "Downlink12", -1, Globals.teamColors[i]);
                textField.vAlign = textField.hAlign = "center";
                textField.pivotX = 30;
                textField.pivotY = 24;
                textField.visible = false;
                labels.push(textField);
            }
            for (i = 0; i < labels.length; i++)
                entityL.labelLayer.addChild(labels[i]);
            image.visible = halo.visible = true;
            entityL.addNode(image, halo, glow);
            entityL.labelLayer.addChild(label);
            if (orbitNode) {
                var dx:Number = nodeData.x - orbitNode.nodeData.x;
                var dy:Number = nodeData.y - orbitNode.nodeData.y;
                orbitDist = Math.sqrt(dx * dx + dy * dy);
                orbitAngle = Math.atan2(dy, dx);
            }
        }

        public function deinit():void {
            entityL.removeNode(image, halo, glow);
            entityL.labelLayer.removeChild(label);
            for (var i:int = 0; i < labels.length; i++)
                entityL.labelLayer.removeChild(labels[i]);
            orbitNode = null;
        }

        // #region update
        public function update(dt:Number):void {
            updateImagePositions();
            label.visible = false;
            for (var i:int = 0; i < labels.length; i++)
                labels[i].visible = false;
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
                    entityL.addGlow(halo);
                }
            } else if (glow.alpha > 0) { // 再归零
                glow.alpha -= dt * 2; // 不透明度减少
                if (glow.alpha <= 0)
                    glow.alpha = 0;
            }
        }

        public function updateConflictLabel(teamId:int, labelAngle:Number, shipCount:int):void {
            var teamLabel:TextField = labels[teamId];
            teamLabel.x = nodeData.x + Math.cos(labelAngle) * labelDist;
            teamLabel.y = nodeData.y + Math.sin(labelAngle) * labelDist;
            teamLabel.text = shipCount.toString();
            teamLabel.visible = (teamLabel.color > 0);
        }

        public function updateCaptureLabel(capturingTeam:int, shipCount:int):void{
            if (capturingTeam != 0 && shipCount > 0) {
                label.text = shipCount.toString();
                label.color = Globals.teamColors[capturingTeam];
                label.visible = (label.color > 0);
            } else 
                label.visible = false;
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
    }
}
