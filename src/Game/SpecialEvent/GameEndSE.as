package Game.SpecialEvent {
    import Game.GameScene;
    import Entity.Node;
    import Entity.EntityContainer;
    import starling.display.Image;
    import UI.UIContainer;
    import Entity.Node.NodeStaticLogic;
    import Entity.Ship;
    import utils.GS;
    import Entity.FXHandler;
    import starling.core.Starling;
    import utils.CalcTools;

    public class GameEndSE implements ISpecialEvent {
        private static const STATE_START:int = 0;
        private static const STATE_BREAK:int = 1;
        private static const STATE_OUT:int = 2;
        private static const STATE_END:int = 3;

        private var _game:GameScene;
        private var state:int;
        private var boss:Node;
        private var triggerTimer:Number;
        private var darkPulse:Image;

        public function GameEndSE(trigger:Object) {
            boss = EntityContainer.nodes[trigger.nodeTag];
            darkPulse = new Image(Root.assets.getTexture("halo"));
            darkPulse.pivotY = darkPulse.pivotX = darkPulse.width * 0.5;
            darkPulse.x = boss.nodeData.x;
            darkPulse.y = boss.nodeData.y;
            darkPulse.visible = false;
            UIContainer.entityLayer.addGlow(darkPulse, Globals.teamDeepColors[Globals.playerTeam]);
        }

        private var slowMult:Number = 1;
        private var soundVolume:Number = Globals.soundVolume;

        public function update(dt:Number):void {
            var i:int = 0;
            var delay:Number = 0;
            var delayStep:Number = 1;
            var rate:Number = 0.5;
            var angle:Number = Math.PI / 2;
            var angleStep:Number = Math.PI * 2 / 3;
            var maxSize:Number = 2;
            var color:uint = Globals.teamColors[Globals.playerTeam];
            if (Globals.teamColorEnhance[Globals.playerTeam])
                color = CalcTools.scaleColorToMax(color);
            var deepColor:Boolean = Globals.teamDeepColors[Globals.playerTeam];
            switch (state) {
                case STATE_START:
                    if (boss.nodeData.hp != 0)
                        break;
                    state = STATE_BREAK;
                    boss.nodeData.hp = 0.01;
                    triggerTimer = 24.34106748146577 - 2.5;
                    UIContainer.touchable = false;
                    Starling.juggler.tween(Globals,10,{"soundVolume":0});
                    // 特效
                    for (i = 0; i < 64; i++) {
                        FXHandler.addDarkPulse(boss, Globals.teamColors[Globals.playerTeam], 1, maxSize, rate, angle, deepColor, delay);
                        delay += delayStep;
                        angle += angleStep;
                        FXHandler.addDarkPulse(boss, Globals.teamColors[Globals.playerTeam], 1, maxSize, rate, angle, deepColor, delay);
                        delay += delayStep;
                        angle += angleStep;
                        FXHandler.addDarkPulse(boss, Globals.teamColors[Globals.playerTeam], 1, maxSize, rate, angle, deepColor, delay);
                        delay += delayStep;
                        angle += angleStep;
                        if (i < 20) {
                            rate *= 1.1;
                            delayStep *= 0.85;
                        }
                        maxSize *= 0.975;
                    }
                    FXHandler.addDarkPulse(boss, Globals.teamColors[Globals.playerTeam], 2, 2.5, 0.75, 0, deepColor, delay - 5.5);
                    FXHandler.addDarkPulse(boss, Globals.teamColors[Globals.playerTeam], 2, 2.5, 1, 0, deepColor, delay - 4.5);
                    if (Globals.levelReached == Globals.level)
                        Globals.levelReached = Globals.level + 1;
                    if (Globals.levelData[Globals.level] < Globals.currentDifficulty)
                        Globals.levelData[Globals.level] = Globals.currentDifficulty;
                    Globals.save();
                    GS.playMusic("bgm07", false);
                    UIContainer.invisibleMode()
                    break;
                case STATE_BREAK:
                    _game.scene.speedMult = 1; // 锁定速度
                    boss.nodeData.hp = 0.01;
                    triggerTimer -= dt;
                    if (triggerTimer > 0)
                        break;
                    state = STATE_OUT;
                    triggerTimer = 4.049999999999999 - 3.5;

                    delay = 0;
                    delayStep = 0.15;
                    rate = 2;
                    angle = Math.PI / 2;
                    maxSize = 1.75;
                    for (i = 0; i < 9; i++) {
                        FXHandler.addDarkPulse(boss, Globals.teamColors[Globals.playerTeam], 0, maxSize, rate, angle, deepColor, delay);
                        delay += delayStep;
                        angle += angleStep;
                        FXHandler.addDarkPulse(boss, Globals.teamColors[Globals.playerTeam], 0, maxSize, rate, angle, deepColor, delay);
                        delay += delayStep;
                        angle += angleStep;
                        FXHandler.addDarkPulse(boss, Globals.teamColors[Globals.playerTeam], 0, maxSize, rate, angle, deepColor, delay);
                        delay += delayStep;
                        angle += angleStep;
                        maxSize *= 1.2;
                    }
                    FXHandler.addDarkPulse(boss, Globals.teamColors[Globals.playerTeam], 3, 20, 5, 0, deepColor, delay - 3.5);
                    FXHandler.addDarkPulse(boss, Globals.teamColors[Globals.playerTeam], 3, 25, 10, 0, deepColor, delay - 3.5);
                    FXHandler.addDarkPulse(boss, Globals.teamColors[Globals.playerTeam], 3, 30, 15, 0, deepColor, delay - 3.5);
                    FXHandler.addDarkPulse(boss, Globals.teamColors[Globals.playerTeam], 3, 40, 20, 0, deepColor, delay - 4);
                    FXHandler.addDarkPulse(boss, Globals.teamColors[Globals.playerTeam], 3, 50, 25, 0, deepColor, delay - 4);
                    FXHandler.addDarkPulse(boss, Globals.teamColors[Globals.playerTeam], 3, 60, 30, 0, deepColor, delay - 4);
                    FXHandler.addDarkPulse(boss, Globals.teamColors[Globals.playerTeam], 3, 50, 20, 0, deepColor, delay - 3);
                    FXHandler.addDarkPulse(boss, Globals.teamColors[Globals.playerTeam], 3, 60, 30, 0, deepColor, delay - 2);
                    FXHandler.addDarkPulse(boss, Globals.teamColors[Globals.playerTeam], 3, 50, 6, 0, deepColor, delay - 2);
                    FXHandler.addDarkPulse(boss, Globals.teamColors[Globals.playerTeam], 3, 60, 8, 0, deepColor, delay - 2);
                    break;
                case STATE_OUT:
                    triggerTimer -= dt;
                    if (triggerTimer > 0)
                        break;

                    boss.moveState.visible = false;
                    boss.unloadShips();
                    state = STATE_END;
                    darkPulse.scaleX = darkPulse.scaleY = 0;
                    darkPulse.visible = true;
                    Starling.juggler.tween(UIContainer.btnLayer, 5, {"alpha": 0});
                    Starling.juggler.tween(UIContainer.gameContainer, 25, {"scaleX": 0.01,
                            "scaleY": 0.01,
                            "delay": 20,
                            "transition": "easeInOut"}); // 画面缩小动画
                    Starling.juggler.tween(_game, 5, {"alpha": 0,
                            "delay": 40,
                            "onComplete": _game.deInit}); // 天体消失动画
                    Starling.juggler.delayCall(function():void {
                        _game.scene.playEndScene();
                    }, 40); // 退回到主界面
                case STATE_END:
                    slowMult = Math.max(slowMult - dt * 0.75, 0.1);
                    _game.scene.speedMult = slowMult;
                    expandDarkPulse(dt);
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
            Globals.teamColorEnhance[Globals.playerTeam] ? darkPulse.color = Globals.teamColors[Globals.playerTeam] : darkPulse.color = CalcTools.scaleColorToMax(Globals.teamColors[Globals.playerTeam]);
            Globals.teamDeepColors[Globals.playerTeam] ? darkPulse.blendMode = "normal" : darkPulse.blendMode = "add";
            darkPulse.scaleY = darkPulse.scaleX += dt * 2;
            if (chackDarkPulseEnd())
                darkPulse.alpha -= dt;
            for each (node in EntityContainer.nodes) {
                if (node.nodeData.team == Globals.playerTeam || node.nodeData.isUntouchable)
                    continue;
                x = node.nodeData.x - darkPulse.x;
                y = node.nodeData.y - darkPulse.y;
                distance = Math.sqrt(x * x + y * y);
                if (distance < darkPulse.width * 0.25) {
                    NodeStaticLogic.changeTeam(node, Globals.playerTeam);
                    NodeStaticLogic.changeShipsTeam(node, Globals.playerTeam);
                    node.nodeData.hp = 100;
                }
            }
            for each (ship in EntityContainer.ships) {
                if (ship.team == Globals.playerTeam)
                    continue;
                x = ship.x - darkPulse.x;
                y = ship.y - darkPulse.y;
                distance = Math.sqrt(x * x + y * y);
                if (distance < darkPulse.width * 0.25)
                    ship.changeTeam(Globals.playerTeam);
            }
        }

        private function chackDarkPulseEnd():Boolean {
            for each (var node:Node in EntityContainer.nodes)
                if (node.nodeData.team != Globals.playerTeam && !node.nodeData.isUntouchable)
                    return false;
            return true;
        }

        public function deinit():void {
            UIContainer.entityLayer.removeGlow(darkPulse);
            UIContainer.touchable = true;
            Starling.juggler.removeTweens(Globals);
            Globals.soundVolume = soundVolume;
        }

        public function get type():String {
            return SpecialEventFactory.GAME_END;
        }

        public function set game(value:GameScene):void {
            this._game = value;
        }
    }
}
