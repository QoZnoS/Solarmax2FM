package Entity.Node.Attack {
    import Entity.Node;

    public class BasicAttack implements IAttackStrategy {

        private var _timer:Number = 0;
        private var _rate:Number = 0;
        private var _range:Number = 0;
        private var _last:Number = 0;
        private var _attack:Boolean = false;

        public function BasicAttack(attackRate:Number, attackRange:Number, attackLast:Number) {
            _rate = attackRate;
            _range = attackRange;
            _last = attackLast;
        }

        public function executeAttack(node:Node, dt:Number):void {
            throw new Error("Abstract method: executeAttack must be overridden in subclass");
        }

        /** 更新计时器，返回能否攻击
         * @param dt 
         * @return boolean
         */
        public function updateTimer(dt:Number):Boolean {
            _timer = Math.max(0, _timer - dt);
            if (_timer == 0) {
                _timer = _rate;
                return true;
            } else
                return false;
        }

        public function get attackType():String {
            return "basic";
        }
        // #region getter/setter
        public function set attackTimer(value:Number):void {
            _timer = value;
        }

        public function get attackTimer():Number {
            return _timer;
        }

        public function set attackRate(value:Number):void {
            _rate = value;
        }

        public function get attackRate():Number {
            return _rate;
        }

        public function set attackRange(value:Number):void {
            _range = value;
        }

        public function get attackRange():Number {
            return _range;
        }

        public function set attackLast(value:Number):void {
            _last = value;
        }

        public function get attackLast():Number {
            return _last;
        }

        public function set attacking(value:Boolean):void {
            _attack = value;
        }

        public function get attacking():Boolean {
            return _attack;
        }
        // #endregion
    }
}
