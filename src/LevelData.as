// 静态文件不能使用 private 声明

package {
    import flash.filesystem.File;
    import flash.filesystem.FileStream;

    public class LevelData {
        public static var file:File; // 文件
        public static var fileStream:FileStream;
        public static var nodeData:XML;
        public static var extensions:XML;
        /** level.json 不含版本信息 */
        public static var rawData:Object;
        /** 关卡列表，经难度和图集修正 */
        public static var level:Array;

        public function LevelData() {
            super();
        }

        // 加载文件
        public static function init():void {
            fileStream = new FileStream();
            nodeData = Root.assets.getXml("Node");
            rawData = Root.assets.getObject("level").data;
            loadExtensions();
            Globals.initTeam();
            resetExtensions();
            if (Globals.device == "Mobile") {
                readExtensions();
                return
            }
            file = File.applicationDirectory.resolvePath("level.json");
            if (file.exists)
                load();
            readExtensions();
            updateLevelData();
        }

        public static function updateLevelData():void {
            var originalLevel:Object = rawData[Globals.currentData].level;
            level = JSON.parse(JSON.stringify(originalLevel)) as Array;
            process(level);
        }

        private static function process(obj:Object):void {
            for (var key:String in obj) {
                // 检查是否有难度后缀
                if (key.indexOf("/") > -1) {
                    var baseKey:String = key.replace(/\/.*$/, "");
                    var diff:String = key.substr(key.lastIndexOf("/") + 1);
                    // 判断当前难度是否匹配
                    if (Globals.currentDifficulty == diff)
                        obj[baseKey] = obj[key];
                    delete obj[key];
                } else if (obj[key] is Object)
                    process(obj[key]);
            }
        }

        // 导入关卡文件
        public static function load():void {
            fileStream.open(file, "read"); // 以只读模式打开文件
            var data:String = String(fileStream.readMultiByte(fileStream.bytesAvailable, "utf-8"));
            rawData = JSON.parse(data).data;
            fileStream.close(); // 关闭文件
        }

        public static function loadExtensions():void {
            file = File.applicationDirectory.resolvePath("extensions.xml");
            if (!file.exists)
                extensions = Root.assets.getXml("extensions")
            else {
                fileStream.open(file, "read");
                var _extensions:String = String(fileStream.readMultiByte(fileStream.bytesAvailable, "utf-8"));
                fileStream.close();
                extensions = XML(_extensions);
            }
            extensions.ignoreComments = true; // 忽略注释
        }

        public static function readExtensions():void {
            var _currentData:int = Globals.currentData;
            var _data:XMLList = extensions.data.(@id == _currentData);
            for each (var _team:XML in _data.team) {
                Globals.teamColors[_team.@id] = String(_team.@color) ? uint(_team.@color) : uint(extensions.data.(@id == 0).team.(@id == 6).@color);
                Globals.teamShipSpeeds[_team.@id] = String(_team.@shipSpeed) ? _team.@shipSpeed : extensions.data.(@id == 0).team.(@id == 0).@shipSpeed;
                Globals.teamShipAttacks[_team.@id] = String(_team.@shipAttack) ? _team.@shipAttack : extensions.data.(@id == 0).team.(@id == 0).@shipAttack;
                Globals.teamShipDefences[_team.@id] = String(_team.@shipDefence) ? _team.@shipDefence : extensions.data.(@id == 0).team.(@id == 0).@shipDefence;
                _team.@captureSpeed != undefined ? Globals.teamRepairingSpeeds[_team.@id] = Globals.teamColonizingSpeeds[_team.@id] = Globals.teamDestroyingSpeeds[_team.@id] = Globals.teamDecolonizingSpeeds[_team.@id] = _team.@captureSpeed : Globals.teamRepairingSpeeds[_team.@id] = Globals.teamColonizingSpeeds[_team.@id] = Globals.teamDestroyingSpeeds[_team.@id] = Globals.teamDecolonizingSpeeds[_team.@id] = extensions.data.(@id == 0).team.(@id == 0).@captureSpeed;
                Globals.teamRepairingSpeeds[_team.@id] = String(_team.@repairingSpeed) ? _team.@repairingSpeed : Globals.teamRepairingSpeeds[_team.@id];
                Globals.teamColonizingSpeeds[_team.@id] = String(_team.@colonizingSpeed) ? _team.@colonizingSpeed : Globals.teamColonizingSpeeds[_team.@id];
                Globals.teamDestroyingSpeeds[_team.@id] = String(_team.@destroyingSpeed) ? _team.@destroyingSpeed : Globals.teamDestroyingSpeeds[_team.@id];
                Globals.teamDecolonizingSpeeds[_team.@id] = String(_team.@decolonizingSpeed) ? _team.@decolonizingSpeed : Globals.teamDecolonizingSpeeds[_team.@id];
                Globals.teamConstructionStrengths[_team.@id] = String(_team.@constructionStrength) ? _team.@constructionStrength : extensions.data.(@id == 0).team.(@id == 0).@constructionStrength;
                Globals.teamNodeBuilds[_team.@id] = String(_team.@nodeBuild) ? _team.@nodeBuild : extensions.data.(@id == 0).team.(@id == 0).@nodeBuild;
                Globals.teamNodePops[_team.@id] = String(_team.@nodePop) ? _team.@nodePop : extensions.data.(@id == 0).team.(@id == 0).@nodePop;
            }
        }

        private static function resetExtensions():void {
            var _data:XMLList = extensions.data.(@id == 0);
            for each (var _team:XML in _data.team) {
                Globals.teamColors[_team.@id] = uint(_team.@color);
                Globals.teamShipSpeeds[_team.@id] = _team.@shipSpeed;
                Globals.teamShipAttacks[_team.@id] = _team.@shipAttack;
                Globals.teamShipDefences[_team.@id] = _team.@shipDefence;
                Globals.teamRepairingSpeeds[_team.@id] = Globals.teamColonizingSpeeds[_team.@id] = Globals.teamDestroyingSpeeds[_team.@id] = Globals.teamDecolonizingSpeeds[_team.@id] = _team.@captureSpeed;
                Globals.teamConstructionStrengths[_team.@id] = _team.@constructionStrength;
                Globals.teamNodeBuilds[_team.@id] = _team.@nodeBuild;
                Globals.teamNodePops[_team.@id] = _team.@nodePop;
            }
        }
    }
}
