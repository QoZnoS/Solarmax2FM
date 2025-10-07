package Game {

    import utils.ReplayData;
    import Entity.Node;
    import Entity.EntityHandler;
    import Entity.EntityPool;
    import Entity.EntityContainer;
    import Game.SpecialEvent.ISpecialEvent;
    import starling.core.Starling;
    import utils.Rng;
    import utils.GS;
    import Game.SpecialEvent.SpecialEventFactory;
    import starling.events.EnterFrameEvent;
    import Entity.Node.NodeStaticLogic;
    import Entity.Ship;

    public class ReplayScene extends BasicScene {
        public var rep:ReplayData;
        public var repBak:ReplayData;

        public var specialEvents:Vector.<ISpecialEvent>;

        public function ReplayScene(scene:SceneController) {
            super(scene);
        }

        public function init(rep:ReplayData):void {
            this.alpha = 1;
            this.visible = true;
            EntityHandler.replay = this;
            this.rep = rep;
            this.repBak = rep.deepCopy;
            rep.startRead();
            this.ui = scene.ui;
            ui.btnL.fleetSlider.visible = false;
            var level:Object = find_level();
            var i:int = 0;
            rng = new Rng(rep.seed);
            nodeIn(level.node);
            if ("ai" in level)
                for (i = 0; i < level.ai.length; i++)
                   rng.nextInt();
            initBarrierLines();
            if (level.bgm)
                GS.playMusic(level.bgm);
            else
                GS.playMusic("bgm02");
            specialEvents = new Vector.<ISpecialEvent>();
            for each (var seData:Object in(level.specialEvents as Array)) {
                var se:ISpecialEvent = SpecialEventFactory.create(seData.type, seData.trigger);
                se.game = scene.gameScene;
                specialEvents.push(se);
            }
            addEventListener("enterFrame", update); // 添加帧监听器，每帧执行一次update
            animateIn();
        }

        private function find_level():Object {
            for each (var data:Object in LevelData.rawData)
                if (data.name == rep.level[0])
                    for each (var level:Object in data.level)
                        if (level.name == rep.level[1])
                            return level;
            throw new Error("level not found");
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
            else{
                var frameData:Array = rep.stepping();
                dt = frameData[0];
                frameData.shift();
            }
            countTeamCaps(dt); // 统计兵力
            ui.update();
            scene.gameScene.winningTeam = -1;
            EntityHandler.removeAllAI();
            for each (var pool:EntityPool in EntityContainer.entityPool) // 依次执行所有实体的更新函数
                pool.update(dt);
            for each (var se:ISpecialEvent in specialEvents) // 依次执行所有特殊事件的更新函数
                se.update(dt);
            updateBarrier();
            if (!rep.reading || frameData.length == 0)
                return
            var len:int = frameData.length / 4;
            for(var i:int = 0; i < len; i++)
                NodeStaticLogic.sendAIShips(EntityContainer.nodes[frameData[i*4]],frameData[i*4+1],EntityContainer.nodes[frameData[i*4+2]],frameData[i*4+3])
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
            Starling.juggler.tween(this, Globals.transitionSpeed, {onComplete: deInit});
        }

        public function restart():void {
            scene.ui.restartLevel();
            Starling.juggler.removeTweens(this);
            Starling.juggler.tween(this, Globals.transitionSpeed / 5, {"onComplete": function():void
            {
                deInit();
                init(repBak.deepCopy);
            }});
        }
    }
}
