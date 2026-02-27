package scenes {
    import core.EntityContainer;
    import core.EntityHandler;
    import core.EntityPool;
    import core.entities.Node;
    import core.entities.Ship;
    import core.factories.SpecialEventFactory;
    import core.game.events.ISpecialEvent;
    import core.node.NodeStaticLogic;

    import managers.AudioManager;
    import managers.Globals;
    import managers.LevelData;

    import starling.core.Starling;
    import starling.events.EnterFrameEvent;

    import ui.UIContainer;

    import utils.ReplayData;
    import utils.Rng;
    import managers.SaveManager;
    import core.ParticleSystem;

    public class ReplayScene extends BasicScene {
        public var rep:ReplayData;
        public var repBak:ReplayData;

        public var specialEvents:Vector.<ISpecialEvent>;

        public function ReplayScene(scene:SceneController) {
            super(scene);
            visible = false;
            EntityHandler.replay = this;
        }

        public function init(rep:ReplayData):void {
            this.alpha = 1;
            this.visible = true;
            this.rep = rep;
            this.repBak = rep.deepCopy;
            rep.startRead();
            UIContainer.fleetSlider.visible = false;
            // 根据回放中的 mappack 名称设置 currentData
            EntityContainer.shipTagCounter = 0;
            var level:Object = find_level();
            rng = new Rng(rep.seed);
            // 势力属性
            Globals.teamGroups = Globals.defaultGroups.slice();
            for (var i:int = 0; i < Globals.teamCount; i++) {
                var teamData:Object = LevelData.rawData[SaveManager.currentData].team[i];
                if ("group" in teamData)
                    Globals.teamGroups[i] = teamData.group;
                else
                    Globals.teamGroups[i] = i;
            }
            var groupData:Array = level.group;
            if ("group" in level)
                for (var group:int = 0; group < groupData.length; group++)
                    for (i = 0; i < groupData[group].length; i++)
                        Globals.teamGroups[groupData[group][i]] = group + 1;
            // 天体
            nodeIn(level.node);
            // AI
            if ("ai" in level) {
                for (i = 0; i < level.ai.length; i++) {
                    rng.nextInt();
                    // trace("AI skepped! seed: " + rng.state.toString());
                }
            }
            // bgm
            if (level.bgm)
                AudioManager.playMusic(level.bgm);
            else
                AudioManager.playMusic("bgm02");
            // 特殊事件
            specialEvents = new Vector.<ISpecialEvent>();
            for each (var seData:Object in(level.specialEvents as Array)) {
                var se:ISpecialEvent = SpecialEventFactory.create(seData.type, seData.trigger);
                se.game = scene.gameScene;
                specialEvents.push(se);
            }
            initBarrierLines();
            addEventListener("enterFrame", update); // 添加帧监听器，每帧执行一次update
            animateIn();
        }

        private function find_level():Object {
            var foundIndex:int = -1;
            for (var i:int = 0; i < LevelData.rawData.length; i++) {
                if (LevelData.rawData[i].name == rep.level[0]) {
                    foundIndex = i;
                    break;
                }
            }
            if (foundIndex == -1)
                throw new Error("Mappack not found: " + rep.level[0]);
            SaveManager.currentData = foundIndex;
            SaveManager.currentDifficulty = rep.difficulty;
            LevelData.updateLevelData();
            var level:Object = null;
            for each (var lvl:Object in LevelData.level) {
                if (lvl.name == rep.level[1]) {
                    level = lvl;
                    break;
                }
            }
            if (!level)
                throw new Error("Level not found: " + rep.level[1]);
            return level;
        }

        private function nodeIn(nodes:Array):void {
            for each (var nodeData:Object in nodes) {
                var node:Node = EntityHandler.addNode(nodeData);
                for (var i:int = 0; i < node.nodeData.startShips.length; i++)
                    EntityHandler.addShips(node, i, node.nodeData.startShips[i]);
            }
        }

        override public function update(e:EnterFrameEvent):void {
            var dt:Number;
            if (!rep.reading)
                dt = e.passedTime;
            else {
                var frameData:Array = rep.stepping();
                dt = frameData[0];
                frameData.shift();
            }
            AudioManager.update(dt); // 更新音效计时器
            // EntityHandler.removeAllAI();
            Debug.update(dt);
            ParticleSystem.update(dt);
            countTeamCaps(dt); // 统计兵力
            UIContainer.i.update();
            scene.gameScene.winningGroup = -1;
            for each (var pool:EntityPool in EntityContainer.entityPool) // 依次执行所有实体的更新函数
                pool.update(dt);
            for each (var se:ISpecialEvent in specialEvents) // 依次执行所有特殊事件的更新函数
                se.update(dt);
            EntityHandler.removeAllAI();
            updateBarrier();
            if (!rep.reading || frameData.length == 0)
                return;
            var len:int = frameData.length / 4;
            for (var i:int = 0; i < len; i++)
                NodeStaticLogic.sendAIShips(EntityContainer.nodes[frameData[i * 4]], frameData[i * 4 + 1], EntityContainer.nodes[frameData[i * 4 + 2]], frameData[i * 4 + 3]);
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
        }

        public function deInit():void {
            for each (var pool:EntityPool in EntityContainer.entityPool)
                pool.deInit();
            for each (var se:ISpecialEvent in specialEvents)
                se.deinit();
            removeEventListener("enterFrame", update); // 移除更新帧监听器
            visible = false;
        }

        public function quit():void {
            animateOut();
            scene.exit2TitleMenu(0);
            Starling.juggler.tween(this, SaveManager.transitionSpeed, {onComplete: deInit});
        }

        public function restart():void {
            UIContainer.i.restartLevel();
            Starling.juggler.removeTweens(this);
            Starling.juggler.tween(this, SaveManager.transitionSpeed / 5, {"onComplete": function():void
            {
                deInit();
                init(repBak.deepCopy);
            }});
        }
    }
}
