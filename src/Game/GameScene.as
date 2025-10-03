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
            ui.btnL.addChildAt(cover, 0);
            var i:int = 0;
            this.level = Globals.level;
            this.rng = new Rng(seed);
            this.rep = rep;
            var levelData:Object = LevelData.level[Globals.level];
            var aiData:Array = levelData.ai;
            if (!("ai" in levelData))
                aiData = [];
            nodeIn(levelData.node);
            if (!rep)
                Globals.replay = [rng.seed, [0]];
            else {
                for (i = 0; i < aiData.length; i++)
                    rng.nextInt();
                aiData = [];
                Globals.replay.shift();
            }
            for (i = 0; i < aiData.length; i++)
                EntityHandler.addAI(aiData[i]);
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

        public function nodeIn(nodes:Array):void {
            var aiArray:Array = [];
            for each (var nodeData:Object in nodes) {
                var node:Node = EntityHandler.addNode(nodeData);
                for (var i:int = 0; i < node.nodeData.startShips.length; i++)
                    EntityHandler.addShips(node, i, node.nodeData.startShips[i]);
            }
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
            ui.removeChild(cover);
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
            if (Globals.levelData[Globals.level] < Globals.difficultyInt)
                Globals.levelData[Globals.level] = Globals.difficultyInt;
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
            Starling.juggler.tween(this, Globals.transitionSpeed / 5, {"onComplete": function():void
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
            dt *= scene.speedMult;
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
                    try {
                        NodeStaticLogic.moveShips(EntityContainer.nodes[arr[0]], arr[1], EntityContainer.nodes[arr[2]], arr[3]);
                    } catch (error:Error) {
                        Globals.replay[Globals.replay.length - 1].removeAt(i);
                    }
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

        public function updateGameOver(dt:Number):void {
            if (!gameOver) { // 通关判断
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
