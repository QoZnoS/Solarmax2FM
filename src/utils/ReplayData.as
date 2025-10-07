package utils {

    public class ReplayData {
        public var seed:int;
        public var frame:int;
        public var winTeam:int;
        public var difficulty:String;
        /** mappack name, level name, player name */
        public var level:Vector.<String>;
        public var frameTime:Vector.<Number>;
        /** 记录含当前帧执行的操作总数 */
        public var actionCL:Vector.<int>;
        /** [node,team,target,ship] */
        public var rep:Vector.<Vector.<int>>;

        private var _writing:Boolean;
        private var _reading:Boolean;

        public function ReplayData(mappack:String, level:String, seed:int) {
            this.seed = seed;
            this.frame = 0;
            this.frameTime = new Vector.<Number>;
            this.actionCL = new Vector.<int>;
            this.rep = new Vector.<Vector.<int>>;
            this.level = Vector.<String>([mappack, level, ""]);
            this.difficulty = Globals.currentDifficulty;
            // level[0] = mappack, level[1] = level;
            _writing = true;
            _reading = false;
        }

        /**
         * 添加一步操作或一帧时长，添加操作时deltaTime应为0，添加帧时长时后四项应不填
         * @param deltaTime 帧时长
         * @param node 出兵天体
         * @param team 出兵势力
         * @param ship 派出飞船数
         * @param target 目标天体
         */
        public function addAction(deltaTime:Number, node:int = -1, team:int = -1, ship:int = -1, target:int = -1):void {
            if (!_writing)
                return;
            if (node == -1 || ship == -1 || target == -1) {
                frame++;
                frameTime.push(deltaTime);
                actionCL.length == 0 ? actionCL.push(0) : actionCL.push(actionCL[actionCL.length - 1]);
                return;
            }
            var action:Vector.<int> = new Vector.<int>(4, true);
            action[0] = node, action[1] = team, action[2] = target, action[3] = ship;
            // frameTime.push(deltaTime);
            actionCL[actionCL.length - 1]++;
            rep.push(action);
        }

        /**
         * 读取特定步指令
         * @param frame
         * @return 首项为帧时间，后每四项为一步操作
         */
        public function readAction(frame:int):Array {
            if (frame >= actionCL.length - 1)
                _reading = false;
            var output:Array = [frameTime[frame]];
            var actionIndex:int = (frame == 0 ? 0 : actionCL[frame - 1]);
            var actionCount:int = actionCL[frame] - actionIndex;
            for (var i:int = 0; i < actionCount; i++)
                output.push(rep[actionIndex + i][0], rep[actionIndex + i][1], rep[actionIndex + i][2], rep[actionIndex + i][3]);
            return output;
        }

        public function startRead():void {
            _reading = true;
            _writing = false;
            frame = 0;
        }

        /** @return 首项为帧时间，后每四项为一步操作 */
        public function stepping():Array {
            if (!_reading)
                throw new Error("Please execult startRead() at first");
            var arr:Array = readAction(frame);
            frame++;
            return arr;
        }

        public function save(player:String):Array {
            _writing = _reading = false;
            level[2] = player;
            var output:Array = [[level[0], level[1], seed, level[2]]];
            var arr:Array = [];
            var len:int = actionCL.length;
            for (var i:int = 0; i < len; i++) {
                arr = readAction(i);
                output.push(arr);
            }
            return output;
        }

        public function load(data:Array):void {
            _writing = _reading = false;
            // 清空原有数据
            frame = 0;
            frameTime.length = 0;
            actionCL.length = 0;
            rep.length = 0;
            // 读取关卡信息
            var arr:Array = data.shift();
            level[0] = arr[0], level[1] = arr[1], seed = arr[2], level[2] = arr[3];
            var totalActions:int = 0;
            // 读取每帧数据
            for each (arr in data) {
                frameTime.push(arr[0]);
                var actionsInFrame:int = (arr.length - 1) / 4;
                totalActions += actionsInFrame;
                actionCL.push(totalActions);
                for (var i:int = 0; i < actionsInFrame; i++) {
                    var action:Vector.<int> = new Vector.<int>(4, true);
                    action[0] = arr[1 + i * 4], action[1] = arr[2 + i * 4], action[2] = arr[3 + i * 4], action[3] = arr[4 + i * 4];
                    rep.push(action);
                }
            }
        }

        public function get totalTime():String {
            var time:Number = 0;
            for each (var t:Number in frameTime)
                time += t;
            time = Math.max(0, time); // 保证非负
            var hours:int = int(time / 3600);
            var minutes:int = int((time % 3600) / 60);
            var seconds:int = int(time % 60);

            var result:String = "";
            if (hours > 0)
                result += hours + "h";
            if (minutes > 0) {
                if (result.length > 0)
                    result += " ";
                result += minutes + "m";
            }
            if (seconds > 0 || result.length == 0) {
                if (result.length > 0)
                    result += " ";
                result += seconds + "s";
            }
            return result;
        }

        public function get reading():Boolean{
            return _reading;
        }

        public function get deepCopy():ReplayData {
            var copy:ReplayData = new ReplayData(level[0], level[1], seed);
            copy.frame = this.frame;
            copy.winTeam = this.winTeam;
            copy.difficulty = this.difficulty;
            copy.level[2] = this.level[2];

            // Deep copy vectors
            copy.frameTime = new Vector.<Number>(this.frameTime.length, true);
            for (var i:int = 0; i < this.frameTime.length; i++) {
            copy.frameTime[i] = this.frameTime[i];
            }

            copy.actionCL = new Vector.<int>(this.actionCL.length, true);
            for (i = 0; i < this.actionCL.length; i++) {
            copy.actionCL[i] = this.actionCL[i];
            }

            copy.rep = new Vector.<Vector.<int>>(this.rep.length, true);
            for (i = 0; i < this.rep.length; i++) {
            var action:Vector.<int> = new Vector.<int>(4, true);
            for (var j:int = 0; j < 4; j++) {
                action[j] = this.rep[i][j];
            }
            copy.rep[i] = action;
            }

            // Copy internal state
            copy._writing = this._writing;
            copy._reading = this._reading;

            return copy;
        }
    }
}


