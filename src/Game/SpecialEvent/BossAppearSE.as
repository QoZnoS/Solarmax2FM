package Game.SpecialEvent {
    import Game.GameScene;
    import Entity.Node;
    import Entity.EntityHandler;
    import Entity.EntityContainer;
    import Entity.FXHandler;
    import utils.GS;
    import Entity.AI.EnemyAIFactory;

    public class BossAppearSE implements ISpecialEvent {
        private static const STATE_READY_APPEAR:int = 0;
        private static const STATE_APPEAR:int = 1;
        private static const STATE_READY_DISAPPEAR:int = 2;
        private static const STATE_DISAPPEAR:int = 3;
        private static const STATE_END:int = 4;

        private var _game:GameScene;
        private var state:int;
        private var triggerShips:int;
        private var triggerNodeData:Object;
        private var triggerNode:Node;
        private var triggerTimer:Number;

        public function BossAppearSE(trigger:Object) {
            triggerShips = trigger.ships;
            triggerNodeData = trigger.node;
        }

        public function update(dt:Number):void {
            var i:int;
            var rate:Number = 1;
            var delay:Number = 0;
            var delayStep:Number = 0.5;
            var angle:Number = Math.PI / 2;
            var angleStep:Number = Math.PI * 2 / 3;
            var maxSize:Number = 2;
            var color:uint = Globals.teamColors[triggerNodeData.team];
            switch (state) {
                case STATE_READY_APPEAR:
                    if (!checkAppearCondition())
                        break;
                    state = STATE_APPEAR;
                    triggerTimer = 5.99397965233468;

                    // 生成星核
                    triggerNode = EntityHandler.addNode(triggerNodeData);
                    triggerNode.moveState.image.visible = false;
                    triggerNode.moveState.halo.visible = false;
                    triggerNode.moveState.glow.visible = false;

                    // 播放特效
                    for (i = 0; i < 24; i++) {
                        FXHandler.addDarkPulse(triggerNode, color, 1, maxSize, rate, angle, delay);
                        delay += delayStep;
                        angle += angleStep;
                        FXHandler.addDarkPulse(triggerNode, color, 1, maxSize, rate, angle, delay);
                        delay += delayStep;
                        angle += angleStep;
                        FXHandler.addDarkPulse(triggerNode, color, 1, maxSize, rate, angle, delay);
                        delay += delayStep;
                        angle += angleStep;
                        rate *= 1.15;
                        delayStep *= 0.75;
                        maxSize *= 0.9;
                    }
                    FXHandler.addDarkPulse(triggerNode, color, 2, 2, 2, 0, delay - 0.75);
                    FXHandler.addDarkPulse(triggerNode, color, 2, 2, 2, 0, delay - 0.4);
                    GS.fadeOutMusic(2);
                    GS.playSound("boss_appear");
                    break;
                case STATE_APPEAR:
                    triggerTimer -= dt;
                    if (triggerTimer > 0)
                        break;
                    state = STATE_READY_DISAPPEAR;
                    triggerTimer = 3;

                    // 生成飞船和AI
                    var bossAI:String = (Globals.difficultyInt == 3) ? EnemyAIFactory.HARD : EnemyAIFactory.DARK;
                    for (i = 0; i < triggerNode.nodeData.startShips.length; i++){
                        EntityHandler.addShips(triggerNode, i, triggerNode.nodeData.startShips[i]);
                        if (!EntityHandler.hadAI(i) && triggerNode.nodeData.startShips[i] != 0)
                            EntityHandler.addAI(i, bossAI);
                    }

                    // 播放特效
                    triggerNode.moveState.image.visible = true;
                    triggerNode.moveState.halo.visible = true;
                    triggerNode.moveState.glow.visible = true;
                    delay = 0;
                    delayStep = 0.05;
                    rate = 2;
                    angle = Math.PI / 2;
                    maxSize = 1;
                    for (i = 0; i < 3; i++) {
                        FXHandler.addDarkPulse(triggerNode, color, 1, maxSize, rate, angle, delay);
                        delay += delayStep;
                        angle += angleStep;
                        FXHandler.addDarkPulse(triggerNode, color, 1, maxSize, rate, angle, delay);
                        delay += delayStep;
                        angle += angleStep;
                        FXHandler.addDarkPulse(triggerNode, color, 1, maxSize, rate, angle, delay);
                        delay += delayStep;
                        angle += angleStep;
                        maxSize *= 1.5;
                    }
                    GS.playSound("boss_ready", 1.5);
                    break;
                case STATE_READY_DISAPPEAR:
                    triggerTimer -= dt;
                    if (triggerTimer > 0)
                        break;
                    state = STATE_DISAPPEAR;
                    triggerTimer = 2.999267578125;

                    delay = 0;
                    rate = 1;
                    delayStep = 0.5;
                    angle = Math.PI / 2;
                    maxSize = 2;
                    for (i = 0; i < 12; i++) {
                        FXHandler.addDarkPulse(triggerNode, color, 1, maxSize, rate, angle, delay);
                        delay += delayStep;
                        angle += angleStep;
                        FXHandler.addDarkPulse(triggerNode, color, 1, maxSize, rate, angle, delay);
                        delay += delayStep;
                        angle += angleStep;
                        FXHandler.addDarkPulse(triggerNode, color, 1, maxSize, rate, angle, delay);
                        delay += delayStep;
                        angle += angleStep;
                        rate *= 1.5;
                        delayStep *= 0.5;
                        maxSize *= 0.7;
                    }
                    FXHandler.addDarkPulse(triggerNode, color, 2, 2, 2, 0, delay - 0.75);
                    GS.playSound("boss_reverse");
                    break;
                case STATE_DISAPPEAR:
                    triggerTimer -= dt;
                    triggerNode.unloadShips();
                    if (triggerTimer > 0)
                        break;
                    state = STATE_END;
                    EntityHandler.removeNode(triggerNode);
                    GS.playMusic("bgm06");
                    break;
                case STATE_END:
                    break;
            }
        }

        private function checkAppearCondition():Boolean {
            for (var i:int = 0; i < Globals.teamCount; i++) {
                if (Globals.teamPops[i] > triggerShips && Globals.teamCaps[i] > triggerShips)
                    return true;
            }
            return false;
        }

        public function deinit():void {
        }

        public function get type():String {
            return SpecialEventFactory.BOSS_APPEAR;
        }

        public function set game(value:GameScene):void {
            _game = value;
        }

        public function get game():GameScene {
            return _game;
        }

    }
}
