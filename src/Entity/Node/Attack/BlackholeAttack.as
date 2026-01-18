package Entity.Node.Attack {
    import starling.animation.Transitions;
    import Entity.Node.Attack.BasicAttack;
    import Entity.Node;
    import Entity.EntityContainer;
    import Entity.Ship;
    import Entity.EntityHandler;
    import Entity.FXHandler;
    import Entity.EntityContainer;

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
            blackhole_angle += dt * Math.PI * 0.5;
            if (blackhole_angle > Math.PI * 2)
                blackhole_angle -= Math.PI * 2;
            var color:uint = Globals.teamColors[node.nodeData.team];
            var deepColor:Boolean = Globals.teamDeepColors[node.nodeData.team]
            if (attacking) {
                if (attackTimer > attackLast - 0.2)
                    FXHandler.addDarkPulse(node, color, 4, 2.5, Transitions.getTransition("easeIn")(attackLast + 0.8 - attackTimer), blackhole_angle, deepColor);
                else if (attackTimer < 0.6) {
                    FXHandler.addDarkPulse(node, color, 4, 2.5, Transitions.getTransition("easeOut")(0.4 + attackTimer), blackhole_angle, deepColor);
                    FXHandler.addDarkPulse(node, color, 5, 1, Transitions.getTransition("easeIn")(0.6 - attackTimer), blackhole_angle, deepColor);
                } else
                    FXHandler.addDarkPulse(node, color, 4, 2.5, 1, blackhole_angle, deepColor);
                if (attackTimer < 1) {
                    FXHandler.addDarkPulse(node, 0xFFFFFF, 7, Transitions.getTransition("easeOutBounce")(attackTimer) * 2, 1, 0, deepColor);
                    FXHandler.addDarkPulse(node, 0xFFFFFF, 6, 1 + Transitions.getTransition("easeOutBounce")(attackTimer) * 0.5, 1, 0, deepColor);
                } else {
                    FXHandler.addDarkPulse(node, 0xFFFFFF, 7, 2, 1, 0, deepColor);
                    FXHandler.addDarkPulse(node, 0xFFFFFF, 6, 1.5, 1, 0, deepColor);
                }
            } else {
                if (attackTimer < 0.8) {
                    FXHandler.addDarkPulse(node, color, 4, 2.5, Transitions.getTransition("easeIn")(0.8 - attackTimer), blackhole_angle, deepColor);
                } else if (attackTimer > attackRate - 0.4) {
                    FXHandler.addDarkPulse(node, color, 4, 2.5, Transitions.getTransition("easeOut")(0.4 + attackTimer - attackRate), blackhole_angle, deepColor);
                    FXHandler.addDarkPulse(node, color, 5,  attackTimer / attackRate, Transitions.getTransition("easeIn")(0.6 - attackTimer + attackRate), blackhole_angle, deepColor);
                } else
                    FXHandler.addDarkPulse(node, color, 5,  attackTimer / attackRate, 1, blackhole_angle, deepColor);
                if (attackTimer < 1) {
                    FXHandler.addDarkPulse(node, 0xFFFFFF, 7, Transitions.getTransition("easeOutBounce")(1 - attackTimer) * 2, 1, 0, deepColor);
                    FXHandler.addDarkPulse(node, 0xFFFFFF, 6, 1 + Transitions.getTransition("easeOutBounce")(attackTimer) * 0.5, 1, 0, deepColor);
                } else
                    FXHandler.addDarkPulse(node, 0xFFFFFF, 6, 1, 1, 0, deepColor);
            }
        }

        override public function get attackType():String {
            return "blackhole";
        }
        // #endregion
    }
}
