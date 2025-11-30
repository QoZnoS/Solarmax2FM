package utils {

    public class Rng {
        private var _state:Vector.<uint>;
        private var _seed:uint;
        private var _generator:Generator;

        // RNG类型，数字越大随机效果越好
        public static const X128:String = "Xorshift128";
        public static const X32:String = "Xorshift32";
        public static const X0:String = "LCG";

        public function Rng(seed:uint = 0, type:String = X128) {
            if (seed == 0)
                seed = uint(Math.random() * uint.MAX_VALUE)
            _seed = seed
            switch (type) {
                case X128:
                    _generator = new Xorshift128(seed)
                    break;
                case X32:
                    _generator = new Xorshift32(seed)
                    break;
                case X0:
                    _generator = new LCG(seed)
                    break;
                default:
                    break;
            }
        }

        /**
         * 步进生成uint
         */
        public function nextInt():uint {
            return _generator.nextInt()
        }

        /**
         * 生成 [0, 1) 范围的浮点数
         */
        public function nextNumber():Number {
            return _generator.nextNumber()
        }

        /**
         * 生成 [min, max] 范围的整数
         */
        public function nextRange(min:int, max:int):int {
            return _generator.nextRange(min, max)
        }

        /**
         * 返回数组中的一个随机项
         */
        public function randomIndex(arr:Object):* {
            try {
                var len:int = arr.length;
                if (len == 0)
                    return null;
                return arr[nextRange(0, len - 1)];
            } catch (error:Error) {
                throw error;
            }
        }

        public function get seed():uint {
            return this._seed;
        }
    }
}

internal class Xorshift128 implements Generator {
    private var _seed:uint;
    private var _state:Vector.<uint>;

    public function Xorshift128(seed:uint = 0) {
        _seed = seed
        _state = new Vector.<uint>(4, true);
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

    public function nextNumber():Number {
        return nextInt() / uint.MAX_VALUE;
    }

    public function nextRange(min:int, max:int):int {
        return min + (nextInt() % (max - min + 1));
    }
}

internal class Xorshift32 implements Generator {
    private var _seed:uint;
    private var _state:uint;

    public function Xorshift32(seed:uint) {
        _seed = seed;
        _state = seed;
    }

    public function nextInt():uint {
        _state ^= _state << 13;
        _state ^= _state >> 17;
        _state ^= _state << 5;
        return _state;
    }

    public function nextNumber():Number {
        return nextInt() / uint.MAX_VALUE;
    }

    public function nextRange(min:int, max:int):int {
        return min + (nextInt() % (max - min + 1));
    }
}

internal class LCG implements Generator {
    private var _state:uint;

    public function LCG(seed:uint) {
        // 确保种子不为0
        _state = seed || 0xBAD5EED;
    }

    public function nextInt():uint {
        _state = (_state * 48271) % 2147483647; // 线性同余法
        return _state;
    }

    public function nextNumber():Number {
        return (nextInt() & 0x7FFFFF) / 0x7FFFFF;
    }

    public function nextRange(min:int, max:int):int {
        return min + (nextInt() % (max - min + 1));
    }
}

internal interface Generator {
    function nextInt():uint
    function nextNumber():Number
    function nextRange(min:int, max:int):int
}
