package Entity.AI
{
    public class EnemyAIFactory{
        public static const BASIC:String = "BasicAI";
        public static const SIMPLE:String = "SimpleAI";
        public static const SMART:String = "SmartAI";
        public static const DARK:String = "DarkAI";
        public static const FINAL:String = "FinalAI";
        public static const HARD:String = "HardAI";

        public static function create(type:String):IEnemyAI{
            switch(type)
            {
                case SIMPLE:
                    return new SimpleAI();
                default:
                    return new BasicAI();
            }
        }
    }
}