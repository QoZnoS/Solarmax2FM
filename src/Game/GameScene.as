/*EntityPool：nodes,ais,ships,warps,beams,pules,flashs,barriers,explosions,darkpulses,fades
   实体池会记录场上的所有实体到对应的active列表中
 */
package Game {
    import starling.core.Starling;
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
    import starling.text.TextField;
    import starling.utils.VAlign;
    import Entity.Node.NodeStaticLogic;
    import Entity.EntityContainer;
    import Game.VictoryType.VictoryTypeFactory;
    import Game.SpecialEvent.ISpecialEvent;
    import Game.SpecialEvent.SpecialEventFactory;
    import utils.ReplayData;
    import UI.UIContainer;
    import flash.geom.Utils3D;
    import utils.CalcTools;

    public class GameScene extends BasicScene {
        // #region 类变量
        // 其他
        public var cover:Quad; // 通关时的遮罩
        public var gameOver:Boolean;
        public var gameOverTimer:Number;
        public var winningGroup:int;

        public var popLabels:Vector.<TextField>;

        public var specialEvents:Vector.<ISpecialEvent>;

        // #endregion
        public function GameScene(scene:SceneController) {
            super(scene);
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
            this.alpha = 0;
            this.visible = false;
            gameOver = true;
            popLabels = new Vector.<TextField>(3, true);
            var color:Number = 16755370;
            popLabels[0] = new TextField(600, 40, "POPULATION : 50 / 50", "Downlink12", -1, color);
            popLabels[1] = new TextField(600, 40, "POPULATION : 50 / 50", "Downlink12", -1, color);
            popLabels[2] = new TextField(200, 40, "+ 30", "Downlink12", -1, color);
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
        public function init(seed:uint = 0):void {
            this.alpha = 0;
            this.visible = true;
            ui = scene.ui;
            UIContainer.btnLayer.addChildAt(cover, 0);
            var i:int = 0;
            rng = new Rng(seed);
            var levelData:Object = LevelData.level[Globals.level];
            var aiData:Array = levelData.ai;
            if (!("ai" in levelData))
                aiData = [];
            nodeIn(levelData.node);
            Globals.replay = new ReplayData(LevelData.rawData[Globals.currentData].name, LevelData.level[Globals.level].name, rng.seed);
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
                if (Globals.teamDeepColors[Globals.playerTeam])
                    UIContainer.btnLayer.normalLayer.addChild(label);
                else
                    UIContainer.btnLayer.addLayer.addChild(label);
            }
            // UIContainer.btnLayer.color = Globals.teamColors[Globals.playerTeam];
            // 执行一些初始化函数
            initBarrierLines();
            cover.alpha = 0;
            gameOver = false;
            gameOverTimer = 3;
            winningGroup = -1;
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
            for each (var nodeData:Object in nodes) {
                var node:Node = EntityHandler.addNode(nodeData);
                for (var i:int = 0; i < node.nodeData.startShips.length; i++)
                    EntityHandler.addShips(node, i, node.nodeData.startShips[i]);
            }
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
                if (Globals.teamDeepColors[Globals.playerTeam])
                    UIContainer.btnLayer.normalLayer.removeChild(label);
                else
                    UIContainer.btnLayer.addLayer.removeChild(label);
            }
            Globals.auto_save_replay();
            this.visible = false;
        }

        public function quit():void {
            animateOut();
            scene.exit2TitleMenu(0);
            Starling.juggler.tween(this, Globals.transitionSpeed, {onComplete: deInit});
        }

        public function next():void {
            animateOut();
            Starling.juggler.tween(this, Globals.transitionSpeed, {onComplete: deInit});
            if (!Globals.levelData[Globals.level])
                Globals.levelData.push(0);
            if (Globals.levelData[Globals.level] < Globals.difficultyInt)
                Globals.levelData[Globals.level] = Globals.difficultyInt;
            if (Globals.levelReached < Globals.level + 1) {
                Globals.levelReached = Globals.level + 1;
                Globals.save();
                scene.exit2TitleMenu(1);
            } else{
                Globals.save();
                scene.exit2TitleMenu(0);
            }
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
            Globals.replay.addAction(dt);
            updateGame(dt);
        }

        public function updateGame(dt:Number):void {
            countTeamCaps(dt); // 统计兵力
            ui.update();
            for each (var pool:EntityPool in EntityContainer.entityPool) // 依次执行所有实体的更新函数
                pool.update(dt);
            winningGroup = victoryType.update(dt);
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
                gameOver = (winningGroup != -1);
                if (gameOver) { // 处理游戏结束时的动画
                    var ripple:int = 1;
                    for each (var node:Node in EntityContainer.nodes) {
                        if (node.nodeData.isUntouchable)
                            continue;
                        node.basicState.winPulseTimer = Math.min(ripple * 0.101, ripple * 2.5 / EntityContainer.nodes.length);
                        ripple++;
                    }
                    var winningColors:Array = new Array();
                    var colorShips:Array = new Array();
                    for (var teamId:int = 0; teamId < Globals.teamCount; teamId++){
                        var group:int = Globals.teamGroups[teamId];
                        if (group == winningGroup){
                            winningColors.push(Globals.teamColors[teamId]);
                            colorShips.push(Globals.teamPops[teamId]);
                        }
                    }
                    var color:uint = CalcTools.calculateWeightedColorAverage(winningColors, colorShips);
                    cover.color = color;
                    cover.color == 0 ? cover.blendMode = "normal" : cover.blendMode = "add";
                    Starling.juggler.tween(cover, 1, {"alpha": 0.4});
                    Starling.juggler.tween(cover, 1, {"alpha": 0,
                            "delay": 1});
                }
            } else if (gameOverTimer > 0) {
                gameOverTimer -= dt;
                if (gameOverTimer <= 0)
                    winningGroup == Globals.teamGroups[Globals.playerTeam] ? next() : quit();
            }
        }

        // #endregion
        public function on_key_down(keyCode:int):void {
            switch (keyCode) {
                case Keyboard.SPACE:
                    Starling.current.isStarted ? pause() : Globals.main.on_resume(null);
                    break;
                case Keyboard.NUMBER_1:
                case Keyboard.NUMBER_2:
                case Keyboard.NUMBER_3:
                case Keyboard.NUMBER_4:
                case Keyboard.NUMBER_5:
                case Keyboard.NUMBER_6:
                case Keyboard.NUMBER_7:
                case Keyboard.NUMBER_8:
                case Keyboard.NUMBER_9:
                    UIContainer.btnLayer.fleetSlider.perc = (keyCode - Keyboard.NUMBER_0) / 10;
                    break;
                case Keyboard.NUMPAD_1:
                case Keyboard.NUMPAD_2:
                case Keyboard.NUMPAD_3:
                case Keyboard.NUMPAD_4:
                case Keyboard.NUMPAD_5:
                case Keyboard.NUMPAD_6:
                case Keyboard.NUMPAD_7:
                case Keyboard.NUMPAD_8:
                case Keyboard.NUMPAD_9:
                    UIContainer.btnLayer.fleetSlider.perc = (keyCode - Keyboard.NUMPAD_0) / 10;
                    break;
                case Keyboard.NUMBER_0:
                case Keyboard.NUMPAD_0:
                    UIContainer.btnLayer.fleetSlider.perc = 1;
            }
        }
    }
}
