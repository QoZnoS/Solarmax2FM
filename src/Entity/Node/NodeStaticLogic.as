package Entity.Node {
    import Entity.Node;
    import Entity.FXHandler;
    import utils.GS;
    import Game.GameScene;
    import Entity.Ship;
    import Entity.Node.Attack.AttackStrategyFactory;

    /** 静态类，函数均与dt无关 */
    public class NodeStaticLogic {
        public static var game:GameScene;

        public static function updateImagePositions(node:Node):void {
            node.image.x = node.halo.x = node.glow.x = node.nodeData.x;
            node.image.y = node.halo.y = node.glow.y = node.nodeData.y;
            node.label.x = node.nodeData.x + 30 * node.nodeData.size;
            node.label.y = node.nodeData.y + 50 * node.nodeData.size;
        }

        public static function changeTeam(node:Node, team:int):void {
            if (Globals.level == 35 && node.nodeData.type == NodeType.DILATOR)
                return; // 32 36关星核不做处理，自己变自己不做处理
            if (team == 0)
                node.nodeData.hp = 0;
            var Nodeteam:int = node.nodeData.team;
            node.nodeData.team = team;
            node.captureTeam = team;
            node.glowing = true; // 激活光效
            node.glow.color = Globals.teamColors[team]; // 设定光效颜色
            node.entityL.addGlow(node.glow);
            FXHandler.addPulse(node, Globals.teamColors[team], 0);
            GS.playCapture(node.nodeData.x); // 播放占领音效
            if (Nodeteam != 1 && team == 1 && node.nodeData.popVal > 0) {
                game.popLabels[1].color = 65280;
                game.popLabels[1].alpha = 1;
                game.popLabels[2].color = 3407667;
                game.popLabels[2].alpha = 1;
                game.popLabels[2].text = "+ " + node.nodeData.popVal;
            } else if (Nodeteam == 1 && team != 1 && node.nodeData.popVal > 0) {
                game.popLabels[1].color = 16711680;
                game.popLabels[1].alpha = 1;
                game.popLabels[2].color = 16724787;
                game.popLabels[2].alpha = 1;
                game.popLabels[2].text = "- " + node.nodeData.popVal;
            }
        }

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

        public static function changeType(node:Node, type:String, size:Number = -1):void {
            var get:String = LevelData.nodeData.node.(@id == type).defaultSize;
            node.nodeData.size = (size == -1) ? Number(get) : size;
            // 处理贴图
            node.image.rotation = node.halo.rotation = node.glow.rotation = 0;
            node.nodeData.type = type;
            if (type == NodeType.PLANET) {
                var ImageID:String = node.rng.nextRange(1, 16).toString();
                if (ImageID.length == 1)
                    ImageID = "0" + ImageID; // 随机取一个星球贴图的编号
                node.image.texture = Root.assets.getTexture("planet" + ImageID); // 更换星球贴图
                node.halo.texture = Root.assets.getTexture("halo"); // 更换光圈
                node.glow.texture = Root.assets.getTexture("planet_shape"); // 更换星球光效
                node.image.scaleX = node.image.scaleY = node.glow.scaleX = node.glow.scaleY = size;
            } else {
                node.image.texture = Root.assets.getTexture(type); // 更换星球贴图
                node.halo.texture = Root.assets.getTexture(type + "_glow"); // 更换光圈
                node.glow.texture = Root.assets.getTexture(type + "_shape"); // 更换星球光效
            }
            node.labelDist = 180 * size; // 计算文本圈大小
            node.nodeData.lineDist = 150 * size; // 计算选中圈大小
            node.nodeData.touchDist = size < 0.5 ? node.nodeData.lineDist + (1 - size * 2) * 50 : node.nodeData.lineDist; // 计算传统操作模式下的天体选中圈
            node.halo.readjustSize();
            node.halo.scaleY = node.halo.scaleX = 1;
            node.halo.pivotY = node.halo.pivotX = node.halo.width * 0.5;
            get = LevelData.nodeData.node.(@name == type).rotation;
            node.image.rotation = node.halo.rotation = node.glow.rotation = (get.indexOf("S*") != -1) ? Number(get.slice(2)) * size : Number(get);
            get = LevelData.nodeData.node.(@name == type).scale;
            type == NodeType.PLANET ? node.halo.scaleY = node.halo.scaleX = size * 0.5 : node.image.scaleX = node.image.scaleY = node.halo.scaleX = node.halo.scaleY = node.glow.scaleX = node.glow.scaleY = Number(get);
            // 读取参数
            get = LevelData.nodeData.node.(@name == type).startVal;
            node.startVal = (get.indexOf("S*") != -1) ? Number(get.slice(2)) * size : Number(get);
            get = LevelData.nodeData.node.(@name == type).popVal;
            node.nodeData.popVal = (get.indexOf("S*") != -1) ? Number(get.slice(2)) * size : Number(get);
            get = LevelData.nodeData.node.(@name == type).buildRate;
            node.buildRate = (get.indexOf("S*") != -1) ? Number(get.slice(2)) * size : Number(get);
            get = LevelData.nodeData.node.(@name == type).hpMult;
            node.nodeData.hpMult = (get.indexOf("S*") != -1) ? Number(get.slice(2)) * size : Number(get);
            get = LevelData.nodeData.node.(@name == type).attackRate;
            var attackRate:Number = (get.indexOf("S*") != -1) ? Number(get.slice(2)) * size : Number(get);
            get = LevelData.nodeData.node.(@name == type).attackRange;
            var attackRange:Number = (get.indexOf("S*") != -1) ? Number(get.slice(2)) * size : Number(get);
            get = LevelData.nodeData.node.(@name == type).attackLast;
            var attackLast:Number = (get.indexOf("S*") != -1) ? Number(get.slice(2)) * size : Number(get);
            get = LevelData.nodeData.node.(@name == type).attackType;
            node.attackStrategy = AttackStrategyFactory.create(get, attackRate, attackRange, attackLast);
            if (type == NodeType.BARRIER)
                node.getBarrierLinks(); // 计算障碍链接参数
        }

        public static function sendShips(node:Node, team:int, targetNode:Node):void {
            var l:int = Math.ceil(node.ships[team].length * game.scene.ui.btnL.fleetSlider.perc); // 计算调动的飞船数，Math.ceil()为至少调动1飞船判定
            if (targetNode == node || l == 0)
                return;
            if (!game.rep)
                Globals.replay[Globals.replay.length - 1].push([node.tag, team, targetNode.tag, l])
        }

        public static function sendAIShips(node:Node, team:int, targetNode:Node, ships:int):void {
            var shipNumber:int = Math.min(ships, node.ships[team].length);
            if (targetNode == node || shipNumber == 0)
                return;
            if (!game.rep)
                Globals.replay[Globals.replay.length - 1].push([node.tag, team, targetNode.tag, shipNumber])
            if (node.aiTimers[team] < 1)
                node.aiTimers[team] = 1;
        }

        public static function moveShips(node:Node, team:int, targetNode:Node, ships:int):void {
            var ship:Ship = null;
            var warp:Boolean = false; // 是否为传送门
            var ShipNumber:int = Math.min(ships, node.ships[team].length);
            for (var i:int = 0; i < ShipNumber; i++) // 遍历每个需调动的飞船
            {
                ship = node.ships[team][i];
                if (ship.state != 0)
                    ShipNumber = Math.min(ShipNumber + 1, node.ships[team].length); // 这里是为了允许快速操作，跳过将要起飞的飞船并将循环次数增加1
                else
                    warp = moveShip(node, ship, team, targetNode);
            }
            if (warp)
                node.showWarpPulse(team); // 播放传送门特效
        }

        private static function moveShip(node:Node, ship:Ship, team:int, targetNode:Node):Boolean {
            if (node.nodeData.type == NodeType.WARP && team == node.nodeData.team) {
                ship.warpTo(targetNode);
                return true;
            } else {
                ship.moveTo(targetNode);
                return false;
            }
        }
    }
}
