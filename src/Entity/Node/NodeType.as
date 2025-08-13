package Entity.Node {
    public class NodeType {
        public static const PLANET:String = "planet";
        public static const WARP:String = "warp";
        public static const HABITAT:String = "habitat";
        public static const BARRIER:String = "barrier";
        public static const TOWER:String = "tower";
        public static const DILATOR:String = "dilator";
        public static const STARBASE:String = "starbase";
        public static const PULSECANNON:String = "pulsecannon";
        public static const BLACKHOLE:String = "blackhole";
        public static const CLONETURRET:String = "cloneturret";
        public static const CAPTURESHIP:String = "captureship";
        /**仅用于兼容部分原版函数
         * @param type 
         * @return 
         */
        public static function switchType(type:int):String {
            switch (type) {
                case 0:
                    return PLANET;
                case 1:
                    return WARP;
                case 2:
                    return HABITAT;
                case 3:
                    return BARRIER;
                case 4:
                    return TOWER;
                case 5:
                    return DILATOR;
                case 6:
                    return STARBASE;
                case 7:
                    return PULSECANNON;
                case 8:
                    return BLACKHOLE;
                case 9:
                    return CLONETURRET;
                case 10:
                    return CAPTURESHIP;
                default:
                    throw new Error("Node type not register");
            }
        }
    }
}
