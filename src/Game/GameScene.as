/*EntityPool：nodes,ais,ships,warps,beams,pules,flashs,barriers,explosions,darkpulses,fades
   实体池会记录场上的所有实体到对应的active列表中
 */
package Game {
    import flash.geom.Point;
    import starling.core.Starling;
    import starling.display.Image;
    import starling.display.Quad;
    import starling.events.EnterFrameEvent;
    import flash.ui.Keyboard;
    import utils.Rng;
    import utils.GS;
    import Entity.EntityPool;
    import Entity.EntityContainer;
    import Entity.EntityHandler;
    import Entity.Node;
    import Entity.Ship;
    import Entity.FXHandler;
    import starling.display.BlendMode;
    import UI.UIContainer;
    import starling.text.TextField;
    import starling.utils.VAlign;
    import Entity.AI.EnemyAIFactory;
    import Entity.Node.NodeStaticLogic;
    import Entity.EntityContainer;
    import Game.VictoryType.VictoryTypeFactory;
    import Game.SpecialEvent.ISpecialEvent;
    import Game.SpecialEvent.SpecialEventFactory;

    public class GameScene extends BasicScene {
        // #region 类变量
        // 其他
        public var cover:Quad; // 通关时的遮罩
        public var barrierLines:Array;
        public var level:int;
        public var gameOver:Boolean;
        public var gameOverTimer:Number;
        public var winningTeam:int;
        public var darkPulse:Image;
        public var bossTimer:Number;
        public var slowMult:Number;

        public var rng:Rng;

        public var scene:SceneController
        public var ui:UIContainer;
        public var popLabels:Vector.<TextField>;

        public var rep:Boolean = false;

        public var specialEvents:Vector.<ISpecialEvent>;

        // #endregion
        public function GameScene(_scene:SceneController) {
            super();
            this.scene = _scene;
            NodeStaticLogic.game = this;
            EntityContainer.game = this;
            FXHandler.game = this;
            EntityHandler.game = this;
            // 通关时的遮罩
            cover = new Quad(1024, 768, 16777215);
            cover.touchable = false;
            cover.blendMode = BlendMode.ADD;
            cover.alpha = 0;
            addChild(cover);
            // 其他可视化对象
            barrierLines = []; // 障碍连接数据
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
                label.alpha = 0.8;
                label.x = 512;
                label.y = 136;
                label.touchable = false;
            }
            popLabels[1].alpha = 0;
            popLabels[2].hAlign = "left";
            popLabels[2].pivotX = 0;
            popLabels[2].alpha = 0;
        }

        // #region 进入关卡
        override public function init(seed:uint = 0, rep:Boolean = false):void {
            ui = scene.ui;
            var i:int = 0;
            var aiArray:Array = [];
            this.level = Globals.level;
            this.rng = new Rng(seed);
            this.rep = rep;
            var levelData:Object = LevelData.level.data[Globals.currentData].level[Globals.level];
            aiArray = nodeIn(levelData.node as Array); // 生成天体，同时返回需生成的ai
            if (!rep)
                Globals.replay = [rng.seed, [0]];
            else {
                for (i = 0; i < aiArray.length; i++)
                    rng.nextInt();
                aiArray = [];
                Globals.replay.shift();
            }
            for (i = 0; i < aiArray.length; i++) {
                switch (Globals.currentDifficulty) {
                    case 1:
                        EntityHandler.addAI(aiArray[i], EnemyAIFactory.SIMPLE);
                        break;
                    case 2:
                        EntityHandler.addAI(aiArray[i], EnemyAIFactory.SMART);
                        break;
                    case 3:
                        EntityHandler.addAI(aiArray[i], EnemyAIFactory.HARD);
                        break;
                    default:
                        break;
                }
            }
            if (Globals.level >= 35 && !rep) { // 为36关黑色设定ai
                Globals.currentDifficulty == 3 ? EntityHandler.addAI(6, EnemyAIFactory.HARD) : EntityHandler.addAI(6, EnemyAIFactory.FINAL);
                bossTimer = 0;
            }
            for each (var label:TextField in popLabels) {
                switch (Globals.textSize) {
                    case 0:
                    case 1:
                        label.fontName = "Downlink12";
                        break;
                    case 2:
                        label.fontName = "Downlink18";
                }
                label.color = Globals.teamColors[Globals.playerTeam];
                label.fontSize = -1;
                if (label.color == 0)
                    ui.btnL.normalLayer.addChild(label);
                else
                    ui.btnL.addLayer.addChild(label);
            }
            // ui.btnL.color = Globals.teamColors[Globals.playerTeam];
            // 执行一些初始化函数
            getBarrierLines();
            addBarriers();
            if (darkPulse)
                darkPulse.visible = false;
            // 重置一些变量
            this.alpha = 0;
            this.visible = true;
            cover.alpha = 0;
            gameOver = false;
            gameOverTimer = 3;
            winningTeam = -1;

            if (levelData.bgm)
                GS.playMusic(levelData.bgm);
            else
                GS.playMusic("bgm02");
            if (levelData.victoryCondition)
                victoryType = VictoryTypeFactory.create(levelData.victoryCondition);
            else
                victoryType = VictoryTypeFactory.create(VictoryTypeFactory.NORMAL_TYPE);
            specialEvents = new Vector.<ISpecialEvent>();
            for each (var seData:Object in(levelData.specialEvents as Array)) {
                var se:ISpecialEvent = SpecialEventFactory.create(seData.type, seData.trigger);
                se.game = this;
                specialEvents.push(se);
            }

            addEventListener("enterFrame", update); // 添加帧监听器，每帧执行一次update
            animateIn(); // 播放关卡进入动画
        }

        public function nodeIn(nodes:Array):Array {
            var aiArray:Array = [];
            for each (var nodeData:Object in nodes) {
                var node:Node = EntityHandler.addNode(nodeData);
                for (var i:int = 0; i < node.nodeData.startShips.length; i++)
                    EntityHandler.addShips(node, i, node.nodeData.startShips[i]);
                if (aiArray.indexOf(nodeData.team) == -1) {
                    // 写入具有常规ai的势力，此处检验势力是否已写入，避免重复写入
                    switch (nodeData.team) {
                        case 0: // 排除中立势力
                        case Globals.playerTeam: // 排除玩家势力
                        case 5: // 排除灰色势力
                        case 6: // 排除黑色势力
                            break;
                        default:
                            aiArray.push(nodeData.team);
                            break;
                    }
                }
            }
            return aiArray;
        }

        override public function animateIn():void {
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
            for each (var pool:EntityPool in EntityContainer.entityPool)
                pool.deInit();
            for each (var se:ISpecialEvent in specialEvents)
                se.deinit();
            removeEventListener("enterFrame", update); // 移除更新帧监听器
            for each (var label:TextField in popLabels) {
                if (label.color == 0)
                    ui.btnL.normalLayer.removeChild(label);
                else
                    ui.btnL.addLayer.removeChild(label);
            }
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
        override public function animateOut():void {
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
            scene.ui.restartLevel();
            Starling.juggler.removeTweens(this);
            Starling.juggler.tween(this, Globals.transitionSpeed / 2, {"onComplete": function():void
            {
                deInit();
                init();
            }});
        }

        // #endregion
        // #region 逐帧更新
        override public function update(e:EnterFrameEvent):void {
            var dt:Number = e.passedTime;
            if (this.alpha == 0)
                return;
            GS.update(dt); // 更新音效计时器
            dt *= this.alpha; // 速度随能见度变化
            dt = updateSpeed(dt); // 更新游戏速度
            Debug.update(e);
            var arr:Array;
            if (Globals.replay.length == 0) {
                updateGame(dt);
                return;
            }
            if (!rep) {
                var l:int = Globals.replay[Globals.replay.length - 1].length;
                for (var i:int = 1; i < l; i++) {
                    arr = Globals.replay[Globals.replay.length - 1][i];
                    NodeStaticLogic.moveShips(EntityContainer.nodes[arr[0]], arr[1], EntityContainer.nodes[arr[2]], arr[3]);
                }
                Globals.replay.push([dt]);
                updateGame(dt);
            } else {
                dt = Globals.replay[0].shift();
                updateGame(dt);
                for each (arr in Globals.replay[0]) {
                    NodeStaticLogic.moveShips(EntityContainer.nodes[arr[0]], arr[1], EntityContainer.nodes[arr[2]], arr[3]);
                }
                Globals.replay.shift();
            }
        }

        public function updateGame(dt:Number):void {
            countTeamCaps(dt); // 统计兵力
            ui.update();
            for each (var pool:EntityPool in EntityContainer.entityPool) // 依次执行所有实体的更新函数
                pool.update(dt);
            winningTeam = victoryType.update(dt);
            for each (var se:ISpecialEvent in specialEvents) // 依次执行所有特殊事件的更新函数
                se.update(dt);
            updateGameOver(dt);
            updateBarrier();
        }

        public function updateSpeed(dt:Number):Number {
            if (Globals.level == 35 && gameOver) {
                // 36关通关时
                slowMult = Math.max(slowMult - dt * 0.75, 0.1);
                dt *= slowMult;
            } else
                dt *= scene.speedMult;
            return dt;
        }

        public function countTeamCaps(dt:Number):void {
            for (var team:int = 0; team < Globals.teamCount; team++) {
                // 重置兵力
                Globals.teamCaps[team] = 0;
                Globals.teamPops[team] = 0;
            }
            for each (var node:Node in EntityContainer.nodes) // 统计兵力上限
                Globals.teamCaps[node.nodeData.team] += node.nodeData.popVal * Globals.teamNodePops[node.nodeData.team];
            for each (var ship:Ship in EntityContainer.ships) // 统计总兵力
                Globals.teamPops[ship.team]++;
            EntityContainer.ships.length < 1024 ? Globals.exOptimization = 0 : (EntityContainer.ships.length < 8192 ? Globals.exOptimization = 1 : Globals.exOptimization = 2);

            popLabels[0].text = popLabels[1].text = "POPULATION : " + Globals.teamPops[Globals.playerTeam] + " / " + Globals.teamCaps[Globals.playerTeam];
            if (popLabels[1].alpha > 0)
                popLabels[1].alpha = Math.max(0, popLabels[1].alpha - dt * 0.5);
            if (popLabels[2].alpha > 0) {
                popLabels[2].x = 512 + popLabels[0].textBounds.width * 0.5 + 10;
                popLabels[2].alpha = Math.max(0, popLabels[2].alpha - dt * 0.5);
            }
        }

        // public function specialEvents():void {
        //     var i:int;
        //     var _boss:Node;
        //     var _timer:Number;
        //     var _rate:Number;
        //     var _addTime:Number;
        //     var _angle:Number;
        //     var _angleStep:Number;
        //     var _size:Number;
        //     var _bossParam:int;
        //     switch (Globals.level) // 处理特殊关卡的特殊事件
        //     {
        //         case 32, 33, 34:
        //             if (!triggers[0]) // 阶段一，生成星核
        //             {
        //                 for (i = 0; i < Globals.teamCaps.length; i++) {
        //                     if (Globals.teamCaps[i] > 220 && Globals.teamPops[i] > 220) {
        //                         _boss = EntityContainer.getReserve(EntityContainer.INDEXnODES) as Node;
        //                         if (!_boss)
        //                             _boss = new Node();
        //                         _boss.initBoss(this, new Rng(rng.nextInt(), Rng.X32), 512, 384);
        //                         EntityContainer.addEntity(EntityContainer.INDEXnODES, _boss);
        //                         _boss.bossAppear();
        //                         triggers[0] = true;
        //                         GS.fadeOutMusic(2);
        //                         GS.playSound("boss_appear");
        //                         break;
        //                     }
        //                 }
        //             }
        //             if (triggers[0] && !triggers[1]) // 阶段二，生成飞船，添加ai
        //             {
        //                 _boss = EntityContainer.nodes[EntityContainer.nodes.length - 1] as Node;
        //                 if (_boss.triggerTimer == 0) {
        //                     triggers[1] = true;
        //                     _boss.bossReady();
        //                     if (Globals.currentDifficulty != 3)
        //                         _bossParam = (Globals.level == 33) ? 320 : 350;
        //                     else
        //                         _bossParam = (Globals.level == 34) ? 400 : 350;
        //                     EntityHandler.addShips(_boss, 6, _bossParam);
        //                     var _bossAI:String = (Globals.currentDifficulty == 3) ? EnemyAIFactory.HARD : EnemyAIFactory.DARK;
        //                     EntityHandler.addAI(6, _bossAI);
        //                     _boss.triggerTimer = 3;
        //                     GS.playSound("boss_ready", 1.5);
        //                 }
        //             }
        //             if (triggers[1] && !triggers[2]) // 阶段三，星核消失动画
        //             {
        //                 _boss = EntityContainer.nodes[EntityContainer.nodes.length - 1] as Node;
        //                 if (_boss.triggerTimer == 0) {
        //                     triggers[2] = true;
        //                     _boss.bossDisappear();
        //                     GS.playSound("boss_reverse");
        //                 }
        //             }
        //             if (triggers[2] && !triggers[3]) // 阶段四，移除星核
        //             {
        //                 _boss = EntityContainer.nodes[EntityContainer.nodes.length - 1] as Node;
        //                 if (_boss.triggerTimer == 0) {
        //                     triggers[3] = true;
        //                     _boss.bossHide();
        //                     _boss.active = false;
        //                     GS.playMusic("bgm06");
        //                 }
        //             }
        //             break;
        //         case 35:
        //             if (!gameOver) {
        //                 _boss = EntityContainer.nodes[0];
        //                 if (!triggers[0] && _boss.nodeData.hp == 0) // 阶段一，坍缩动画
        //                 {
        //                     triggers[0] = true;
        //                     _timer = 0;
        //                     _rate = 0.5;
        //                     _addTime = 1;
        //                     _angle = 1.5707963267948966;
        //                     _angleStep = 2.0943951023931953;
        //                     _size = 2;
        //                     for (i = 0; i < 64; i++) {
        //                         FXHandler.addDarkPulse(_boss, Globals.teamColors[1], 1, _size, _rate, _angle, _timer);
        //                         _timer += _addTime;
        //                         _angle += _angleStep;
        //                         FXHandler.addDarkPulse(_boss, Globals.teamColors[1], 1, _size, _rate, _angle, _timer);
        //                         _timer += _addTime;
        //                         _angle += _angleStep;
        //                         FXHandler.addDarkPulse(_boss, Globals.teamColors[1], 1, _size, _rate, _angle, _timer);
        //                         _timer += _addTime;
        //                         _angle += _angleStep;
        //                         if (i < 20) {
        //                             _rate *= 1.1;
        //                             _addTime *= 0.85;
        //                         }
        //                         _size *= 0.975;
        //                     }
        //                     FXHandler.addDarkPulse(_boss, Globals.teamColors[1], 2, 2.5, 0.75, 0, _timer - 5.5);
        //                     FXHandler.addDarkPulse(_boss, Globals.teamColors[1], 2, 2.5, 1, 0, _timer - 4.5);
        //                     _boss.triggerTimer = _timer - 2.5;
        //                     if (Globals.levelReached == 35)
        //                         Globals.levelReached = 36;
        //                     if (Globals.levelData[Globals.level] < Globals.currentDifficulty)
        //                         Globals.levelData[Globals.level] = Globals.currentDifficulty;
        //                     Globals.save();
        //                     GS.playMusic("bgm07", false);
        //                     invisibleMode();
        //                 }
        //                 if (triggers[0] && !triggers[1]) // 阶段二，膨胀动画
        //                 {
        //                     _boss = EntityContainer.nodes[0];
        //                     if (_boss.triggerTimer == 0) {
        //                         triggers[1] = true;
        //                         _timer = 0;
        //                         _rate = 2;
        //                         _addTime = 0.15;
        //                         _angle = 1.5707963267948966;
        //                         _angleStep = 2.0943951023931953;
        //                         _size = 1.75;
        //                         for (i = 0; i < 9; i++) {
        //                             FXHandler.addDarkPulse(_boss, Globals.teamColors[1], 0, _size, _rate, _angle, _timer);
        //                             _timer += _addTime;
        //                             _angle += _angleStep;
        //                             FXHandler.addDarkPulse(_boss, Globals.teamColors[1], 0, _size, _rate, _angle, _timer);
        //                             _timer += _addTime;
        //                             _angle += _angleStep;
        //                             FXHandler.addDarkPulse(_boss, Globals.teamColors[1], 0, _size, _rate, _angle, _timer);
        //                             _timer += _addTime;
        //                             _angle += _angleStep;
        //                             _size *= 1.2;
        //                         }
        //                         FXHandler.addDarkPulse(_boss, Globals.teamColors[1], 3, 20, 5, 0, _timer - 3.5);
        //                         FXHandler.addDarkPulse(_boss, Globals.teamColors[1], 3, 25, 10, 0, _timer - 3.5);
        //                         FXHandler.addDarkPulse(_boss, Globals.teamColors[1], 3, 30, 15, 0, _timer - 3.5);
        //                         FXHandler.addDarkPulse(_boss, Globals.teamColors[1], 3, 40, 20, 0, _timer - 4);
        //                         FXHandler.addDarkPulse(_boss, Globals.teamColors[1], 3, 50, 25, 0, _timer - 4);
        //                         FXHandler.addDarkPulse(_boss, Globals.teamColors[1], 3, 60, 30, 0, _timer - 4);
        //                         FXHandler.addDarkPulse(_boss, Globals.teamColors[1], 3, 50, 20, 0, _timer - 3);
        //                         FXHandler.addDarkPulse(_boss, Globals.teamColors[1], 3, 60, 30, 0, _timer - 2);
        //                         FXHandler.addDarkPulse(_boss, Globals.teamColors[1], 3, 50, 6, 0, _timer - 2);
        //                         FXHandler.addDarkPulse(_boss, Globals.teamColors[1], 3, 60, 8, 0, _timer - 2);
        //                         _boss.triggerTimer = _timer - 3.5;
        //                     }
        //                 }
        //                 if (triggers[1] && !triggers[2]) // 阶段三，画面缩小，天体消失，回到主界面
        //                 {
        //                     _boss = EntityContainer.nodes[0];
        //                     if (_boss.triggerTimer == 0) {
        //                         _boss.active = false;
        //                         gameOver = true;
        //                         gameOverTimer = 1;
        //                         slowMult = 1;
        //                         triggers[2] = true;
        //                         darkPulse.team = 1;
        //                         darkPulse.scaleX = darkPulse.scaleY = 0;
        //                         darkPulse.visible = true;
        //                         Starling.juggler.tween(ui.gameContainer, 25, {"scaleX": 0.01,
        //                                 "scaleY": 0.01,
        //                                 "delay": 20,
        //                                 "transition": "easeInOut"}); // 画面缩小动画
        //                         Starling.juggler.tween(this, 5, {"alpha": 0,
        //                                 "delay": 40,
        //                                 "onComplete": hide}); // 天体消失动画
        //                         Starling.juggler.delayCall(function():void {
        //                             scene.playEndScene();
        //                         }, 40); // 退回到主界面
        //                     }
        //                 }
        //                 if (triggers[2] && gameOver) {
        //                 }
        //             }
        //             break;
        //         default:
        //             return;
        //     }
        // }

        public function expandDarkPulse(dt:Number):void {
            var team:int = darkPulse.team;
            var node:Node = null;
            var x:Number = NaN;
            var y:Number = NaN;
            var distance:Number = NaN;
            var ship:Ship = null;
            darkPulse.color = Globals.teamColors[team];
            darkPulse.color == 0 ? darkPulse.blendMode = "normal" : darkPulse.blendMode = "add";
            team == 1 ? darkPulse.scaleX += dt * 2 : darkPulse.scaleX += dt * 0.5;
            darkPulse.scaleY = darkPulse.scaleX;
            if (darkPulse.width > 3072) {
                darkPulse.visible = false;
                gameOver = true;
                winningTeam = 1;
                gameOverTimer = 0.5;
            }
            for each (node in EntityContainer.nodes) {
                if (node.nodeData.team == team || node.nodeData.isUntouchable)
                    continue;
                x = node.nodeData.x - darkPulse.x;
                y = node.nodeData.y - darkPulse.y;
                distance = Math.sqrt(x * x + y * y);
                if (distance < darkPulse.width * 0.25) {
                    NodeStaticLogic.changeTeam(node, team);
                    NodeStaticLogic.changeShipsTeam(node, team);
                    node.nodeData.hp = 100;
                }
            }
            for each (ship in EntityContainer.ships) {
                if (ship.team == team)
                    continue;
                x = ship.x - darkPulse.x;
                y = ship.y - darkPulse.y;
                distance = Math.sqrt(x * x + y * y);
                if (distance < darkPulse.width * 0.25)
                    ship.changeTeam(team);
            }
        }

        public function updateGameOver(dt:Number):void {
            if (!gameOver) // 通关判断
            {
                gameOver = (winningTeam != -1);
                if (gameOver) { // 处理游戏结束时的动画
                    var _ripple:int = 1;
                    for each (var node:Node in EntityContainer.nodes) {
                        if (node.nodeData.isUntouchable)
                            continue;
                        node.basicState.winPulseTimer = Math.min(_ripple * 0.101, _ripple * 2.5 / EntityContainer.nodes.length);
                        _ripple++;
                    }
                    cover.color = Globals.teamColors[winningTeam];
                    cover.color == 0 ? cover.blendMode = "normal" : cover.blendMode = "add";
                    Starling.juggler.tween(cover, 1, {"alpha": 0.4});
                    Starling.juggler.tween(cover, 1, {"alpha": 0,
                            "delay": 1});
                }
            } else if (gameOverTimer > 0) {
                gameOverTimer -= dt;
                if (gameOverTimer <= 0)
                    winningTeam == Globals.playerTeam ? next() : quit();
            }
        }

        public function updateBarrier():void {
            EntityContainer.entityPool[EntityContainer.INDEX_BARRIERS].deInit();
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
            var x1:Number = NaN;
            var y1:Number = NaN;
            var x2:Number = NaN;
            var y2:Number = NaN;
            var dx:Number = NaN;
            var dy:Number = NaN;
            var angle:Number = NaN;
            var distance:Number = NaN;
            var x3:Number = NaN;
            var y3:Number = NaN;
            var space:Number = 8;
            var dspace:int = 0;
            for each (var _barrierArray:Array in barrierLines) {
                x1 = Number(_barrierArray[0].x);
                y1 = Number(_barrierArray[0].y);
                x2 = Number(_barrierArray[1].x);
                y2 = Number(_barrierArray[1].y);
                space = 8; // 贴图间距
                dx = x2 - x1;
                dy = y2 - y1;
                angle = Math.atan2(dy, dx);
                distance = Math.sqrt(dx * dx + dy * dy);
                x3 = x1 + Math.cos(angle) * space;
                y3 = y1 + Math.sin(angle) * space;
                dspace = int(space);
                while (dspace < int(Math.floor(distance))) {
                    dx = x3 + Math.cos(angle) * space * 0.5;
                    dy = y3 + Math.sin(angle) * space * 0.5;
                    FXHandler.addBarrier(x3, y3, angle, 16729156);
                    x3 += Math.cos(angle) * space;
                    y3 += Math.sin(angle) * space;
                    dspace += int(space);
                }
            }
        }

        public function hideSingleBarriers():void {
            for each (var node:Node in EntityContainer.nodes) {
                if (!node.nodeData.isBarrier)
                    continue;
                node.moveState.image.visible = node.moveState.halo.visible = node.linked;
            }
        }

        public function getBarrierLines():void {
            var i:int = 0;
            var j:int = 0;
            var k:int = 0;
            var L_1:int = 0;
            var L_2:int = 0;
            var L_3:int = 0;
            var node1:Node = null;
            var node2:Node = null;
            var array:Array;
            var exist:Boolean;
            barrierLines.length = 0; // 清空障碍线数组
            L_1 = int(EntityContainer.nodes.length);
            for (i = 0; i < L_1; i++) {
                node1 = EntityContainer.nodes[i];
                if (!node1.nodeData.isBarrier)
                    continue;
                L_2 = int(node1.nodeData.barrierLinks.length); // 该天体需连接的障碍总数
                for (j = 0; j < L_2; j++) {
                    if (node1.nodeData.barrierLinks[j] < L_1)
                        node2 = EntityContainer.nodes[node1.nodeData.barrierLinks[j]];
                    array = [new Point(node1.nodeData.x, node1.nodeData.y), new Point(node2.nodeData.x, node2.nodeData.y)];
                    L_3 = int(barrierLines.length);
                    exist = false;
                    for (k = 0; k < L_3; k++)
                        if (check4same(array, barrierLines[k]))
                            exist = true;
                    if (!exist && node2.nodeData.isBarrier) {
                        barrierLines.push(array);
                        node1.linked = true;
                        node2.linked = true;
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
