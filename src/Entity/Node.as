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
    import flash.geom.Point;
    import starling.display.Image;
    import starling.text.TextField;
    import Entity.EntityHandler;
    import Entity.EntityContainer;
    import utils.Rng;
    import utils.GS;
    import utils.Drawer;
    import Entity.Node.Attack.IAttackStrategy;
    import Entity.Node.Attack.AttackStrategyFactory;
    import Entity.Node.NodeStaticLogic;
    import Entity.Node.NodeData;
    import Entity.Node.NodeType;

    public class Node extends GameEntity {
        // #region 类变量
        // 基本变量
        public var tag:int; // 标记符，debug用
        public var startVal:int; // 初始人口
        public var buildRate:Number; // 生产速度，生产时间的倒数
        public var orbitNode:Node; // 轨道中心天体
        public var orbitDist:Number; // 轨道半径
        public var orbitSpeed:Number; // 轨道运转速度
        public var attackStrategy:IAttackStrategy; // 攻击策略
        // 状态变量
        public var conflict:Boolean; // 战斗状态，判断天体上是否有战斗
        public var capturing:Boolean; // 占据状态
        public var captureTeam:int; // 占领条势力
        public var captureRate:Number; // 占领速度
        public var buildTimer:Number; // 生产计时器
        public var orbitAngle:Number; // 轨道旋转角度
        public var ships:Array; // 第一维储存的每个数组对应一个势力，第二维数组用于储存飞船的引用，一个值指代一个飞船，二维数组的长度表示该天体上该势力的飞船总数

        public var rng:Rng;
        // AI相关变量
        public var aiValue:Number; // ai价值
        public var aiStrength:Number; // ai强度
        public var aiTimers:Array; // ai计时器
        public var transitShips:Array; // 
        public var oppNodeLinks:Array; // 
        public var nodeLinks:Array; // 
        public var breadthFirstSearchNode:Node; // hardAI 寻路，标记父节点
        public var senderType:String; // hardAI 出兵动机
        public var targetType:String; // hardAI 需求动机
        // 贴图相关变量
        public var glow:Image; // 光效图片
        public var image:Image; // 天体图片
        public var halo:Image; // 光圈图片
        public var label:TextField; // 非战斗状态下的兵力文本
        public var glowing:Boolean; // 是否正在发光（天体改变势力时的特效
        public var labels:Array; // 战斗状态下的兵力文本列表
        public var warps:Array; // 是否有传送，只和传送门目的地特效有关
        public var winPulseTimer:Number; // 通关占领特效计时器
        public var triggerTimer:Number; // 用于特殊事件
        public var labelDist:Number; // 文本圈大小
        // 其他变量
        public var winTeam:int; // 获胜势力，游戏结束后在 GameScene.as 中统一
        public var barrierLinks:Array; // 障碍连接数组
        public var barrierCostom:Boolean; // 障碍是否为自定义连接
        public var linked:Boolean; // 是否被连接

        public var nodeData:NodeData;

        // #endregion
        public function Node() {
            super();
            var color:uint = uint(Globals.teamColors[0]);
            image = new Image(Root.assets.getTexture("planet01")); // 设定默认天体
            image.pivotX = image.pivotY = image.width * 0.5;
            image.scaleX = image.scaleY = 0.5;
            image.color = color;
            halo = new Image(Root.assets.getTexture("halo"));
            halo.pivotX = halo.pivotY = halo.width * 0.5;
            halo.scaleX = halo.scaleY = image.scaleY;
            halo.color = color;
            halo.alpha = 0.75;
            glow = new Image(Root.assets.getTexture("planet_shape"));
            glow.pivotX = glow.pivotY = glow.width * 0.5;
            glow.scaleX = glow.scaleY = image.scaleY;
            label = new TextField(60, 48, "00", "Downlink12", -1, Globals.teamColors[0]); // 默认兵力文本
            label.vAlign = label.hAlign = "center";
            label.pivotX = 30;
            label.pivotY = 24;
            nodeLinks = [];
            oppNodeLinks = [];
            barrierLinks = []; // 障碍链接数组
        }

        private function resetArray():void{
            var textField:TextField = null; // 文本
            ships = []; // 第一维储存的每个数组对应一个势力，第二维数组用于储存飞船的引用，一个值指代一个飞船，二维数组的长度表示该天体上该势力的飞船总数
            transitShips = [];
            aiTimers = [];
            warps = [];
            labels = []; // 储存战斗状态下各势力的兵力文本标签
            for (var i:int = 0; i < Globals.teamCount; i++) {
                ships.push([]);
                transitShips.push(0);
                aiTimers.push(0);
                warps.push(false);
                textField = new TextField(60, 48, "00", "Downlink12", -1, Globals.teamColors[i]);
                textField.vAlign = textField.hAlign = "center";
                textField.pivotX = 30;
                textField.pivotY = 24;
                textField.visible = false;
                labels.push(textField);
            }

        }

        // #region 生成天体 移除天体
        public function initNode(_GameScene:GameScene, _rng:Rng, _x:Number, _y:Number, _type:int, _size:Number, _team:int, _OrbitNode:Node = null, _Clockwise:Boolean = true, _OrbitSpeed:Number = 0.1):void {
            super.init(_GameScene);
            nodeData = new NodeData(true);
            nodeData.size = _size;
            nodeData.type = NodeType.switchType(_type);
            nodeData.team = _team;
            nodeData.x = _x;
            nodeData.y = _y;
            this.rng = _rng;
            resetArray()
            captureTeam = _team; // 占据势力
            nodeData.hp = 0; // 占领度
            aiValue = 0;
            if (_team > 0)
                nodeData.hp = 100; // 设定非中立天体默认占领度为100
            buildTimer = 1; // 生产计时器
            triggerTimer = 0;
            winPulseTimer = 0;
            winTeam = -1;
            updateLabelSizes();
            image.visible = halo.visible = glow.visible = true;
            glow.alpha = 0;
            image.x = halo.x = glow.x = label.x = nodeData.x;
            image.y = halo.y = glow.y = label.y = nodeData.y;
            image.color = halo.color = label.color = Globals.teamColors[_team];
            label.y += 50 * _size;
            label.x += 30 * _size;
            barrierCostom = false;
            linked = false;
            glowing = false;
            NodeStaticLogic.changeType(this, NodeType.switchType(_type), _size);
            var _dx:Number = NaN;
            var _dy:Number = NaN;
            if (_OrbitNode) {
                this.orbitNode = _OrbitNode;
                _dx = nodeData.x - _OrbitNode.nodeData.x;
                _dy = nodeData.y - _OrbitNode.nodeData.y;
                orbitDist = Math.sqrt(_dx * _dx + _dy * _dy);
                orbitAngle = Math.atan2(_dy, _dx);
                orbitSpeed = _OrbitSpeed;
                if (!_Clockwise)
                    orbitSpeed = -1 * _OrbitSpeed;
            } else
                this.orbitNode = null;
            entityL.addNode(image, halo, glow);
            entityL.labelLayer.addChild(label);
            var i:int = 0;
            for (i = 0; i < labels.length; i++)
                entityL.labelLayer.addChild(labels[i]);
            for (i = 0; i < aiTimers.length; i++)
                aiTimers[i] = 0;
            for (i = 0; i < transitShips.length; i++)
                transitShips[i] = 0;
        }

        public function initBoss(_GameScene:GameScene, _rng:Rng, _x:Number, _y:Number):void {
            var i:int = 0;
            super.init(_GameScene);
            nodeData = new NodeData(true);
            nodeData.size = 0.4;
            nodeData.type = NodeType.DILATOR;
            nodeData.team = 6;
            this.rng = _rng;
            captureTeam = 6;
            nodeData.hp = 100;
            aiValue = 0;
            buildTimer = 1;
            startVal = 0;
            triggerTimer = 0;
            winPulseTimer = 0;
            winTeam = -1;
            updateLabelSizes();
            nodeData.x = _x;
            nodeData.y = _y;
            image.visible = halo.visible = glow.visible = true;
            image.x = halo.x = label.x = glow.x = nodeData.x;
            image.y = halo.y = label.y = glow.y = nodeData.y;
            image.scaleX = image.scaleY = halo.scaleX = halo.scaleY = glow.scaleX = glow.scaleY = 1;
            image.color = halo.color = glow.color = label.color = Globals.teamColors[nodeData.team];
            label.y += 50 * nodeData.size;
            label.x += 30 * nodeData.size;
            nodeData.lineDist = 150 * nodeData.size;
            labelDist = 180 * nodeData.size;
            orbitNode = null;
            linked = false;
            NodeStaticLogic.changeType(this, NodeType.DILATOR, 0.4);
            nodeData.popVal = 0;
            buildRate = 0;
            startVal = 300;
            halo.readjustSize();
            halo.pivotX = halo.pivotY = halo.width * 0.5;
            entityL.addNode(image, halo, glow);
            entityL.labelLayer.addChild(label);
            for (i = 0; i < labels.length; i++) {
                entityL.labelLayer.addChild(labels[i]);
            }
            for (i = 0; i < aiTimers.length; i++) {
                aiTimers[i] = 0;
            }
            for (i = 0; i < transitShips.length; i++) {
                transitShips[i] = 0;
            }
        }

        public function updateLabelSizes():void {
            var i:int = 0;
            switch (Globals.textSize) // 读取文本大小设置
            {
                case 0: // 大小设置为0
                    label.fontName = "Downlink10"; // 切换和平状态下的字体图
                    label.fontSize = -1; // 默认大小
                    for (i = 0; i < labels.length; i++) // 设定战斗状态下每个势力的文本
                    {
                        labels[i].fontName = "Downlink10";
                        labels[i].fontSize = -1;
                    }
                    break;
                case 1: // 大小设置为1
                    label.fontName = "Downlink12";
                    label.fontSize = -1;
                    for (i = 0; i < labels.length; i++) {
                        labels[i].fontName = "Downlink12";
                        labels[i].fontSize = -1;
                    }
                    break;
                case 2: // 大小设置为2
                    label.fontName = "Downlink18";
                    label.fontSize = -1;
                    for (i = 0; i < labels.length; i++) {
                        labels[i].fontName = "Downlink18";
                        labels[i].fontSize = -1;
                    }
                    return;
            }
        }

        override public function deInit():void {
            var i:int = 0;
            entityL.removeNode(image, halo, glow);
            entityL.labelLayer.removeChild(label); // 移除和平时文本
            for (i = 0; i < labels.length; i++) // 循环移除和战斗时文本
            {
                entityL.labelLayer.removeChild(labels[i]); // 移除文本
            }
            for (i = 0; i < ships.length; i++) // 循环移除每个势力的飞船
            {
                ships[i].length = 0; // 移除遍历势力飞船
                transitShips[i] = 0;
            }
            // 移除其他参数
            barrierLinks.length = 0;
            nodeLinks.length = 0;
            oppNodeLinks.length = 0;
        }

        // #endregion
        // #region 更新
        override public function update(_dt:Number):void {
            var i:int = 0;
            var j:int = 0;
            var l:int = 0;
            var _Ship:Ship = null;
            updateOrbit(_dt); // 更新轨道
            updateImagePositions(); // 更新贴图位置
            label.visible = false; // 默认兵力文本设为不可见
            for (i = 0; i < labels.length; i++) // 战斗时文本也设为不可见
                labels[i].visible = false;
            for (i = 0; i < ships.length; i++) // 处理飞出天体的飞船
            {
                l = int(ships[i].length);
                for (j = 0; j < l; j++) {
                    _Ship = ships[i][j];
                    if (_Ship.state == 0)
                        continue; // 不处理驻留的飞船
                    if (_Ship.state == 1) {
                        if (aiTimers[i] < 0.5)
                            aiTimers[i] = 0.5;
                    } else {
                        ships[i][j] = ships[i][l - 1];
                        ships[i].pop();
                        l--;
                        j--;
                    }
                }
            }
            if (glowing) // 处理势力改变时的光效，先亮度拉满
            {
                glow.alpha += _dt * 4; // 不透明度增加
                if (glow.alpha >= 1) // 亮度满时换贴图颜色
                {
                    glow.alpha = 1;
                    glowing = false;
                    image.color = halo.color = Globals.teamColors[nodeData.team];
                    entityL.addGlow(halo);
                }
            } else if (glow.alpha > 0) // 再归零
            {
                glow.alpha -= _dt * 2; // 不透明度减少
                if (glow.alpha <= 0)
                    glow.alpha = 0;
            }
            for (i = 0; i < warps.length; i++) // 有传送时播放传送门目的地特效
            {
                if (warps[i])
                    showWarpArrive(i);
                warps[i] = false;
            }
            updateTimer(_dt); // 更新各种计时器
            updateAttack(_dt); // 更新天体攻击
            updateConflict(_dt); // 更新飞船攻击
            updateCapture(_dt); // 更新占领度
            updateBuild(_dt); // 更新飞船生产
        }

        public function updateOrbit(_dt:Number):void {
            if (!orbitNode)
                return;
            orbitAngle += orbitSpeed * _dt; // 将轨道角度加上轨道速度*游戏速度
            if (orbitAngle > Math.PI * 2)
                orbitAngle -= Math.PI * 2; // 重置角度
            nodeData.x = orbitNode.nodeData.x + Math.cos(orbitAngle) * orbitDist; // 计算更新后的x坐标
            nodeData.y = orbitNode.nodeData.y + Math.sin(orbitAngle) * orbitDist; // 计算更新后的y坐标
        }

        public function updateImagePositions():void {
            image.x = halo.x = glow.x = nodeData.x;
            image.y = halo.y = glow.y = nodeData.y;
            label.x = nodeData.x + 30 * nodeData.size;
            label.y = nodeData.y + 50 * nodeData.size;
        }

        public function updateTimer(_dt:Number):void {
            for (var i:int = 0; i < aiTimers.length; i++) // 计算AI计时器
            {
                if (aiTimers[i] > 0)
                    aiTimers[i] = Math.max(0, aiTimers[i] - _dt);
            }
            if (triggerTimer > 0)
                triggerTimer = Math.max(0, triggerTimer - _dt);
            if (winPulseTimer > 0) {
                winPulseTimer = Math.max(0, winPulseTimer - _dt);
                if (winPulseTimer == 0)
                    NodeStaticLogic.changeTeam(this, winTeam);
            }
        }

        public function updateAttack(_dt:Number):void {
            if (nodeData.team == 0 && Globals.level != 31)
                return; // 排除32关以外的中立和无范围天体
            if (attackStrategy.attackType != "basic")
                attackStrategy.executeAttack(this, _dt);
        }

        public function updateConflict(_dt:Number):void {
            var i:int = 0;
            var j:int = 0;
            var _Ship:Ship = null;
            var _AttackArray:Array = null;
            var _ShipState0:int = 0;
            var _Attack:Number = NaN;
            var _DisAttack:Array = null;
            var _DisShip:Ship = null;
            var _ArcRatio:Number = NaN;
            var _ArcAngle:Number = NaN;
            var _LableAngle:Number = NaN;
            var _ShipTeam:Array = []; // 统计飞船势力
            var _ShipStat:int = 0; // 该天体上的总飞船数
            var _conflict:Boolean = false;
            for (i = 0; i < ships.length; i++) // 判断是否有战斗
            {
                if (ships[i].length > 0) // 该势力有飞船时执行
                {
                    _ShipTeam.push(i); // 储存该势力
                    _ShipStat += ships[i].length;
                }
                if (_ShipTeam.length > 1)
                    _conflict = true; // 该天体存在两种以上势力飞船时设为战争状态
            }
            if (_conflict) // 在战争状态下
            {
                _AttackArray = []; // 储存各飞船势力的消除量（能够消除的血量）
                for (i = 0; i < _ShipTeam.length; i++) // 计算各飞船势力的消除量
                {
                    _ShipState0 = 0;
                    for (j = 0; j < ships[_ShipTeam[i]].length; j++) // 统计该势力不飞走的飞船数
                    {
                        if (ships[_ShipTeam[i]][j].state == 0)
                            _ShipState0++;
                    }
                    _Attack = Globals.teamShipAttacks[_ShipTeam[i]] * _ShipState0 * 10 * _dt / (_ShipTeam.length - 1); // 计算该势力飞船的总攻击力，公式：10 * 帧时间 * 飞船数 * 势力攻击倍率/（飞船势力数-1）
                    _AttackArray.push(_Attack); // 储存该势力飞船的总攻击力存
                }
                for (i = 0; i < _ShipTeam.length; i++) // 让所有势力被攻击一次
                {
                    for (j = 0; j < _AttackArray.length; j++) // 消除所有攻击势力的消除量
                    {
                        if (i == j)
                            continue; // 不对自身执行
                        _Attack = Number(_AttackArray[j]) / Globals.teamShipDefences[_ShipTeam[i]]; // 记录攻击势力的飞船消除量
                        _DisAttack = ships[_ShipTeam[i]]; // 指向被攻击势力的全部飞船（该天体上
                        while (_Attack > 0 && _DisAttack.length > 0) // 执行对消直到消除量归零或被攻击方没有飞船
                        {
                            _DisShip = _DisAttack[_DisAttack.length - 1]; // 被攻击飞船
                            if (_DisShip.hp > _Attack) {
                                // 血量大于攻击势力消除量时
                                _DisShip.hp -= _Attack;
                                _Attack = 0;
                                break;
                            } else {
                                // 血量小于消除量时
                                _Attack -= _DisShip.hp;
                                _DisAttack.pop();
                                EntityHandler.destroyShip(_DisShip);
                            }
                        }
                    }
                }
                _ArcAngle = -Math.PI / 2 - Math.PI * ships[_ShipTeam[0]].length / _ShipStat;
                _LableAngle = Math.PI * 2 / _ShipTeam.length;
                for (i = 0; i < _ShipTeam.length; i++) {
                    // 绘制战斗弧
                    _ArcRatio = ships[_ShipTeam[i]].length / _ShipStat;
                    Drawer.drawCircle(game.scene.ui.behaviorBatch, nodeData.x, nodeData.y, Globals.teamColors[_ShipTeam[i]], nodeData.lineDist, nodeData.lineDist - 2, false, 1, _ArcRatio - 0.006366197723675814, _ArcAngle + 0.01);
                    _ArcAngle += Math.PI * 2 * _ArcRatio;
                    // 修改兵力文本
                    labels[i].x = nodeData.x + Math.cos(-Math.PI / 2 + i * _LableAngle) * labelDist;
                    labels[i].y = nodeData.y + Math.sin(-Math.PI / 2 + i * _LableAngle) * labelDist;
                    labels[i].text = ships[_ShipTeam[i]].length.toString();
                    labels[i].color = Globals.teamColors[_ShipTeam[i]];
                    if (labels[i].color > 0)
                        labels[i].visible = true;
                }
            }
            conflict = _conflict;
        }

        public function updateCapture(_dt:Number):void {
            if (conflict) // 战争状态下不执行该函数
            {
                capturing = false;
                return;
            }
            var _capturing:Boolean = false;
            var _captureTeam:int = 0;
            for (var i:int = 0; i < ships.length; i++) // 判定占据状态，计算占据势力
            {
                if (ships[i].length > 0) {
                    if (i != nodeData.team)
                        _capturing = true;
                    _captureTeam = i;
                    if (nodeData.team == 0 && nodeData.hp == 0)
                        captureTeam = _captureTeam;
                    break;
                }
            }
            captureRate = ships[_captureTeam].length / (nodeData.size * 100) * 10;
            captureRate /= nodeData.hpMult * Globals.teamConstructionStrengths[nodeData.team]; // 计算占领速度加权
            if (Globals.level > 31 && Globals.level < 35 && nodeData.type == NodeType.DILATOR)
                captureRate = 0; // 禁止 33 34 35 星核被占领
            captureRate = Math.min(captureRate, 100); // 防止占领速度超过100
            if (nodeData.team == 0) // 特殊化中立占领度
            {
                if (captureTeam == _captureTeam)
                    nodeData.hp = Math.min(nodeData.hp + Globals.teamColonizingSpeeds[_captureTeam] * captureRate * _dt, 100); // 占领条同占据势力则增加占领度
                else
                    nodeData.hp = Math.max(0, nodeData.hp - Globals.teamDecolonizingSpeeds[_captureTeam] * captureRate * _dt); // 否则减少占领度
            } else {
                if (captureTeam == _captureTeam)
                    nodeData.hp = Math.min(nodeData.hp + Globals.teamRepairingSpeeds[_captureTeam] * captureRate * _dt, 100); // 占领条同占据势力则增加占领度
                else
                    nodeData.hp = Math.max(0, nodeData.hp - Globals.teamDestroyingSpeeds[_captureTeam] * captureRate * _dt); // 否则减少占领度
            }
            if (_capturing || nodeData.hp != 100 && captureTeam == _captureTeam && nodeData.team != 0) // 占据状态下显示占领条
            {
                var _ArcAngle:Number = -Math.PI / 2 - Math.PI * (nodeData.hp / 100);
                Drawer.drawCircle(game.scene.ui.behaviorBatch,nodeData.x, nodeData.y, Globals.teamColors[captureTeam], nodeData.lineDist, nodeData.lineDist - 2, false, 0.1);
                Drawer.drawCircle(game.scene.ui.behaviorBatch,nodeData.x, nodeData.y, Globals.teamColors[captureTeam], nodeData.lineDist, nodeData.lineDist - 2, false, 0.7, nodeData.hp / 100, _ArcAngle);
            }
            if (_captureTeam != 0) // 非中立飞船占据显示兵力
            {
                label.text = ships[_captureTeam].length.toString();
                label.color = Globals.teamColors[_captureTeam];
                label.visible = (label.color > 0);
            }
            if (Globals.level == 31 && nodeData.type == NodeType.DILATOR)
                return;
            if (nodeData.team == 0 && nodeData.hp == 100)
                NodeStaticLogic.changeTeam(this, captureTeam); // 中立天体占领度满时变为占领度势力
            if (nodeData.team != 0 && nodeData.hp == 0 && winTeam == -1)
                NodeStaticLogic.changeTeam(this, 0); // 非中立天体占领度空时变为中立
            capturing = _capturing;
        }

        public function updateBuild(_dt:Number):void {
            if (nodeData.team == 0 || Globals.teamPops[nodeData.team] >= Globals.teamCaps[nodeData.team] || capturing || conflict && ships[nodeData.team].length == 0)
                return; // 不产兵条件：中立/兵力到上限/被占据/战争状态没自己兵
            buildTimer -= buildRate * Globals.teamNodeBuilds[nodeData.team] * _dt; // 计算生产计时器
            while (buildTimer <= 0) // 计时结束时
            {
                buildTimer += 1; // 重置倒计时
                EntityHandler.addShip(this, nodeData.team); // 生产飞船
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
                if (_Node != this && _Node.nodeData.type != NodeType.BARRIER) {
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
                if (this.buildRate > 0 && nodeData.team == i)
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
            if (this.buildRate > 0 && _team == nodeData.team)
                _Strength *= 1.25;
            return _Strength;
        }

        // 计算可到达的有前往价值的天体
        public function getOppLinks(_team:int):void {
            oppNodeLinks.length = 0;
            for each (var _Node:Node in nodeLinks) {
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
        // #region 一般计算工具函数

        // 计算指定势力可到达的天体
        public function getNodeLinks(_team:int):void {
            nodeLinks.length = 0;
            for each (var _Node:Node in EntityContainer.nodes) {
                if (_Node == this || _Node.nodeData.type == NodeType.BARRIER || (_Node.nodeData.type == NodeType.DILATOR && Globals.level != 35))
                    continue;
                if (nodesBlocked(this, _Node) == null || nodeData.type == NodeType.WARP && nodeData.team == _team)
                    nodeLinks.push(_Node);
            }
        }

        // 判断路径是否被拦截并计算拦截点
        public function nodesBlocked(_Node1:Node, _Node2:Node):Point {
            var _bar1:Point = null;
            var _bar2:Point = null;
            var _Intersection:Point = null;
            var l:int = game.barrierLines.length;
            if (l == 0)
                return null;
            for (var i:int = 0; i < l; i++) {
                _bar1 = game.barrierLines[i][0];
                _bar2 = game.barrierLines[i][1];
                _Intersection = EntityContainer.getIntersection(_Node1.nodeData.x, _Node1.nodeData.y, _Node2.nodeData.x, _Node2.nodeData.y, _bar1.x, _bar1.y, _bar2.x, _bar2.y); // 计算交点
                if (_Intersection)
                    return _Intersection;
            }
            return null;
        }

        // 计算需连接的障碍
        public function getBarrierLinks():void {
            var _dx:Number = NaN;
            var _dy:Number = NaN;
            for each (var _Node:Node in EntityContainer.nodes) {
                if (_Node == this || _Node.nodeData.type != NodeType.BARRIER)
                    continue;
                if (_Node.nodeData.x != nodeData.x && _Node.nodeData.y != nodeData.y)
                    continue; // 横纵坐标至少有一个相等
                _dx = _Node.nodeData.x - nodeData.x;
                _dy = _Node.nodeData.y - nodeData.y;
                if (Math.sqrt(_dx * _dx + _dy * _dy) < 180)
                    barrierLinks.push(_Node);
            }
        }

        // 计算交点

        // #endregion
        // #region 特效与绘图
        public function bossAppear():void {
            image.visible = false;
            halo.visible = false;
            glow.visible = false;
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
            image.visible = true;
            halo.visible = true;
            glow.visible = true;
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
            image.visible = false;
            halo.visible = false;
            glow.visible = false;
            active = false;
        }

        public function showWarpPulse(_team:int):void {
            var _delay:Number = 0;
            var _rate:Number = 2.6;
            var _delayStep:Number = 0.12;
            var _angle:Number = 1.5707963267948966;
            var _maxSize:Number = 1;
            for (var i:int = 0; i < 3; i++) {
                FXHandler.addDarkPulse(this, Globals.teamColors[_team], 1, _maxSize, _rate, _angle, _delay);
                _delay += _delayStep;
                _angle += 2.0943951023931953;
                FXHandler.addDarkPulse(this, Globals.teamColors[_team], 1, _maxSize, _rate, _angle, _delay);
                _delay += _delayStep;
                _angle += 2.0943951023931953;
                FXHandler.addDarkPulse(this, Globals.teamColors[_team], 1, _maxSize, _rate, _angle, _delay);
                _delay += _delayStep;
                _angle += 2.0943951023931953;
                _rate *= 1.1;
                _delayStep *= 0.9;
                _maxSize *= 0.8;
            }
            FXHandler.addDarkPulse(this, Globals.teamColors[_team], 2, 2, 2, 0);
            GS.playWarpCharge(nodeData.x);
        }

        public function showWarpArrive(_team:int):void {
            var _rate:Number = 2;
            var _angle:Number = 1.5707963267948966;
            var _maxSize:Number = nodeData.size * 2;
            FXHandler.addDarkPulse(this, Globals.teamColors[_team], 0, _maxSize, _rate, _angle, 0);
            _angle += 2.0943951023931953;
            FXHandler.addDarkPulse(this, Globals.teamColors[_team], 0, _maxSize, _rate, _angle, 0);
            _angle += 2.0943951023931953;
            FXHandler.addDarkPulse(this, Globals.teamColors[_team], 0, _maxSize, _rate, _angle, 0);
            _angle += 2.0943951023931953;
            _rate *= 1.1;
            _maxSize *= 1.2;
            FXHandler.addDarkPulse(this, Globals.teamColors[_team], 3, 18 * nodeData.size, 28 * nodeData.size, 0);
        }

        public function fireBeam(_Ship:Ship):void {
            FXHandler.addBeam(this, _Ship); // 播放攻击特效
            GS.playLaser(nodeData.x); // 播放攻击音效
        }
        // #endregion
    }
}
