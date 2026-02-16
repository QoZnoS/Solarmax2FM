package managers {
    import flash.filesystem.File;
    import flash.filesystem.FileStream;
    import flash.events.IOErrorEvent;
    import flash.filesystem.FileMode;

    import utils.ReplayData;

    import starling.events.Event;

    public class Globals {
        public static const defaultGroups:Array = [0, 1, 2, 3, 4, 5, 6];
        public static const defaultColors:Array = [0xCCCCCC, 0x5FB6FF, 0xFF5D93, 0xFF8C5A, 0xCAFF6E, 0x999999, 0x000000];
        public static var main:Main;
        public static var level:int = 0; // 关卡
        public static var scaleFactor:Number = 2; // 比例因子
        public static var margin:Number = 30; // 边距，Main中设定30，影响按钮到左右两侧的相对位置
        public static var stageWidth:Number = 1920; // 画面宽度
        public static var stageHeight:Number = 1080; // 画面高度
        public static var device:String = "pc"; // 设备类型
        // #region 
        public static var teamGroups:Array = [0, 1, 2, 3, 4, 5, 6]; // 势力所属的队伍
        public static var teamColors:Array = [0xCCCCCC, 0x5FB6FF, 0xFF5D93, 0xFF8C5A, 0xCAFF6E, 0x999999, 0x000000]; // 势力颜色
        public static var teamDeepColors:Array = [false, false, false, false, false, false, true];
        public static var teamColorEnhances:Array = [false, false, false, false, false, false, false];
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
        public static var teamShowLabels:Array = [false, true, true, true, true, true, false]; // 是否显示兵力文本
        public static var teamCount:int = 7; // 势力数上限
        public static var playerTeam:int = 1; // 玩家势力
        // #endregion
        public static var exOptimization:int = 0; // 优化等级
        public static var isApril_Fools:Boolean = false; // 是否为愚人节

        public static var file:File; // 文件
        public static var fileStream:FileStream;
        // 以下为存档数据
        public static var replay:ReplayData;

        private static var _replayMetadataCache:Array; // 缓存数组
        private static var _replayMetadataCacheLoaded:Boolean; // 是否已加载

        /** 初始化势力数组 */
        public static function initTeam():void {
            fileStream = new FileStream();
            teamCount = LevelData.rawData[SaveManager.currentData].team.length;
            if (teamCount < 7)
                teamCount = 7;
            // 重置数组
            // #region S33加的初始化
            teamGroups = defaultGroups.slice();
            teamColors = defaultColors.slice();
            teamDeepColors = new Array();
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
            teamShowLabels = new Array();
            for (var i:int = 0; i < teamCount; i++) {
                if (teamGroups.length <= i)
                    teamColors.push(i);
                if (teamColors.length <= i)
                    teamColors.push(0);
                teamDeepColors.push(false);
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
                teamShowLabels.push(true);
            }
            teamShipSpeeds[6] = 100;
            teamDeepColors[6] = true;
            teamShowLabels[0] = teamShowLabels[6] = false;
            // #endregion
        }

        // 执行第一次载入
        public static function load():void {
            SaveManager.load();
            loadReplayMetadataCache();
            main.start();
        }

        /**
         * 加载回放元数据缓存（扫描 replay 目录，解析每个 .s2rp 文件）
         */
        private static function loadReplayMetadataCache():void {
            if (_replayMetadataCacheLoaded)
                return;
            _replayMetadataCache = [];
            var replayDir:File = File.applicationStorageDirectory.resolvePath("replay");
            if (!replayDir.exists) {
                _replayMetadataCacheLoaded = true;
                return;
            }
            var files:Array = replayDir.getDirectoryListing();
            for each (var f:File in files) {
                if (f.extension == "s2rp") {
                    try {
                        var fs:FileStream = new FileStream();
                        fs.open(f, FileMode.READ);
                        var data:String = fs.readMultiByte(fs.bytesAvailable, "utf-8");
                        fs.close();
                        var loadData:Array = JSON.parse(data) as Array;
                        // 提取分组键：JSON 第一个数组的第一个元素（mappack 名称）
                        var groupKey:String = (loadData && loadData.length > 0 && loadData[0] is Array && loadData[0].length > 0) ? String(loadData[0][0]) : "default";
                        _replayMetadataCache.push({file: f,
                                name: f.name.substr(0, f.name.lastIndexOf(".")),
                                modDate: f.modificationDate,
                                groupKey: groupKey});
                    } catch (e:Error) {
                        // 跳过损坏文件
                    }
                }
            }
            _replayMetadataCacheLoaded = true;
        }

        /**
         * 向缓存添加或更新一个回放文件的元数据
         */
        private static function addToReplayMetadataCache(file:File, groupKey:String):void {
            if (!_replayMetadataCacheLoaded)
                loadReplayMetadataCache();
            // 检查是否已存在（防止重复）
            for each (var item:Object in _replayMetadataCache) {
                if (item.file.nativePath == file.nativePath) {
                    item.modDate = file.modificationDate;
                    item.groupKey = groupKey;
                    return;
                }
            }
            _replayMetadataCache.push({file: file,
                    name: file.name.substr(0, file.name.lastIndexOf(".")),
                    modDate: file.modificationDate,
                    groupKey: groupKey});
        }

        /**
         * 从缓存中移除一个回放文件的元数据
         */
        private static function removeFromReplayMetadataCache(file:File):void {
            if (!_replayMetadataCacheLoaded)
                return;
            for (var i:int = 0; i < _replayMetadataCache.length; i++) {
                if (_replayMetadataCache[i].file.nativePath == file.nativePath) {
                    _replayMetadataCache.splice(i, 1);
                    break;
                }
            }
        }

        public static function auto_save_replay():void {
            // 确保缓存已加载
            loadReplayMetadataCache();

            var replayDir:File = File.applicationStorageDirectory.resolvePath("replay");
            if (!replayDir.exists)
                replayDir.createDirectory();

            // 使用缓存构建分组
            var replayGroups:Object = {};
            for each (var meta:Object in _replayMetadataCache) {
                var key:String = meta.groupKey;
                if (!replayGroups[key])
                    replayGroups[key] = [];
                replayGroups[key].push(meta);
            }

            // 每组按修改时间排序（旧的在前）
            for (var group:String in replayGroups) {
                var arr:Array = replayGroups[group];
                arr.sortOn("modDate", Array.NUMERIC);
                // 每组最多保留20个
                while (arr.length >= 20) {
                    var oldestMeta:Object = arr[0];
                    try {
                        oldestMeta.file.deleteFile(); // 同步删除文件
                        removeFromReplayMetadataCache(oldestMeta.file); // 从缓存移除
                    } catch (e:Error) {
                        // 删除失败，忽略（可能文件已被手动删除）
                    }
                    arr.shift();
                }
            }

            // 自动命名新回放
            var now:Date = new Date();
            var name:String = "auto_" + now.fullYear + ("0" + (now.month + 1)).substr(-2) + ("0" + now.date).substr(-2) + "_" + ("0" + now.hours).substr(-2) + ("0" + now.minutes).substr(-2) + ("0" + now.seconds).substr(-2);
            save_replay(name);
        }

        public static function save_replay(name:String):void {
            // 准备要写入的数据（同步操作）
            var data:Array = replay.save(name);
            var jsonData:String = JSON.stringify(data);

            var file:File = File.applicationStorageDirectory.resolvePath("replay/" + name + ".s2rp");
            var fileStream:FileStream = new FileStream();

            function onComplete(e:Event):void {
                fileStream.removeEventListener(Event.COMPLETE, onComplete);
                fileStream.removeEventListener(IOErrorEvent.IO_ERROR, onIOError);
                fileStream.close();

                // 文件写入成功，添加到缓存（利用已序列化的数据提取分组键）
                var groupKey:String = (data && data.length > 0 && data[0] is Array && data[0].length > 0) ? String(data[0][0]) : "default";
                addToReplayMetadataCache(file, groupKey);
            }

            function onIOError(e:IOErrorEvent):void {
                fileStream.removeEventListener(Event.COMPLETE, onComplete);
                fileStream.removeEventListener(IOErrorEvent.IO_ERROR, onIOError);
                fileStream.close();
                SceneController.alert("Failed to save replay: " + e.text);
            }

            fileStream.addEventListener(Event.COMPLETE, onComplete);
            fileStream.addEventListener(IOErrorEvent.IO_ERROR, onIOError);

            try {
                fileStream.openAsync(file, FileMode.WRITE);
                fileStream.writeUTFBytes(jsonData);
            } catch (e:Error) {
                SceneController.alert("Failed to open file for saving replay: " + e.message);
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
            switch (SaveManager.currentDifficulty) {
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
