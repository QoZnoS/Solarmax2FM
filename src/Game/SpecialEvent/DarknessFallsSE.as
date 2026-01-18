package Game.SpecialEvent {
    import Game.GameScene;
    import Entity.Node;
    import Entity.EntityContainer;
    import Entity.FXHandler;
    import utils.GS;
    import Entity.Node.NodeStaticLogic;
    import Entity.EntityHandler;
    import Entity.AI.EnemyAIFactory;
    import starling.display.Image;
    import UI.UIContainer;
    import Entity.Ship;
    import starling.core.Starling;

    public class DarknessFallsSE implements ISpecialEvent {
        private static const STATE_START:int = 0;
        private static const STATE_BOSSIN:int = 1;
        private static const STATE_BOSSOUT:int = 2;
        private static const STATE_END:int = 3;

        private var _game:GameScene;
        private var state:int;
        private var triggerNode:Node;
        private var triggerTimer:Number;
        private var darkPulse:Image;
        private var targetTeam:int;
        private var darkAI:Object = {
            type:EnemyAIFactory.DARK,
            actionDelay:0.25
        }

        public function DarknessFallsSE(trigger:Object) {
            state = 0;
            triggerNode = EntityContainer.nodes[trigger.nodeTag];
            targetTeam = trigger.targetTeam;
            darkAI.team = trigger.targetTeam;
            darkPulse = new Image(Root.assets.getTexture("halo"));
            darkPulse.pivotY = darkPulse.pivotX = darkPulse.width * 0.5;
            darkPulse.x = triggerNode.nodeData.x;
            darkPulse.y = triggerNode.nodeData.y;
            darkPulse.visible = false;
            UIContainer.entityLayer.addGlow(darkPulse, Globals.teamDeepColors[targetTeam]);
        }
        private var soundVolume:Number = Globals.soundVolume;
        public function update(dt:Number):void {
            var delay:Number = 0;
            var delayStep:Number = 1;
            var rate:Number = 0.5;
            var angle:Number = Math.PI / 2;
            var angleStep:Number = Math.PI * 2 / 3;
            var maxSize:Number = 1;
            var color:uint = Globals.teamColors[targetTeam];
            var deepColor:Boolean = Globals.teamDeepColors[targetTeam];
            switch (state) {
                case STATE_START:
                    if (triggerNode.nodeData.hp != 100)
                        break;
                    state = STATE_BOSSIN;
                    triggerNode.nodeData.hp = 99.99; // 天体满占领度但不占领特效
                    triggerTimer = 24.34106748146577 - 3; // 24.34106748146577为动画的总时间
                    Starling.juggler.tween(Globals,5,{"soundVolume":0});
                    // 播放动画
                    delay = 0;
                    delayStep = 1;
                    rate = 0.5;
                    angle = Math.PI / 2;
                    angleStep = Math.PI * 2 / 3;
                    maxSize = 2;
                    for (var i:int = 0; i < 64; i++) {
                        FXHandler.addDarkPulse(triggerNode, color, 1, maxSize, rate, angle, deepColor, delay);
                        delay += delayStep;
                        angle += angleStep;
                        FXHandler.addDarkPulse(triggerNode, color, 1, maxSize, rate, angle, deepColor, delay);
                        delay += delayStep;
                        angle += angleStep;
                        FXHandler.addDarkPulse(triggerNode, color, 1, maxSize, rate, angle, deepColor, delay);
                        delay += delayStep;
                        angle += angleStep;
                        if (i < 20) {
                            rate *= 1.1;
                            delayStep *= 0.85;
                        }
                        maxSize *= 0.975;
                    }
                    FXHandler.addDarkPulse(triggerNode, color, 2, 2.5, 0.75, 0, deepColor, delay - 5.5);
                    FXHandler.addDarkPulse(triggerNode, color, 2, 2.5, 1, 0, deepColor, delay - 4.5);
                    GS.playMusic("bgm_dark", false);
                    break;

                case STATE_BOSSIN:
                    triggerNode.nodeData.hp = 99.99; // 天体满占领度但不占领特效
                    _game.scene.speedMult = 1; // 锁定速度
                    triggerTimer -= dt;
                    if (triggerTimer > 0)
                        break;
                    state = STATE_BOSSOUT;
                    // 黑色出场
                    NodeStaticLogic.changeTeam(triggerNode, 6);
                    NodeStaticLogic.changeShipsTeam(triggerNode, 6);
                    EntityHandler.addAI(darkAI);
                    darkPulse.scaleX = darkPulse.scaleY = 0;
                    darkPulse.visible = true;
                    darkPulse.alpha = 1;

                    // 特效
                    delay = 0;
                    delayStep = 0.05;
                    angle = Math.PI / 2;
                    maxSize = 1;
                    for (i = 0; i < 3; i++) {
                        FXHandler.addDarkPulse(triggerNode, color, 0, maxSize, 2, angle, deepColor, delay);
                        delay += delayStep;
                        angle += Math.PI * 2 / 3;
                        FXHandler.addDarkPulse(triggerNode, color, 0, maxSize, 2, angle, deepColor, delay);
                        delay += delayStep;
                        angle += Math.PI * 2 / 3;
                        FXHandler.addDarkPulse(triggerNode, color, 0, maxSize, 2, angle, deepColor, delay);
                        delay += delayStep;
                        angle += Math.PI * 2 / 3;
                        maxSize *= 1.5;
                    }
                    triggerNode.aiTimers[6] = 0.5;
                    break;

                case STATE_BOSSOUT:
                    expandDarkPulse(dt);
                    if (darkPulse.alpha > 0.5)
                        break;
                    state = STATE_END;
                    _game.gameOverTimer = 0.5;
                    break;
                case STATE_END:
                    _game.gameOver = true;
                    _game.winningGroup = Globals.playerTeam;
                    expandDarkPulse(dt);
                    break;
                default:
                    break;
            }
        }

        public function expandDarkPulse(dt:Number):void {
            var node:Node = null;
            var x:Number = NaN;
            var y:Number = NaN;
            var distance:Number = NaN;
            var ship:Ship = null;
            darkPulse.color = Globals.teamColors[targetTeam];
            Globals.teamDeepColors[targetTeam] ? darkPulse.blendMode = "normal" : darkPulse.blendMode = "add";
            darkPulse.scaleY = darkPulse.scaleX += dt * 0.5;
            if (chackDarkPulseEnd())
                darkPulse.alpha -= dt / 10;
            for each (node in EntityContainer.nodes) {
                if (node.nodeData.team == targetTeam || node.nodeData.isUntouchable)
                    continue;
                x = node.nodeData.x - darkPulse.x;
                y = node.nodeData.y - darkPulse.y;
                distance = Math.sqrt(x * x + y * y);
                if (distance < darkPulse.width * 0.25) {
                    NodeStaticLogic.changeTeam(node, targetTeam);
                    NodeStaticLogic.changeShipsTeam(node, targetTeam);
                    node.nodeData.hp = 100;
                }
            }
            for each (ship in EntityContainer.ships) {
                if (ship.team == targetTeam)
                    continue;
                x = ship.x - darkPulse.x;
                y = ship.y - darkPulse.y;
                distance = Math.sqrt(x * x + y * y);
                if (distance < darkPulse.width * 0.25)
                    ship.changeTeam(targetTeam);
            }
        }

        private function chackDarkPulseEnd():Boolean {
            for each (var node:Node in EntityContainer.nodes)
                if (node.nodeData.team != targetTeam && !node.nodeData.isUntouchable)
                    return false;
            return true;
        }

        public function deinit():void {
            UIContainer.entityLayer.removeGlow(darkPulse);
            Starling.juggler.removeTweens(Globals);
            Globals.soundVolume = soundVolume;
        }

        public function get type():String {
            return SpecialEventFactory.DARKNESS_FALLS;
        }

        public function set game(value:GameScene):void {
            _game = value;
        }
    }
}
