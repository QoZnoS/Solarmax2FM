package Entity.Node.Attack {
    import starling.animation.Transitions;
    import Entity.Node.Attack.BasicAttack;
    import Entity.Node;
    import Entity.EntityContainer;
    import Entity.Ship;
    import Entity.EntityHandler;
    import Entity.FXHandler;
    import Entity.EntityContainer;
    import utils.CalcTools;
    import Entity.FX.OneFrameFX;

    public class BlackholeAttack extends BasicAttack {

        public function BlackholeAttack(attackRate:Number, attackRange:Number, attackLast:Number) {
            super(attackRate, attackRange, attackLast)
        }

        private var blackhole_angle:Number = 0;

        override public function executeAttack(node:Node, dt:Number):void {
            updateTimer(dt)
            updateFX(node, dt);
            if (!attacking)
                return;
            var ships:Vector.<Ship> = EntityContainer.findShipsInRange(node);
            for each (var ship:Ship in ships)
                EntityHandler.destroyShip(ship);
        }

        override public function updateTimer(dt:Number):Boolean {
            attackTimer = Math.max(0, attackTimer - dt);
            if (attackTimer == 0) {
                attackTimer = !attacking ? attackLast : attackRate;
                attacking = !attacking;
                return true;
            } else
                return false;
        }

        private function updateFX(node:Node, dt:Number):void {
            var x:Number = node.nodeData.x;
            var y:Number = node.nodeData.y;
            blackhole_angle += dt * Math.PI * 0.5;
            if (blackhole_angle > Math.PI * 2)
                blackhole_angle -= Math.PI * 2;
            var color:uint = Globals.teamColors[node.nodeData.team];
            if (Globals.teamColorEnhance[node.nodeData.team])
                color = CalcTools.scaleColorToMax(color);
            var deepColor:Boolean = Globals.teamDeepColors[node.nodeData.team];
            if (attacking) {
                if (attackTimer > attackLast - 0.2)
                    FXHandler.addDarkPulse(node, color, 4, 2.5, Transitions.getTransition("easeIn")(attackLast + 0.8 - attackTimer), blackhole_angle, deepColor);
                else if (attackTimer < 0.6) {
                    FXHandler.addDarkPulse(node, color, 4, 2.5, Transitions.getTransition("easeOut")(0.4 + attackTimer), blackhole_angle, deepColor);
                    FXHandler.addOneFrame(OneFrameFX.BLACKHOLE_PULSE, x, y, 1, color, Transitions.getTransition("easeIn")(0.6 - attackTimer), blackhole_angle, deepColor);
                } else
                    FXHandler.addDarkPulse(node, color, 4, 2.5, 1, blackhole_angle, deepColor);
                if (attackTimer < 1) {
                    FXHandler.addOneFrame(OneFrameFX.SKILL_GLOW, x, y, Transitions.getTransition("easeOutBounce")(attackTimer) * 2, 0xFFFFFF, 1, 0, deepColor);
                    FXHandler.addOneFrame(OneFrameFX.SKILL_LIGHT, x, y, 1 + Transitions.getTransition("easeOutBounce")(attackTimer) * 0.5, 0xFFFFFF, 1, 0, deepColor);
                } else {
                    FXHandler.addOneFrame(OneFrameFX.SKILL_GLOW, x, y, 2, 0xFFFFFF, 1, 0, deepColor);
                    FXHandler.addOneFrame(OneFrameFX.SKILL_LIGHT, x, y, 1.5, 0xFFFFFF, 1, 0, deepColor);
                }
            } else {
                if (attackTimer < 0.8) {
                    FXHandler.addDarkPulse(node, color, 4, 2.5, Transitions.getTransition("easeIn")(0.8 - attackTimer), blackhole_angle, deepColor);
                } else if (attackTimer > attackRate - 0.4) {
                    FXHandler.addDarkPulse(node, color, 4, 2.5, Transitions.getTransition("easeOut")(0.4 + attackTimer - attackRate), blackhole_angle, deepColor);
                    FXHandler.addOneFrame(OneFrameFX.BLACKHOLE_PULSE, x, y, attackTimer / attackRate, color, Transitions.getTransition("easeIn")(0.6 - attackTimer + attackRate), blackhole_angle, deepColor);
                } else
                    FXHandler.addOneFrame(OneFrameFX.BLACKHOLE_PULSE, x, y, attackTimer / attackRate, color, 1, blackhole_angle, deepColor);
                if (attackTimer < 1) {
                    FXHandler.addOneFrame(OneFrameFX.SKILL_GLOW, x, y, Transitions.getTransition("easeOutBounce")(1 - attackTimer) * 2, 0xFFFFFF, 1, 0, deepColor);
                    FXHandler.addOneFrame(OneFrameFX.SKILL_LIGHT, x, y, 1 + Transitions.getTransition("easeOutBounce")(1 - attackTimer) * 0.5, 0xFFFFFF, 1, 0, deepColor);
                } else
                    FXHandler.addOneFrame(OneFrameFX.SKILL_LIGHT, x, y, 1, 0xFFFFFF, 1, 0, deepColor);
            }
        }

        override public function get attackType():String {
            return "blackhole";
        }
        // #endregion
    }
}
