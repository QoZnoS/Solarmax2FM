package {
    import flash.filesystem.File;
    import flash.filesystem.FileStream;
    import flash.utils.Dictionary;
    import utils.ReplayData;

    public class Globals {
        public static var main:Main;
        public static var level:int = 0; // 关卡
        public static var scaleFactor:Number = 2; // 比例因子
        public static var margin:Number = 0; // 边距，Main中设定30，影响按钮到左右两侧的相对位置
        public static var stageWidth:Number = 1920; // 画面宽度
        public static var stageHeight:Number = 1080; // 画面高度
        public static var device:String = "pc"; // 设备类型
        public static var teamColors:Array = [0xCCCCCC, 0x5FB6FF, 0xFF5D93, 0xFF8C5A, 0xCAFF6E, 0x999999, 0x000000]; // 势力颜色
        public static var teamCaps:Array = [0, 0, 0, 0, 0, 0, 0]; // 势力在关卡内的总飞船上限
        public static var teamPops:Array = [0, 0, 0, 0, 0, 0, 0]; // 势力在关卡内的总飞船数
        public static var teamShipSpeeds:Array = [50, 50, 50, 50, 50, 50, 100]; // 基础飞船速度
        public static var teamShipAttacks:Array = [1, 1, 1, 1, 1, 1, 1]; // 飞船攻击倍率
        public static var teamShipDefences:Array = [1, 1, 1, 1, 1, 1, 1]; // 飞船伤害抗性
        public static var teamRepairingSpeeds:Array = [1, 1, 1, 1, 1, 1, 1]; // 修复速度倍率
        public static var teamColonizingSpeeds:Array = [1, 1, 1, 1, 1, 1, 1]; // 建造速度倍率
        public static var teamDestroyingSpeeds:Array = [1, 1, 1, 1, 1, 1, 1]; // 摧毁速度倍率
        public static var teamDecolonizingSpeeds:Array = [1, 1, 1, 1, 1, 1, 1]; // 中立破坏速度倍率
        public static var teamConstructionStrengths:Array = [1, 1, 1, 1, 1, 1, 1]; // 基地强度
        public static var teamNodeBuilds:Array = [1, 1, 1, 1, 1, 1, 1]; // 生产速度倍率
        public static var teamNodePops:Array = [1, 1, 1, 1, 1, 1, 1]; // 飞船上限倍率
        public static var teamCount:int = 7; // 势力数上限
        public static var playerTeam:int = 1; // 玩家势力
        public static var exOptimization:int = 0; // 优化等级
        public static var isApril_Fools:Boolean = false; // 是否为愚人节

        public static var file:File; // 文件
        public static var fileStream:FileStream;
        // 以下为存档数据
        public static var playerData:Array = []; // 储存玩家存档，与playerData.txt同步
        public static var levelReached:int = 0; // 已通过关卡，playerData.txt第一项
        public static var soundVolume:Number = 1; // 音乐音量，playerData.txt第二项
        public static var musicVolume:Number = 1; // 音效音量，playerData.txt第三项
        public static var transitionSpeed:Number = 1; // 动画时长，playerData.txt第四项
        public static var textSize:int = 1; // 文本大小参数，playerData.txt第六项
        public static var fullscreen:Boolean = true; // 是否全屏，playerData.txt第八项
        public static var antialias:int = 3; // 抗锯齿参数，playerData.txt第九项
        public static var touchControls:Boolean = true; // 控制方式，playerData.txt第十六项
        public static var levelData:Array = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]; // 每关已获取的星数，playerData.txt第十七项
        public static var currentDifficulty:String = "normal"; // 当前难度，playerData.txt第十八项，levelData后第一项
        public static var blackQuad:Boolean = true; // 是否生成黑边，playerData.txt第十九项，levelData后第二项
        public static var currentData:int = 0; // 当前关卡数据，playerData.txt第二十项，levelData后第三项
        public static var nohup:Boolean = false; // 禁用暂停，playerData.txt第二十一项，levelData后第四项
        public static var fleetSliderPosition:int = 1; // 分兵条位置

        public static const VERSION:int = 250905;

        public static var saveVersion:int = VERSION;

        public static var saveData:Dictionary = new Dictionary(true);
        public static var replay:ReplayData;

        /** 初始化势力数组 */
        public static function initTeam():void {
            fileStream = new FileStream();
            teamCount = LevelData.rawData[Globals.currentData].team.length;
            if (teamCount == 7)
                return;
            // 重置数组
            teamCaps = new Array();
            teamPops = new Array();
            teamShipSpeeds = new Array();
            teamShipAttacks = new Array();
            teamShipDefences = new Array();
            teamRepairingSpeeds = new Array();
            teamColonizingSpeeds = new Array();
            teamDestroyingSpeeds = new Array();
            teamDecolonizingSpeeds = new Array();
            teamConstructionStrengths = new Array();
            teamNodeBuilds = new Array();
            teamNodePops = new Array();
            for (var i:int = 0; i < teamCount; i++) {
                if (teamColors.length <= i)
                    teamColors.push(0);
                teamCaps.push(0);
                teamPops.push(0);
                teamShipSpeeds.push(50);
                teamShipAttacks.push(1);
                teamShipDefences.push(1);
                teamRepairingSpeeds.push(1);
                teamColonizingSpeeds.push(1);
                teamDestroyingSpeeds.push(1);
                teamDecolonizingSpeeds.push(1);
                teamConstructionStrengths.push(1);
                teamNodeBuilds.push(1);
                teamNodePops.push(1);
            }
            teamShipSpeeds[6] = 100;
        }

        // 加载存档文件
        public static function load():void {
            var _data:String = null; // 字符串，储存存档
            file = File.applicationStorageDirectory.resolvePath("playerData.txt"); // 读取文件playData.txt
            fileStream = new FileStream();
            try {
                fileStream.open(file, "read"); // 以只读模式打开文件
                _data = String(fileStream.readMultiByte(fileStream.bytesAvailable, "utf-8")); // 按utf-8编码读取并转换成字符串
                fileStream.close(); // 关闭文件
                playerData = JSON.parse(_data) as Array;
                // 接下来依次读取playerData中的各项数据
                levelReached = playerData[0];
                soundVolume = playerData[1];
                musicVolume = playerData[2];
                transitionSpeed = playerData[3];
                textSize = playerData[5];
                fullscreen = playerData[7];
                antialias = playerData[8];
                touchControls = playerData[15];
                levelData = playerData[16];
                currentDifficulty = playerData[17];
                blackQuad = playerData[18];
                currentData = playerData[19];
                nohup = playerData[20];
            } catch (error:Error) {
                // 储存默认数据到playerData.txt
                playerData = [levelReached, soundVolume, musicVolume, transitionSpeed, 0, textSize, 0, fullscreen, antialias, 0, 0, 0, 0, 0, 0, touchControls, levelData, currentDifficulty, blackQuad, currentData, nohup];
                if (!file.exists) { // 如果文件不存在
                    save(); // 保存存档文件到本地
                } else { // 如果文件存在
                    saveVersion = -1;
                    SceneController.alert("Failed to read the save file: " + error.message);
                }
            }

            main.start(); // 执行main.as中的start()
        }

        // 保存存档文件
        public static function save():void {
            playerData = [levelReached, soundVolume, musicVolume, transitionSpeed, 0, textSize, 0, fullscreen, antialias, 0, 0, 0, 0, 0, 0, touchControls, levelData, currentDifficulty, blackQuad, currentData, nohup];
            var _data:String = JSON.stringify(playerData); // 将playerData转换为json字符串
            file = File.applicationStorageDirectory.resolvePath("playerData.txt"); // 读取文件playData.txt
            fileStream.open(file, "write"); // 以写入模式打开文件
            fileStream.writeUTFBytes(_data);
            fileStream.close(); // 关闭文件
        }

        public static function save_new():void {
            var data:String = JSON.stringify(saveData);
            file = File.applicationStorageDirectory.resolvePath("saveData.json");
            fileStream.open(file, "write");
            fileStream.writeUTFBytes(data);
            fileStream.close();
        }

        public static function auto_save_replay():void {
            var replayDir:File = File.applicationStorageDirectory.resolvePath("replay");
            if (!replayDir.exists)
                replayDir.createDirectory();
            var files:Array = replayDir.getDirectoryListing();
            var replayGroups:Object = {};
            for each (var f:File in files) {
                if (f.extension == "s2rp" && f.name.startsWith("auto")) {
                    try {
                        var fs:FileStream = new FileStream();
                        fs.open(f, "read");
                        var loadData:Array = JSON.parse(fs.readMultiByte(fs.bytesAvailable, "utf-8")) as Array;
                        fs.close();
                        var key:String = (loadData && loadData.length > 0 && loadData[0].length > 0) ? String(loadData[0][0]) : "default";
                        if (!replayGroups[key])
                            replayGroups[key] = [];
                        replayGroups[key].push(f);
                    } catch (e:Error) {
                        // 跳过损坏文件
                    }
                }
            }
            // 每组按修改时间排序，旧的在前
            for (var group:String in replayGroups) {
                var arr:Array = replayGroups[group];
                arr.sortOn("modificationDate", Array.NUMERIC);
                // 每组最多保留20个
                while (arr.length >= 20) {
                    try {
                        arr[0].deleteFile();
                    } catch (e:Error) {
                    }
                    arr.shift();
                }
            }
            // 自动命名新回放，格式 auto_时间
            var now:Date = new Date();
            var name:String = "auto_" + now.fullYear + ("0" + (now.month + 1)).substr(-2) + ("0" + now.date).substr(-2) + "_" + ("0" + now.hours).substr(-2) + ("0" + now.minutes).substr(-2) + ("0" + now.seconds).substr(-2);
            save_replay(name);
        }

        public static function save_replay(name:String):void {
            var data:String = JSON.stringify(replay.save(name));
            var filePath:String = "replay/" + name + ".s2rp"
            file = File.applicationStorageDirectory.resolvePath(filePath);
            try {
                fileStream.open(file, "write");
                fileStream.writeUTFBytes(data);
                fileStream.close();
            } catch (e:Error) {
                SceneController.alert("Failed to save replay: " + e.message);
            }
        }

        public static function load_replay(name:String):void {
            var filePath:String = "replay/" + name + ".s2rp"
            file = File.applicationStorageDirectory.resolvePath(filePath);
            try {
                fileStream.open(file, "read");
                var loadData:Array = JSON.parse(fileStream.readMultiByte(fileStream.bytesAvailable, "utf-8")) as Array;
                replay = new ReplayData(loadData[0][0], loadData[0][1], loadData[0][2]);
                replay.load(loadData);
                fileStream.close();
            } catch (e:Error) {
                SceneController.alert("Failed to load replay: " + e.message);
            }
        }

        public static function get difficultyInt():int {
            switch (currentDifficulty) {
                case "easy":
                    return 1
                case "normal":
                    return 2
                case "hard":
                    return 3
                default:
                    return 0
            }
        }
    }
}
