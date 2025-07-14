package Entity.Node.Interface {
    import Entity.Node.Attack.*;

    public class AttackStrategyFactory {
        public static const TOWER:String = "tower";
        public static const PULSECANNON:String = "pulsecannon";
        public static const BLACKHOLE:String = "blackhole";
        public static const CLONETURRENT:String = "cloneturret";
        public static const CAPTURESHIP:String = "captureship";

        public static function create(type:String, attackRate:Number, attackRange:Number, attackLast:Number):IAttackStrategy {
            switch (type) {
                case TOWER:
                    return new TowerAttack(attackRate, attackRange, attackLast);
                case PULSECANNON:
                    return new PulsecannonAttack(attackRate, attackRange, attackLast);
                case BLACKHOLE:
                    return new BlackholeAttack(attackRate, attackRange, attackLast);
                case CLONETURRENT:
                    return new CloneturretAttack(attackRate, attackRange, attackLast);
                case CAPTURESHIP:
                    return new CaptureshipAttack(attackRate, attackRange, attackLast);
                default:
                    return new BasicAttack(attackRate, attackRange, attackLast);
            }
        }
    }
}
