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
    import utils.CalcTools;
    import UI.LayerFactory;

    public class WhiteholeFallsSE implements ISpecialEvent {
        private static const STATE_START:int = 0;
        private static const STATE_BOSSIN:int = 1;
        private static const STATE_BOSSOUT:int = 2;
        private static const STATE_END:int = 3;

        private var _game:GameScene;
        private var state:int;
        private var triggerNode:Node;
        private var triggerTimer:Number;
        private var whiteHole:Image;
        private var targetTeam:int;
        private var AI:Object = {
            type:EnemyAIFactory.WHITEHOLE,
            actionDelay:0.25
        }

        public function WhiteholeFallsSE(trigger:Object) {
            state = 0;
            triggerNode = EntityContainer.nodes[trigger.nodeTag];
            targetTeam = trigger.targetTeam;
            AI.team = trigger.targetTeam;
            whiteHole = new Image(Root.assets.getTexture("spot_glow"));
            whiteHole.pivotY = whiteHole.pivotX = whiteHole.width * 0.5;
            whiteHole.x = triggerNode.nodeData.x;
            whiteHole.y = triggerNode.nodeData.y;
            whiteHole.visible = false;
            LayerFactory.call(LayerFactory.ADD_GROW)(whiteHole, Globals.teamDeepColors[targetTeam]);
        }
        public function update(dt:Number):void {
            var delay:Number = 0;
            var delayStep:Number = 1;
            var rate:Number = 0.5;
            var angle:Number = Math.PI / 2;
            var angleStep:Number = Math.PI * 2 / 3;
            var maxSize:Number = 1;
            var color:uint = Globals.teamColors[targetTeam];
            if (Globals.teamColorEnhance[targetTeam])
                color = CalcTools.scaleColorToMax(color);
            var deepColor:Boolean = Globals.teamDeepColors[targetTeam];
            switch (state) {
                case STATE_START:
                    if (triggerNode.nodeData.hp != 100)
                        break;
                    state = STATE_BOSSIN;
                    triggerNode.nodeData.hp = 99.99; // 天体满占领度但不占领特效
                    triggerTimer = 24.34106748146577 - 3; // 24.34106748146577为动画的总时间
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
                    // FXHandler.addDarkPulse(triggerNode, color, 2, 2.5, 0.75, 0, deepColor, delay - 5.5);
                    // FXHandler.addDarkPulse(triggerNode, color, 2, 2.5, 1, 0, deepColor, delay - 4.5);
                    FXHandler.addDarkPulse(triggerNode, color, 9, 15, 10.5, 0, deepColor, delay - 3.5);
                    FXHandler.addDarkPulse(triggerNode, color, 9, 15, 10, 0, deepColor, delay - 4.0);
                    FXHandler.addDarkPulse(triggerNode, color, 9, 15, 9.5, 0, deepColor, delay - 4.5);
                    FXHandler.addDarkPulse(triggerNode, color, 9, 15, 9, 0, deepColor, delay - 5.0);
                    FXHandler.addDarkPulse(triggerNode, color, 9, 15, 8.5, 0, deepColor, delay - 5.5);
                    FXHandler.addDarkPulse(triggerNode, color, 9, 15, 8, 0, deepColor, delay - 6.0);
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
                    EntityHandler.addAI(AI);
                    whiteHole.scaleX = whiteHole.scaleY = 0;
                    whiteHole.visible = true;
                    whiteHole.alpha = 1;

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
                    FXHandler.addDarkPulse(triggerNode, color, 10, 25, 15, 0, deepColor, delay);
                    triggerNode.aiTimers[6] = 0.5;
                    break;

                case STATE_BOSSOUT:
                    expandWhiteHole(dt);
                    if (whiteHole.alpha > 0.5)
                        break;
                    state = STATE_END;
                    break;
                case STATE_END:
                    if(checkWhiteHoleEnd() && whiteHole.alpha <= 0.01)
                        _game.gameOverTimer = 0.5;
                        _game.winningGroup = Globals.playerTeam;
                        _game.gameOver = true;
                    expandWhiteHole(dt);
                    break;
                default:
                    break;
            }
        }

        public function expandWhiteHole(dt:Number):void {
            var node:Node = null;
            var x:Number = NaN;
            var y:Number = NaN;
            var distance:Number = NaN;
            var ship:Ship = null;
            whiteHole.color = Globals.teamColorEnhance[targetTeam] ? CalcTools.scaleColorToMax(Globals.teamColors[targetTeam]) : Globals.teamColors[targetTeam];
            Globals.teamDeepColors[targetTeam] ? whiteHole.blendMode = "normal" : whiteHole.blendMode = "add";
            if (!checkWhiteHoleEnd())
                whiteHole.scaleY = whiteHole.scaleX += dt;
            else {
                whiteHole.scaleY = whiteHole.scaleX -= dt * 3;
                whiteHole.alpha -= dt / 10;
            }
            if(triggerNode.buildState.buildRate < 80)
                triggerNode.buildState.buildRate = 80;
            else
                triggerNode.buildState.buildRate += dt * 64;
        }

        private function checkWhiteHoleEnd():Boolean {
            for each (var node:Node in EntityContainer.nodes)
                if (node.nodeData.team != targetTeam && !node.nodeData.isUntouchable)
                    return false;
            return true;
        }

        public function deinit():void {
            LayerFactory.call(LayerFactory.REMOVE_GROW)(whiteHole);
            Starling.juggler.removeTweens(Globals);
        }

        public function get type():String {
            return SpecialEventFactory.WHITEHOLE_FALLS;
        }

        public function set game(value:GameScene):void {
            _game = value;
        }
    }
}
