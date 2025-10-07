package Entity.Node {
    import Entity.Node;
    import Entity.FXHandler;
    import utils.GS;
    import Game.GameScene;
    import Entity.Ship;
    import Entity.Node.Attack.AttackStrategyFactory;
    import UI.UIContainer;

    /** 静态类，函数均与dt无关 */
    public class NodeStaticLogic {
        public static var game:GameScene;

        // #region 控制天体

        /**修改天体上的UI大小
         * @param node
         */
        public static function updateLabelSizes(node:Node):void {
            var i:int = 0;
            switch (Globals.textSize) // 读取文本大小设置
            {
                case 0: // 大小设置为0
                    node.moveState.label.fontName = "Downlink10"; // 切换和平状态下的字体图
                    node.moveState.label.fontSize = -1; // 默认大小
                    for (i = 0; i < node.moveState.labels.length; i++) {
                        // 设定战斗状态下每个势力的文本
                        node.moveState.labels[i].fontName = "Downlink10";
                        node.moveState.labels[i].fontSize = -1;
                    }
                    break;
                case 1: // 大小设置为1
                    node.moveState.label.fontName = "Downlink12";
                    node.moveState.label.fontSize = -1;
                    for (i = 0; i < node.moveState.labels.length; i++) {
                        node.moveState.labels[i].fontName = "Downlink12";
                        node.moveState.labels[i].fontSize = -1;
                    }
                    break;
                case 2: // 大小设置为2
                    node.moveState.label.fontName = "Downlink18";
                    node.moveState.label.fontSize = -1;
                    for (i = 0; i < node.moveState.labels.length; i++) {
                        node.moveState.labels[i].fontName = "Downlink18";
                        node.moveState.labels[i].fontSize = -1;
                    }
                    return;
            }
        }

        /**修改天体势力
         * @param node 目标天体
         * @param team 目标势力
         * @param pulseEffect 是否播放占领特效
         */
        public static function changeTeam(node:Node, team:int, pulseEffect:Boolean = true):void {
            // if (Globals.level == 35 && node.nodeData.type == NodeType.DILATOR)
            // return; // 32 36关星核不做处理，自己变自己不做处理
            if (team == 0)
                node.nodeData.hp = 0;
            else
                node.nodeData.hp = 100;
            var nodeTeam:int = node.nodeData.team;
            node.nodeData.team = team;
            node.captureState.captureTeam = team;
            node.moveState.glowing = true; // 激活光效
            node.moveState.glow.visible = false;
            if (!pulseEffect)
                return;
            node.moveState.glow.visible = true;
            node.moveState.glow.color = Globals.teamColors[team]; // 设定光效颜色
            UIContainer.entityLayer.addGlow(node.moveState.glow);
            FXHandler.addPulse(node, Globals.teamColors[team], 0);
            GS.playCapture(node.nodeData.x); // 播放占领音效
            if (nodeTeam != Globals.playerTeam && team == Globals.playerTeam && node.nodeData.popVal > 0) {
                game.popLabels[1].color = 65280;
                game.popLabels[1].alpha = 1;
                game.popLabels[2].color = 3407667;
                game.popLabels[2].alpha = 1;
                game.popLabels[2].text = "+ " + node.nodeData.popVal;
            } else if (nodeTeam == Globals.playerTeam && team != Globals.playerTeam && node.nodeData.popVal > 0) {
                game.popLabels[1].color = 16711680;
                game.popLabels[1].alpha = 1;
                game.popLabels[2].color = 16724787;
                game.popLabels[2].alpha = 1;
                game.popLabels[2].text = "- " + node.nodeData.popVal;
            }
        }

        /**修改天体上所有飞船的势力（待改）
         * @param node 目标天体
         * @param team 目标势力
         */
        public static function changeShipsTeam(node:Node, team:int):void {
            var ship:Ship = null;
            for (var i:int = 0; i < node.ships.length; i++) {
                if (i == team)
                    continue;
                while (node.ships[i].length > 0) {
                    ship = node.ships[i].pop();
                    ship.changeTeam(team);
                }
            }
        }

        /**修改天体类型
         * @param node 目标天体
         * @param type 目标类型
         * @param size 目标大小
         */
        public static function changeType(node:Node, type:String, size:Number = NaN):void {
            size = node.nodeData.size = isNaN(size) ? NodeType.getDefaultSize(type) : size;
            // 处理贴图
            node.moveState.image.rotation = node.moveState.halo.rotation = node.moveState.glow.rotation = 0;
            node.nodeData.type = type;
            if (type == NodeType.PLANET) {
                var imageID:String = node.rng.nextRange(1, 16).toString();
                if (imageID.length == 1)
                    imageID = "0" + imageID; // 随机取一个星球贴图的编号
                node.moveState.image.texture = Root.assets.getTexture("planet" + imageID); // 更换星球贴图
                node.moveState.halo.texture = Root.assets.getTexture("halo"); // 更换光圈
                node.moveState.glow.texture = Root.assets.getTexture("planet_shape"); // 更换星球光效
                node.moveState.image.scaleX = node.moveState.image.scaleY = node.moveState.glow.scaleX = node.moveState.glow.scaleY = size;
            } else {
                node.moveState.image.texture = Root.assets.getTexture(type); // 更换星球贴图
                node.moveState.halo.texture = Root.assets.getTexture(type + "_glow"); // 更换光圈
                node.moveState.glow.texture = Root.assets.getTexture(type + "_shape"); // 更换星球光效
            }
            node.moveState.labelDist = 180 * size; // 计算文本圈大小
            if (!node.nodeData.lineDist)
                node.nodeData.lineDist = 150 * size; // 计算选中圈大小
            node.moveState.halo.readjustSize();
            node.moveState.halo.scaleY = node.moveState.halo.scaleX = 1;
            node.moveState.halo.pivotY = node.moveState.halo.pivotX = node.moveState.halo.width * 0.5;
            node.moveState.image.rotation = node.moveState.halo.rotation = node.moveState.glow.rotation = NodeType.getDefaultRotation(type);
            if (type == NodeType.PLANET)
                node.moveState.halo.scaleY = node.moveState.halo.scaleX = size * 0.5;
            else
                node.moveState.image.scaleX = node.moveState.image.scaleY = node.moveState.halo.scaleX = node.moveState.halo.scaleY = node.moveState.glow.scaleX = node.moveState.glow.scaleY = NodeType.getDefaultScale(type, size);
            if (node.nodeData.team != 0)
                node.nodeData.startShips[node.nodeData.team] = NodeType.getDefaultStartVal(type, size);
            node.nodeData.popVal = NodeType.getDefaultPopVal(type, size);
            node.nodeData.hpMult = NodeType.getDefaultHpMult(type, size);
            node.buildState.buildRate = NodeType.getDefaultBuildRate(type, size);
            var attackRate:Number = NodeType.getDefaultAttackRate(type, size);
            var attackRange:Number = NodeType.getDefaultAttackRange(type, size);
            var attackLast:Number = NodeType.getDefaultAttackLast(type, size);
            node.attackState.attackStrategy = AttackStrategyFactory.create(NodeType.getDefaultAttackType(type), attackRate, attackRange, attackLast);
            if (!node.nodeData.isBarrier)
                node.nodeData.isBarrier = NodeType.isBarrier(type);
            if (!node.nodeData.isWarp)
                node.nodeData.isWarp = NodeType.isWarp(type);
            if (!node.nodeData.isUntouchable)
                node.nodeData.isUntouchable = NodeType.isUntouchable(type);
            if (!node.nodeData.isAIinvisible)
                node.nodeData.isAIinvisible = NodeType.isAIinvisible(type);
        }

        public static function changeSize(node:Node, size:Number):void {
            node.nodeData.size = size;
            node.moveState.labelDist = 180 * size; // 计算文本圈大小
            node.nodeData.lineDist = 150 * size; // 计算选中圈大小
            node.moveState.halo.readjustSize();
            node.moveState.halo.scaleY = node.moveState.halo.scaleX = 1;
            node.moveState.halo.pivotY = node.moveState.halo.pivotX = node.moveState.halo.width * 0.5;
            var get:Number = LevelData.nodeData.node.(@name == node.nodeData.type).scale;
            if (node.nodeData.type == NodeType.PLANET) {
                node.moveState.halo.scaleY = node.moveState.halo.scaleX = size * 0.5;
                node.moveState.image.scaleX = node.moveState.image.scaleY = node.moveState.glow.scaleX = node.moveState.glow.scaleY = size;
            } else {
                node.moveState.image.scaleX = node.moveState.image.scaleY = node.moveState.halo.scaleX = node.moveState.halo.scaleY = node.moveState.glow.scaleX = node.moveState.glow.scaleY = Number(get);
            }
        }

        private static function sliceGet(get:String, size:Number):Number {
            return (get.indexOf("S*") != -1) ? Number(get.slice(2)) * size : Number(get);
        }

        // #endregion
        // #region 控制飞船

        /**派出玩家飞船
         * @param node 起点
         * @param team 势力
         * @param targetNode 终点
         */
        public static function sendShips(node:Node, team:int, targetNode:Node):void {
            var l:int = Math.ceil(node.ships[team].length * game.scene.ui.btnL.fleetSlider.perc); // 计算调动的飞船数，Math.ceil()为至少调动1飞船判定
            if (targetNode == node || l == 0)
                return;
            if (game.visible)
                Globals.replay.addAction(0, node.tag, team, l, targetNode.tag);
            node.shipActions.push([team, targetNode, l])
        }

        /**派出AI飞船
         * @param node 起点
         * @param team 势力
         * @param targetNode 终点
         * @param ships 派出的飞船数
         */
        public static function sendAIShips(node:Node, team:int, targetNode:Node, ships:int):void {
            var shipNumber:int = Math.min(ships, node.ships[team].length);
            if (targetNode == node || shipNumber == 0)
                return;
            if (game.visible)
                Globals.replay.addAction(0, node.tag, team, shipNumber, targetNode.tag);
            if (node.aiTimers[team] < 1)
                node.aiTimers[team] = 1;
            node.shipActions.push([team, targetNode, shipNumber]);
        }

        /**发送飞船
         * @param node 起点
         * @param team 目标势力
         * @param targetNode 终点
         * @param ships 飞船数
         */
        public static function moveShips(node:Node, team:int, targetNode:Node, ships:int):void {
            var ship:Ship = null;
            var warp:Boolean = false; // 是否为传送门
            var ShipNumber:int = Math.min(ships, node.ships[team].length);
            for (var i:int = 0; i < ShipNumber; i++) {
                // 遍历每个需调动的飞船
                ship = node.ships[team][i];
                if (ship.state != 0)
                    ShipNumber = Math.min(ShipNumber + 1, node.ships[team].length); // 这里是为了允许快速操作，跳过将要起飞的飞船并将循环次数增加1
                else
                    warp = moveShip(node, ship, targetNode);
            }
            if (warp)
                showWarpPulse(node, team); // 播放传送门特效
        }

        /**发送单个飞船
         * @param node 起点
         * @param ship 目标飞船
         * @param targetNode 终点
         * @return 是否为传送门
         */
        private static function moveShip(node:Node, ship:Ship, targetNode:Node):Boolean {
            if (node.nodeData.isWarp && ship.team == node.nodeData.team) {
                ship.warpTo(targetNode);
                return true;
            } else {
                ship.moveTo(targetNode);
                return false;
            }
        }

        // #endregion
        // #region 播放特效

        /**播放传送起点特效
         * @param node 目标天体
         * @param team 特效颜色势力
         */
        public static function showWarpPulse(node:Node, team:int):void {
            var _delay:Number = 0;
            var _rate:Number = 2.6;
            var _delayStep:Number = 0.12;
            var _angle:Number = 1.5707963267948966;
            var _maxSize:Number = 1;
            for (var i:int = 0; i < 3; i++) {
                FXHandler.addDarkPulse(node, Globals.teamColors[team], 1, _maxSize, _rate, _angle, _delay);
                _delay += _delayStep;
                _angle += 2.0943951023931953;
                FXHandler.addDarkPulse(node, Globals.teamColors[team], 1, _maxSize, _rate, _angle, _delay);
                _delay += _delayStep;
                _angle += 2.0943951023931953;
                FXHandler.addDarkPulse(node, Globals.teamColors[team], 1, _maxSize, _rate, _angle, _delay);
                _delay += _delayStep;
                _angle += 2.0943951023931953;
                _rate *= 1.1;
                _delayStep *= 0.9;
                _maxSize *= 0.8;
            }
            FXHandler.addDarkPulse(node, Globals.teamColors[team], 2, 2, 2, 0);
            GS.playWarpCharge(node.nodeData.x);
        }

        /**播放传送终点特效
         * @param node 目标天体
         * @param team 特效颜色势力
         */
        public static function showWarpArrive(node:Node, team:int):void {
            var rate:Number = 2;
            var angle:Number = 1.5707963267948966;
            var maxSize:Number = node.nodeData.size * 2;
            FXHandler.addDarkPulse(node, Globals.teamColors[team], 0, maxSize, rate, angle, 0);
            angle += 2.0943951023931953;
            FXHandler.addDarkPulse(node, Globals.teamColors[team], 0, maxSize, rate, angle, 0);
            angle += 2.0943951023931953;
            FXHandler.addDarkPulse(node, Globals.teamColors[team], 0, maxSize, rate, angle, 0);
            angle += 2.0943951023931953;
            rate *= 1.1;
            maxSize *= 1.2;
            FXHandler.addDarkPulse(node, Globals.teamColors[team], 3, 18 * node.nodeData.size, 28 * node.nodeData.size, 0);
        }

        // #endregion

    }
}
