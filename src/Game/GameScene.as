/*EntityPool：nodes,ais,ships,warps,beams,pules,flashs,barriers,explosions,darkpulses,fades
   实体池会记录场上的所有实体到对应的active列表中
 */
package Game {
    import flash.geom.Point;
    import starling.animation.Juggler;
    import starling.core.Starling;
    import starling.display.Image;
    import starling.display.Quad;
    import starling.display.QuadBatch;
    import starling.display.Sprite;
    import starling.events.EnterFrameEvent;
    import flash.ui.Keyboard;
    import utils.Rng;
    import utils.GS;
    import Entity.EntityPool;
    import Entity.Utils;
    import Entity.EntityHandler;
    import Entity.Node;
    import Entity.Ship;
    import Entity.FXHandler;
    import UI.Component.TutorialSprite;
    import starling.display.BlendMode;
    import UI.UIContainer;
    import starling.text.TextField;
    import starling.utils.VAlign;

    public class GameScene extends Sprite {
        // #region 类变量
        // 实体池
        public var entities:Array;
        public var ais:EntityPool; // AI
        public var nodes:EntityPool; // 天体
        public var ships:EntityPool; // 飞船
        public var ases:EntityPool;
        public var warps:EntityPool; // 传送门特效
        public var beams:EntityPool; // 攻击塔射线
        public var pulses:EntityPool; // 波
        public var flashes:EntityPool; // 飞船爆炸光效
        public var barriers:EntityPool; // 障碍线
        public var explosions:EntityPool; // 飞船爆炸特效
        public var darkPulses:EntityPool; // 通用特效
        public var fades:EntityPool; // 选中特效
        // 其他
        public var cover:Quad; // 通关时的遮罩
        public var barrierLines:Array;
        public var tutorial:TutorialSprite;
        public var level:int;
        public var gameOver:Boolean;
        public var gameOverTimer:Number;
        public var winningTeam:int;
        public var triggers:Array;
        public var juggler:Juggler;
        public var darkPulse:Image;
        public var bossTimer:Number;
        public var slowMult:Number;

        public var rng:Rng;

        public var scene:SceneController
        public var ui:UIContainer;
        public var popLabels:Vector.<TextField>;

        public var rep:Boolean = false;

        // #endregion
        public function GameScene(_scene:SceneController) {
            super();
            this.scene = _scene
            Utils.game = this;
            FXHandler.game = this;
            EntityHandler.game = this;
            // 通关时的遮罩
            cover = new Quad(1024, 768, 16777215);
            cover.touchable = false;
            cover.blendMode = BlendMode.ADD;
            cover.alpha = 0;
            addChild(cover);
            // 其他可视化对象
            juggler = new Juggler();
            darkPulse = new Image(Root.assets.getTexture("halo"));
            darkPulse.pivotY = darkPulse.pivotX = darkPulse.width * 0.5;
            darkPulse.x = 512;
            darkPulse.y = 384;
            darkPulse.color = 0;
            darkPulse.visible = false;
            ais = new EntityPool();
            nodes = new EntityPool();
            ships = new EntityPool();
            warps = new EntityPool();
            beams = new EntityPool();
            pulses = new EntityPool();
            flashes = new EntityPool();
            barriers = new EntityPool();
            explosions = new EntityPool();
            darkPulses = new EntityPool();
            fades = new EntityPool();
            entities = [ships, nodes, ais, warps, beams, pulses, flashes, barriers, explosions, darkPulses, fades]; // 实体池列表
            triggers = [false, false, false, false, false]; // 特殊事件
            barrierLines = []; // 障碍连接数据
            tutorial = new TutorialSprite();
            this.alpha = 0;
            this.visible = false;
            gameOver = true;
            popLabels = new Vector.<TextField>(3, true);
            var _Color:Number = 16755370;
            popLabels[0] = new TextField(600, 40, "POPULATION : 50 / 50", "Downlink12", -1, _Color);
            popLabels[1] = new TextField(600, 40, "POPULATION : 50 / 50", "Downlink12", -1, _Color);
            popLabels[2] = new TextField(200, 40, "+ 30", "Downlink12", -1, _Color);
            for (var i:int = 0; i < 3; i++) {
                var label:TextField = popLabels[i];
                label.vAlign = label.hAlign = VAlign.CENTER;
                label.pivotX = 300;
                label.pivotY = 20;
                label.alpha = 0.5;
                label.x = 512;
                label.y = 136;
            }
            popLabels[1].alpha = 0;
            popLabels[2].hAlign = "left";
            popLabels[2].pivotX = 0;
            popLabels[2].alpha = 0;
        }

        // #region 进入关卡
        public function init(seed:uint = 0, rep:Boolean = false):void {
            ui = scene.ui;
            ui.entityL.addGlow(darkPulse);
            var i:int = 0;
            var _aiArray:Array = [];
            this.level = Globals.level;
            this.rng = new Rng(seed)
            this.rep = rep
            _aiArray = nodeIn(); // 生成天体，同时返回需生成的ai
            if (!rep)
                Globals.replay = [rng.seed, [0]];
            else {
                for(i = 0; i < _aiArray.length; i++)
                    rng.nextInt();
                _aiArray = [];
                Globals.replay.shift();
            }
            for (i = 0; i < _aiArray.length; i++) {
                Globals.currentDifficulty == 3 ? EntityHandler.addAI(_aiArray[i], 4) : EntityHandler.addAI(_aiArray[i], Globals.currentDifficulty - 1); // 为有天体的常规势力添加ai
            }
            if (Globals.level >= 35 && !rep) { // 为36关黑色设定ai
                Globals.currentDifficulty == 3 ? EntityHandler.addAI(6, 4) : EntityHandler.addAI(6, 3);
                bossTimer = 0;
            }
            for (i = 0; i < triggers.length; i++)
                triggers[i] = false; // 重置特殊事件
            for each (var label:TextField in popLabels) {
                switch (Globals.textSize) {
                    case 0:
                    case 1:
                        label.fontName = "Downlink12";
                        break;
                    case 2:
                        label.fontName = "Downlink18";
                }
                label.fontSize = -1;
                ui.btnL.addChild(label);
            }
            // 执行一些初始化函数
            tutorial.init(this, level);
            getBarrierLines();
            addBarriers();
            hideSingleBarriers();
            if (darkPulse)
                darkPulse.visible = false;
            // 重置一些变量
            this.alpha = 0;
            this.visible = true;
            cover.alpha = 0;
            gameOver = false;
            gameOverTimer = 3;
            winningTeam = -1;
            // 以下部分决定bgm的播放
            if (Globals.level < 9)
                GS.playMusic("bgm02");
            else if (Globals.level < 23)
                GS.playMusic("bgm04");
            else if (Globals.level < 32)
                GS.playMusic("bgm05");
            else
                GS.playMusic("bgm06");
            addEventListener("enterFrame", update); // 添加帧监听器，每帧执行一次update
            animateIn(); // 播放关卡进入动画
        }

        // 生成天体并返回需添加的ai
        public function nodeIn():Array {
            var _Node:Node = null;
            var _Level:Array = LevelData.maps[level];
            var _aiArray:Array = [];
            for each (var _NodeData:Array in _Level) {
                // 处理每个天体
                _NodeData.length >= 7 ? _Node = EntityHandler.addNode(_NodeData[0], _NodeData[1], _NodeData[2], _NodeData[3], _NodeData[4], _NodeData[5], _NodeData[6]) : _Node = EntityHandler.addNode(_NodeData[0], _NodeData[1], _NodeData[2], _NodeData[3], _NodeData[4], _NodeData[5]);
                if (Globals.level != 31) {
                    // 修改32关之外的天体数据
                    if (Globals.level == 35 && _Node.team == 6)
                        _Node.startVal = 0; // 36关黑色除星核无初始兵力
                    if (_Node.type == 5) {
                        // 设定星核数据
                        _Node.buildRate = 8;
                        _Node.popVal = 280;
                        _Node.startVal = Globals.currentDifficulty * 75;
                    }
                }
                if (_NodeData.length >= 8) // 检验第八项数据(自定义兵力或障碍)
                {
                    if (_NodeData[7] is Array) {
                        if (_Node.type == 3) {
                            // 障碍
                            _Node.barrierLinks.length = 0;
                            _Node.barrierCostom = true;
                            for each (var _Barrier:int in _NodeData[7])
                                _Node.barrierLinks.push(_Barrier);
                        } else {
                            // 兵力
                            for (var i:int = 0; i < _NodeData[7].length; i++)
                                EntityHandler.addShips(_Node, i, _NodeData[7][i]);
                        }
                        _Node.startVal = 0; // 禁用原版初始人口设定
                    } else {
                        if (_Node.type == 3) {
                            // 障碍
                            _Node.barrierLinks.length = 0;
                            _Node.barrierCostom = true;
                            _Node.barrierLinks.push(_NodeData[7]);
                        } else
                            _Node.startVal = int(_NodeData[7]); // 设定初始人口为该参数
                    }
                }
                if (_aiArray.indexOf(_NodeData[4]) == -1) {
                    // 写入具有常规ai的势力，此处检验势力是否已写入，避免重复写入
                    switch (_NodeData[4]) {
                        case 0: // 排除中立势力
                        case 1: // 排除玩家势力
                        case 5: // 排除灰色势力
                        case 6: // 排除黑色势力
                            break;
                        default:
                            _aiArray.push(_NodeData[4]);
                            break;
                    }
                }
                if (_Node.team > 0 && _Node.startVal > 0)
                    EntityHandler.addShips(_Node, _Node.team, _Node.startVal); // 为非中立天体添加初始飞船
            }
            return _aiArray;
        }

        public function animateIn():void {
            this.alpha = 0;
            this.visible = true;
            Starling.juggler.tween(this, Globals.transitionSpeed, {"alpha": 1,
                    "transition": "easeInOut"});
        }

        private function check4same(_Array1:Array, _Array2:Array):Boolean {
            var _1:Point = _Array1[0];
            var _2:Point = _Array1[1];
            var _3:Point = _Array2[0];
            var _4:Point = _Array2[1];
            var _result:Boolean = false;
            if (_1.x == _3.x && _1.y == _3.y && _2.x == _4.x && _2.y == _4.y)
                _result = true;
            if (_1.x == _4.x && _1.y == _4.y && _2.x == _3.x && _2.y == _3.y)
                _result = true;
            return _result;
        }

        // #endregion
        // #region 界面功能
        public function deInit():void {
            tutorial.deInit();
            for each (var _pool:EntityPool in entities)
                _pool.deInit();
            removeEventListener("enterFrame", update); // 移除更新帧监听器
        }

        // 移除UI，执行animateOut()
        public function quit():void {
            animateOut();
            scene.exit2TitleMenu(0);
        }

        // 解锁下一关，执行animateOut()
        public function next():void {
            animateOut();
            if (!Globals.levelData[Globals.level])
                Globals.levelData.push(0);
            if (Globals.levelData[Globals.level] < Globals.currentDifficulty)
                Globals.levelData[Globals.level] = Globals.currentDifficulty;
            if (Globals.levelReached < Globals.level + 1) {
                Globals.levelReached = Globals.level + 1;
                Globals.save();
                scene.exit2TitleMenu(1);
            } else
                Globals.save();
            scene.exit2TitleMenu(0);
        }

        // 关卡退出动画，执行hide()
        public function animateOut():void {
            Starling.juggler.tween(this, Globals.transitionSpeed, {"alpha": 0,
                    "onComplete": hide,
                    "transition": "easeInOut"});
        }

        // 隐藏UI，执行deInit()
        public function hide():void {
            this.visible = false;
            deInit();
        }

        public function pause():void {
            Globals.main.on_deactivate(null);
        }

        public function restart():void {
            Starling.juggler.tween(this, 0.1, {"alpha": 0,
                    "transition": "easeIn",
                    "onComplete": function():void
                    {
                        deInit();
                        init();
                    }});
        }

        // #endregion
        // #region 逐帧更新
        public function update(e:EnterFrameEvent):void {
            var dt:Number = e.passedTime;
            if (this.alpha == 0)
                return;
            GS.update(dt); // 更新音效计时器
            dt *= this.alpha; // wtf？？
            dt = updateSpeed(dt); // 更新游戏速度
            Debug.update(e);
            var arr:Array;
            if (Globals.replay.length == 0) {
                updateGame(dt);
                return;
            }
            if (!rep) {
                var l:int = Globals.replay[Globals.replay.length - 1].length;
                for(var i:int = 1; i < l; i++)
                {
                    arr = Globals.replay[Globals.replay.length - 1][i];
                    nodes.active[arr[0]].moveShips(arr[1], nodes.active[arr[2]], arr[3]);
                }
                Globals.replay.push([dt]);
                updateGame(dt);
            } else {
                dt = Globals.replay[0].shift();
                updateGame(dt);
                for each (arr in Globals.replay[0]) {
                    nodes.active[arr[0]].moveShips(arr[1], nodes.active[arr[2]], arr[3]);
                }
                Globals.replay.shift();
            }
        }

        public function updateGame(dt:Number):void {
            countTeamCaps(dt); // 统计兵力
            juggler.advanceTime(dt);
            ui.update();
            for each (var _pool:EntityPool in entities) // 依次执行所有实体的更新函数
                _pool.update(dt);
            specialEvents(); // 处理特殊关卡的特殊事件
            if (darkPulse.visible)
                expandDarkPulse(dt);
            if (Globals.level != 35)
                updateGameOver(dt);
            updateBarrier();
        }

        public function updateSpeed(_dt:Number):Number {
            if (Globals.level == 35 && gameOver) {
                // 36关通关时
                slowMult = Math.max(slowMult - _dt * 0.75, 0.1);
                _dt *= slowMult;
            } else if (!((Globals.level == 31 || Globals.level == 35) && triggers[0]))
                _dt *= scene.speedMult;
            return _dt;
        }

        public function countTeamCaps(_dt:Number):void {
            for (var _team:int = 0; _team < Globals.teamCount; _team++) {
                // 重置兵力
                Globals.teamCaps[_team] = 0;
                Globals.teamPops[_team] = 0;
            }
            for each (var _Node:Node in nodes.active) // 统计兵力上限
                Globals.teamCaps[_Node.team] += _Node.popVal * Globals.teamNodePops[_Node.team];
            for each (var _Ship:Ship in ships.active) // 统计总兵力
                Globals.teamPops[_Ship.team]++;
            ships.active.length < 1024 ? Globals.exOptimization = 0 : (ships.active.length < 8192 ? Globals.exOptimization = 1 : Globals.exOptimization = 2);

            popLabels[0].text = popLabels[1].text = "POPULATION : " + Globals.teamPops[1] + " / " + Globals.teamCaps[1];
            if (popLabels[1].alpha > 0)
                popLabels[1].alpha = Math.max(0, popLabels[1].alpha - _dt * 0.5);
            if (popLabels[2].alpha > 0) {
                popLabels[2].x = 512 + popLabels[0].textBounds.width * 0.5 + 10;
                popLabels[2].alpha = Math.max(0, popLabels[2].alpha - _dt * 0.5);
            }
        }

        public function specialEvents():void {
            var i:int;
            var _boss:Node;
            var _timer:Number;
            var _rate:Number;
            var _addTime:Number;
            var _angle:Number;
            var _angleStep:Number;
            var _size:Number;
            var _bossParam:int;
            switch (Globals.level) // 处理特殊关卡的特殊事件
            {
                case 0: // 前两关处理教程提示
                    if (!triggers[0])
                        if (nodes.active[0].ships[1].length < 60)
                            triggers[0] = true;
                    break;
                case 1:
                    if (!triggers[0])
                        if (ui.btnL.fleetSlider.perc < 1)
                            triggers[0] = true;
                    break;
                case 31:
                    if (!triggers[0]) {
                        _boss = nodes.active[0];
                        if (_boss.hp == 100) {
                            triggers[0] = true;
                            _timer = 0;
                            _rate = 0.5;
                            _addTime = 1;
                            _angle = 1.5707963267948966;
                            _angleStep = 2.0943951023931953;
                            _size = 2;
                            for (i = 0; i < 64; i++) {
                                FXHandler.addDarkPulse(_boss, 0, 1, _size, _rate, _angle, _timer);
                                _timer += _addTime;
                                _angle += _angleStep;
                                FXHandler.addDarkPulse(_boss, 0, 1, _size, _rate, _angle, _timer);
                                _timer += _addTime;
                                _angle += _angleStep;
                                FXHandler.addDarkPulse(_boss, 0, 1, _size, _rate, _angle, _timer);
                                _timer += _addTime;
                                _angle += _angleStep;
                                if (i < 20) {
                                    _rate *= 1.1;
                                    _addTime *= 0.85;
                                }
                                _size *= 0.975;
                            }
                            FXHandler.addDarkPulse(_boss, 0, 2, 2.5, 0.75, 0, _timer - 5.5);
                            FXHandler.addDarkPulse(_boss, 0, 2, 2.5, 1, 0, _timer - 4.5);
                            _boss.triggerTimer = _timer - 3;
                            Starling.juggler.tween(Globals, 5, {"soundMult": 0});
                            GS.playMusic("bgm_dark", false);
                        }
                    }
                    if (triggers[0] && !triggers[1]) {
                        _boss = nodes.active[0];
                        if (_boss.triggerTimer == 0) {
                            triggers[1] = true;
                            _boss.bossReady();
                            _boss.changeTeam(6);
                            _boss.changeShipsTeam(6);
                            EntityHandler.addAI(6, 2);
                            _boss.triggerTimer = 3;
                            darkPulse.team = 6;
                            darkPulse.scaleX = darkPulse.scaleY = 0;
                            darkPulse.visible = true;
                        }
                    }
                    if (triggers[1] && !triggers[2]) {
                        _boss = nodes.active[0];
                        if (_boss.triggerTimer == 0) {
                            triggers[2] = true;
                            _boss.bossDisappear();
                        }
                    }
                    break;
                case 32:
                case 33:
                case 34:
                    if (!triggers[0]) // 阶段一，生成星核
                    {
                        for (i = 0; i < Globals.teamCaps.length; i++) {
                            if (Globals.teamCaps[i] > 220 && Globals.teamPops[i] > 220) {
                                _boss = nodes.getReserve() as Node;
                                if (!_boss)
                                    _boss = new Node();
                                _boss.initBoss(this, new Rng(rng.nextInt(), Rng.X32), 512, 384);
                                nodes.addEntity(_boss);
                                _boss.bossAppear();
                                triggers[0] = true;
                                GS.fadeOutMusic(2);
                                GS.playSound("boss_appear");
                                break;
                            }
                        }
                    }
                    if (triggers[0] && !triggers[1]) // 阶段二，生成飞船，添加ai
                    {
                        _boss = nodes.active[nodes.active.length - 1];
                        if (_boss.triggerTimer == 0) {
                            triggers[1] = true;
                            _boss.bossReady();
                            if (Globals.currentDifficulty != 3)
                                _bossParam = (Globals.level == 33) ? 320 : 350;
                            else
                                _bossParam = (Globals.level == 34) ? 400 : 350;
                            EntityHandler.addShips(_boss, 6, _bossParam);
                            _bossParam = (Globals.currentDifficulty == 3) ? 4 : 2;
                            EntityHandler.addAI(6, _bossParam);
                            _boss.triggerTimer = 3;
                            GS.playSound("boss_ready", 1.5);
                        }
                    }
                    if (triggers[1] && !triggers[2]) // 阶段三，星核消失动画
                    {
                        _boss = nodes.active[nodes.active.length - 1];
                        if (_boss.triggerTimer == 0) {
                            triggers[2] = true;
                            _boss.bossDisappear();
                            GS.playSound("boss_reverse");
                        }
                    }
                    if (triggers[2] && !triggers[3]) // 阶段四，移除星核
                    {
                        _boss = nodes.active[nodes.active.length - 1];
                        if (_boss.triggerTimer == 0) {
                            triggers[3] = true;
                            _boss.bossHide();
                            _boss.active = false;
                            GS.playMusic("bgm06");
                        }
                    }
                    break;
                case 35:
                    if (!gameOver) {
                        _boss = nodes.active[0];
                        if (!triggers[0] && _boss.hp == 0) // 阶段一，坍缩动画
                        {
                            triggers[0] = true;
                            _timer = 0;
                            _rate = 0.5;
                            _addTime = 1;
                            _angle = 1.5707963267948966;
                            _angleStep = 2.0943951023931953;
                            _size = 2;
                            for (i = 0; i < 64; i++) {
                                FXHandler.addDarkPulse(_boss, Globals.teamColors[1], 1, _size, _rate, _angle, _timer);
                                _timer += _addTime;
                                _angle += _angleStep;
                                FXHandler.addDarkPulse(_boss, Globals.teamColors[1], 1, _size, _rate, _angle, _timer);
                                _timer += _addTime;
                                _angle += _angleStep;
                                FXHandler.addDarkPulse(_boss, Globals.teamColors[1], 1, _size, _rate, _angle, _timer);
                                _timer += _addTime;
                                _angle += _angleStep;
                                if (i < 20) {
                                    _rate *= 1.1;
                                    _addTime *= 0.85;
                                }
                                _size *= 0.975;
                            }
                            FXHandler.addDarkPulse(_boss, Globals.teamColors[1], 2, 2.5, 0.75, 0, _timer - 5.5);
                            FXHandler.addDarkPulse(_boss, Globals.teamColors[1], 2, 2.5, 1, 0, _timer - 4.5);
                            _boss.triggerTimer = _timer - 2.5;
                            if (Globals.levelReached == 35)
                                Globals.levelReached = 36;
                            if (Globals.levelData[Globals.level] < Globals.currentDifficulty)
                                Globals.levelData[Globals.level] = Globals.currentDifficulty;
                            Globals.save();
                            GS.playMusic("bgm07", false);
                            Starling.juggler.tween(Globals, 10, {"soundMult": 0});
                            invisibleMode();
                        }
                        if (triggers[0] && !triggers[1]) // 阶段二，膨胀动画
                        {
                            _boss = nodes.active[0];
                            if (_boss.triggerTimer == 0) {
                                triggers[1] = true;
                                _timer = 0;
                                _rate = 2;
                                _addTime = 0.15;
                                _angle = 1.5707963267948966;
                                _angleStep = 2.0943951023931953;
                                _size = 1.75;
                                for (i = 0; i < 9; i++) {
                                    FXHandler.addDarkPulse(_boss, Globals.teamColors[1], 0, _size, _rate, _angle, _timer);
                                    _timer += _addTime;
                                    _angle += _angleStep;
                                    FXHandler.addDarkPulse(_boss, Globals.teamColors[1], 0, _size, _rate, _angle, _timer);
                                    _timer += _addTime;
                                    _angle += _angleStep;
                                    FXHandler.addDarkPulse(_boss, Globals.teamColors[1], 0, _size, _rate, _angle, _timer);
                                    _timer += _addTime;
                                    _angle += _angleStep;
                                    _size *= 1.2;
                                }
                                FXHandler.addDarkPulse(_boss, Globals.teamColors[1], 3, 20, 5, 0, _timer - 3.5);
                                FXHandler.addDarkPulse(_boss, Globals.teamColors[1], 3, 25, 10, 0, _timer - 3.5);
                                FXHandler.addDarkPulse(_boss, Globals.teamColors[1], 3, 30, 15, 0, _timer - 3.5);
                                FXHandler.addDarkPulse(_boss, Globals.teamColors[1], 3, 40, 20, 0, _timer - 4);
                                FXHandler.addDarkPulse(_boss, Globals.teamColors[1], 3, 50, 25, 0, _timer - 4);
                                FXHandler.addDarkPulse(_boss, Globals.teamColors[1], 3, 60, 30, 0, _timer - 4);
                                FXHandler.addDarkPulse(_boss, Globals.teamColors[1], 3, 50, 20, 0, _timer - 3);
                                FXHandler.addDarkPulse(_boss, Globals.teamColors[1], 3, 60, 30, 0, _timer - 2);
                                FXHandler.addDarkPulse(_boss, Globals.teamColors[1], 3, 50, 6, 0, _timer - 2);
                                FXHandler.addDarkPulse(_boss, Globals.teamColors[1], 3, 60, 8, 0, _timer - 2);
                                _boss.triggerTimer = _timer - 3.5;
                            }
                        }
                        if (triggers[1] && !triggers[2]) // 阶段三，画面缩小，天体消失，回到主界面
                        {
                            _boss = nodes.active[0];
                            if (_boss.triggerTimer == 0) {
                                _boss.active = false;
                                gameOver = true;
                                gameOverTimer = 1;
                                slowMult = 1;
                                triggers[2] = true;
                                darkPulse.team = 1;
                                darkPulse.scaleX = darkPulse.scaleY = 0;
                                darkPulse.visible = true;
                                Starling.juggler.tween(ui.gameContainer, 25, {"scaleX": 0.01,
                                        "scaleY": 0.01,
                                        "delay": 20,
                                        "transition": "easeInOut"}); // 画面缩小动画
                                Starling.juggler.tween(this, 5, {"alpha": 0,
                                        "delay": 40,
                                        "onComplete": hide}); // 天体消失动画
                                Starling.juggler.delayCall(function():void {
                                    scene.playEndScene();
                                }, 40); // 退回到主界面
                            }
                        }
                        if (triggers[2] && gameOver) {
                        }
                    }
                    break;
                default:
                    return;
            }
        }

        public function expandDarkPulse(_dt:Number):void {
            var _team:int = darkPulse.team;
            var _Node:Node = null;
            var _x:Number = NaN;
            var _y:Number = NaN;
            var _Distance:Number = NaN;
            var _Ship:Ship = null;
            darkPulse.color = Globals.teamColors[_team];
            darkPulse.color == 0 ? darkPulse.blendMode = "normal" : darkPulse.blendMode = "add";
            _team == 1 ? darkPulse.scaleX += _dt * 2 : darkPulse.scaleX += _dt * 0.5;
            darkPulse.scaleY = darkPulse.scaleX;
            if (darkPulse.width > 3072) {
                darkPulse.visible = false;
                gameOver = true;
                winningTeam = 1;
                gameOverTimer = 0.5;
            }
            for each (_Node in nodes.active) {
                if (_Node.team == _team || _Node.type == 3)
                    continue;
                _x = _Node.x - darkPulse.x;
                _y = _Node.y - darkPulse.y;
                _Distance = Math.sqrt(_x * _x + _y * _y);
                if (_Distance < darkPulse.width * 0.25) {
                    _Node.changeTeam(_team);
                    _Node.changeShipsTeam(_team);
                    _Node.hp = 100;
                }
            }
            for each (_Ship in ships.active) {
                if (_Ship.team == _team)
                    continue;
                _x = _Ship.x - darkPulse.x;
                _y = _Ship.y - darkPulse.y;
                _Distance = Math.sqrt(_x * _x + _y * _y);
                if (_Distance < darkPulse.width * 0.25)
                    _Ship.changeTeam(_team);
            }
        }

        public function updateGameOver(_dt:Number):void {
            if (!gameOver) // 通关判断
            {
                checkWinningTeam();
                if (Globals.level == 31)
                    gameOver = false; // 32关禁用常规通关判定
                if (gameOver) // 处理游戏结束时的动画
                {
                    var _ripple:int = 1;
                    for each (var _Node:Node in nodes.active) {
                        if (_Node.type == 3)
                            continue;
                        _Node.winPulseTimer = Math.min(_ripple * 0.101, _ripple * 1.5 / nodes.active.length);
                        _Node.winTeam = winningTeam;
                        _ripple++;
                    }
                    cover.color = Globals.teamColors[winningTeam];
                    cover.color == 0 ? cover.blendMode = "normal" : cover.blendMode = "add";
                    Starling.juggler.tween(cover, 1, {"alpha": 0.4});
                    Starling.juggler.tween(cover, 1, {"alpha": 0,
                            "delay": 1});
                }
            } else if (gameOverTimer > 0) {
                gameOverTimer -= _dt;
                if (gameOverTimer <= 0)
                    winningTeam == 1 ? next() : quit();
            }
        }

        public function checkWinningTeam():void {
            var i:int = 0;
            var _Node:Node = null;
            if (Globals.level == 0) // 第一关的特殊通关条件：非障碍天体均被玩家占领
            {
                winningTeam = 1; // 玩家势力获胜
                gameOver = true; // 不判定游戏继续时，游戏结束
                for each (_Node in nodes.active)
                    if (_Node.team != 1 && _Node.type != 3)
                        gameOver = false;
                return; // 终止该函数
            }
            for (i = 0; i < Globals.teamCount; i++) // 判断场上的飞船仅剩一方势力
            {
                gameOver = true;
                for (var j:int = 0; j < Globals.teamCount; j++) {
                    if (i == j)
                        continue;
                    if (Globals.teamPops[j] > 0) // 该其他势力有飞船时
                    {
                        gameOver = false;
                        break; // 结束内循环
                    }
                }
                if (gameOver == true)
                    break;
            }
            if (gameOver == false)
                return;
            for each (_Node in nodes.active) // 判断非中立天体上都有获胜势力的飞船
            {
                if (_Node.team == 0 || _Node.team == i)
                    continue;
                if (_Node.type == 3 || _Node.type == 5)
                    continue; // 排除障碍和星核
                if (_Node.ships[i].length == 0 && i != 0) // 如果天体上没有飞船
                {
                    gameOver = false; // 游戏继续
                    return;
                }
                if (i == 0 && _Node.buildRate != 0) // 都没飞船也都产不了兵判中立赢
                {
                    gameOver = false; // 游戏继续
                    return;
                }
            }
            winningTeam = i;
        }

        public function updateBarrier():void {
            barriers.deInit();
            getBarrierLines();
            addBarriers();
            hideSingleBarriers();
        }

        public function invisibleMode():void {
            // Starling.juggler.tween(ui.entityL.labelLayer, 5, {"alpha": 0,
            //         "delay": 22});
            // Starling.juggler.tween(ui.entityL.shipsLayer1, 5, {"alpha": 0,
            //         "delay": 50});
            // Starling.juggler.tween(ui.entityL.shipsLayer2, 5, {"alpha": 0,
            //         "delay": 50});
            // Starling.juggler.tween(ui.btnL, 5, {"alpha": 0,
            //         "delay": 120});
        }

        // #endregion
        // #region 障碍
        public function addBarriers():void {
            var _x1:Number = NaN;
            var _y1:Number = NaN;
            var _x2:Number = NaN;
            var _y2:Number = NaN;
            var _dx:Number = NaN;
            var _dy:Number = NaN;
            var _Angle:Number = NaN;
            var _Distance:Number = NaN;
            var _x3:Number = NaN;
            var _y3:Number = NaN;
            var _space:Number = 8;
            var _dspace:int = 0;
            for each (var _barrierArray:Array in barrierLines) {
                _x1 = Number(_barrierArray[0].x);
                _y1 = Number(_barrierArray[0].y);
                _x2 = Number(_barrierArray[1].x);
                _y2 = Number(_barrierArray[1].y);
                _space = 8; // 贴图间距
                _dx = _x2 - _x1;
                _dy = _y2 - _y1;
                _Angle = Math.atan2(_dy, _dx);
                _Distance = Math.sqrt(_dx * _dx + _dy * _dy);
                _x3 = _x1 + Math.cos(_Angle) * _space;
                _y3 = _y1 + Math.sin(_Angle) * _space;
                _dspace = int(_space);
                while (_dspace < int(Math.floor(_Distance))) {
                    _dx = _x3 + Math.cos(_Angle) * _space * 0.5;
                    _dy = _y3 + Math.sin(_Angle) * _space * 0.5;
                    FXHandler.addBarrier(_x3, _y3, _Angle, 16729156);
                    _x3 += Math.cos(_Angle) * _space;
                    _y3 += Math.sin(_Angle) * _space;
                    _dspace += int(_space);
                }
            }
        }

        public function hideSingleBarriers():void {
            for each (var _Node:Node in nodes.active) {
                if (_Node.type != 3)
                    continue;
                _Node.image.visible = _Node.halo.visible = _Node.linked;
            }
        }

        public function getBarrierLines():void {
            var i:int = 0;
            var j:int = 0;
            var k:int = 0;
            var L_1:int = 0;
            var L_2:int = 0;
            var L_3:int = 0;
            var _Node1:Node = null;
            var _Node2:Node = null;
            var _Array:Array;
            var _Exist:Boolean;
            barrierLines.length = 0; // 清空障碍线数组
            L_1 = int(nodes.active.length);
            for (i = 0; i < L_1; i++) {
                _Node1 = nodes.active[i];
                if (_Node1.type != 3)
                    continue;
                L_2 = int(_Node1.barrierLinks.length); // 该天体需连接的障碍总数
                for (j = 0; j < L_2; j++) {
                    if (_Node1.barrierLinks[j] is Node)
                        _Node2 = _Node1.barrierLinks[j];
                    else if (_Node1.barrierLinks[j] < L_1)
                        _Node2 = nodes.active[_Node1.barrierLinks[j]];
                    if (!_Node1.barrierCostom && _Node2.barrierCostom)
                        continue;
                    _Array = [new Point(_Node1.x, _Node1.y), new Point(_Node2.x, _Node2.y)];
                    L_3 = int(barrierLines.length);
                    _Exist = false;
                    for (k = 0; k < L_3; k++)
                        if (check4same(_Array, barrierLines[k]))
                            _Exist = true;
                    if (!_Exist && _Node2.type == 3) {
                        barrierLines.push(_Array);
                        _Node1.linked = true;
                        _Node2.linked = true;
                    }
                }
            }
        }

        // #endregion

        public function on_key_down(keyCode:int):void {
            switch (keyCode) {
                case Keyboard.SPACE: // 对应Spacebar，即空格
                    Starling.current.isStarted ? pause() : Globals.main.on_resume(null);
                    break;
                case Keyboard.NUMBER_1: // 大键盘上的1
                case Keyboard.NUMBER_2:
                case Keyboard.NUMBER_3:
                case Keyboard.NUMBER_4:
                case Keyboard.NUMBER_5:
                case Keyboard.NUMBER_6:
                case Keyboard.NUMBER_7:
                case Keyboard.NUMBER_8:
                case Keyboard.NUMBER_9:
                    ui.btnL.fleetSlider.perc = (keyCode - Keyboard.NUMBER_0) / 10;
                    break;
                case Keyboard.NUMPAD_1: // 小键盘上的1
                case Keyboard.NUMPAD_2:
                case Keyboard.NUMPAD_3:
                case Keyboard.NUMPAD_4:
                case Keyboard.NUMPAD_5:
                case Keyboard.NUMPAD_6:
                case Keyboard.NUMPAD_7:
                case Keyboard.NUMPAD_8:
                case Keyboard.NUMPAD_9:
                    ui.btnL.fleetSlider.perc = (keyCode - Keyboard.NUMPAD_0) / 10;
                    break;
                case Keyboard.NUMBER_0:
                case Keyboard.NUMPAD_0:
                    ui.btnL.fleetSlider.perc = 1;
            }
        }

    }
}
