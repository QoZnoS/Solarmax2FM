// 静态文件不能使用 private 声明

package {
    import flash.filesystem.File;
    import flash.filesystem.FileStream;

    public class LevelData {
        public static var maps:Array; // 储存关卡
        public static var file:File; // 文件
        public static var fileStream:FileStream;
        public static var difficulty:Array; // 难度标识数据
        public static var currentFile:Array; // 当前读取的文件
        public static var nodeData:XML;
        public static var extensions:XML;
        public static var data:Array;

        public static var level:Object; // level.json

        public function LevelData() {
            super();
        }

        // 加载文件
        public static function init():void {
            fileStream = new FileStream();
            nodeData = Root.assets.getXml("Node");
            data = Root.assets.getObject("data") as Array;
            level = Root.assets.getObject("level");
            loadExtensions();
            Globals.initTeam();
            resetExtensions();
            if (Globals.device == "Mobile") {
                currentFile = data[Globals.currentData];
                maps = currentFile[0];
                difficulty = currentFile[1];
                readExtensions(); // 读取文件
                return
            }
            file = File.applicationDirectory.resolvePath("data.txt"); // 读取文件Data.txt
            if (!file.exists) {
                currentFile = data[Globals.currentData];
                maps = currentFile[0];
                difficulty = currentFile[1];
            } else
                load(); // 导入文件
            readExtensions(); // 读取文件
        }

        // 导入关卡文件
        public static function load():void {
            fileStream.open(file, "read"); // 以只读模式打开文件
            var _data:String = String(fileStream.readMultiByte(fileStream.bytesAvailable, "utf-8")); // 按utf-8编码读取文件并转化为字符串
            fileStream.close(); // 关闭文件
            data = JSON.parse(_data) as Array; // 将文件内容转化为字符串并写入Data
            currentFile = data[Globals.currentData]; // 读取当前配置
            maps = currentFile[0]; // 设置maps
            difficulty = currentFile[1]; // 设置Difficulty
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
