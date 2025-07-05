package utils {

    public class Rng {
        private var _state:Vector.<uint>;
        private var _seed:uint;

        public function Rng(seed:uint = 0) {
            if (seed == 0)
                seed = uint(Math.random() * uint.MAX_VALUE)
            _seed = seed
            _state = new Vector.<uint>(4, true);
            // 初始化状态（需分散种子）
            _state[0] = seed = 1812433253 * (seed ^ (seed >> 30)) + 1;
            _state[1] = seed = 1812433253 * (seed ^ (seed >> 30)) + 2;
            _state[2] = seed = 1812433253 * (seed ^ (seed >> 30)) + 3;
            _state[3] = seed = 1812433253 * (seed ^ (seed >> 30)) + 4;
        }

        public function nextInt():uint {
            var t:uint = _state[3];
            var s:uint = _state[0];
            _state[3] = _state[2];
            _state[2] = _state[1];
            _state[1] = s;
            t ^= t << 11;
            t ^= t >> 8;
            return _state[0] = t ^ s ^ (s >> 19);
        }

        /**
         * 生成 [0, 1) 范围的浮点数
         */
        public function nextNumber():Number {
            return nextInt() / uint.MAX_VALUE;
        }

        /**
         * 生成 [min, max] 范围的整数
         */
        public function nextRange(min:int, max:int):int {
            return min + (nextInt() % (max - min + 1));
        }

        public function get seed():uint {
            return this._seed;
        }
    }
}
