package Game.Entity.GameEntity.Node.Attack {
    import Game.Entity.GameEntity.Node.Interface.IAttackStrategy;
    import Game.Entity.GameEntity.*;

    public class BasicAttack implements IAttackStrategy {

        private var timer:Number = 0;
        private var rate:Number = 0;
        private var range:Number = 0;
        private var last:Number = 0;
        private var attack:Boolean = false;

        public function BasicAttack(attackRate:Number, attackRange:Number, attackLast:Number) {
            rate = attackRate;
            range = attackRange;
            last = attackLast;
        }

        public function executeAttack(node:Node, dt:Number):void {
            throw new Error("Abstract method: executeAttack must be overridden in subclass");
        }

        /** 更新计时器，返回能否攻击
         * @param dt 
         * @return boolean
         */
        public function updateTimer(dt:Number):Boolean {
            timer = Math.max(0, timer - dt);
            if (timer == 0) {
                timer = rate;
                return true;
            } else
                return false;
        }

        public function get attackType():String {
            return "basic";
        }
        // #region getter/setter
        public function set attackTimer(value:Number):void {
            timer = value;
        }

        public function get attackTimer():Number {
            return timer;
        }

        public function set attackRate(value:Number):void {
            rate = value;
        }

        public function get attackRate():Number {
            return rate;
        }

        public function set attackRange(value:Number):void {
            range = value;
        }

        public function get attackRange():Number {
            return range;
        }

        public function set attackLast(value:Number):void {
            last = value;
        }

        public function get attackLast():Number {
            return last;
        }

        public function set attacking(value:Boolean):void {
            attack = value;
        }

        public function get attacking():Boolean {
            return attack;
        }
        // #endregion
    }
}
