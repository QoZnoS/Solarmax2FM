package Entity.Node.Interface
{
    import Entity.Node.Attack.*;

    public class AttackStrategyFactory{
        public static function create(type:String, attackRate:Number, attackRange:Number, attackLast:Number):IAttackStrategy {
        switch(type) {
            case "tower": 
                return new TowerAttack(attackRate, attackRange, attackLast);
            case "pulsecannon": 
                return new PulsecannonAttack(attackRate, attackRange, attackLast);
            case "blackhole": 
                return new BlackholeAttack(attackRate, attackRange, attackLast);
            case "cloneturret":
                return new CloneturretAttack(attackRate, attackRange, attackLast);
            case "captureship":
                return new CaptureshipAttack(attackRate, attackRange, attackLast);
            default : 
                return new BasicAttack(attackRate, attackRange, attackLast);
        }
    }
    }
}