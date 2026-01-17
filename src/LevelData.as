// 静态文件不能使用 private 声明

package {
    import flash.filesystem.File;
    import flash.filesystem.FileStream;

    public class LevelData {
        public static var file:File; // 文件
        public static var fileStream:FileStream;
        public static var nodeData:XML;
        /** level.json 不含版本信息 */
        public static var rawData:Array;
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
            file = File.applicationDirectory.resolvePath("level.json");
            if (file.exists)
                load();
            updateLevelData();
            
            if (Globals.currentData >= rawData.length){
                SceneController.alert("The selected Mappack does not exist!");
                Globals.currentData = 0;
            }
            Globals.initTeam();
            updateTeam();
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

        private static function updateTeam():void {
            var len:int = rawData[Globals.currentData].team.length;
            for (var i:int = 0; i < len; i++) {
                var teamData:Object = rawData[Globals.currentData].team[i];
                // #region S33加的读取
                if ("group" in teamData)
                    Globals.teamGroups[i] = teamData.group;
                else
                    Globals.teamGroups[i] = i;
                if ("color" in teamData)
                    Globals.teamColors[i] = teamData.color;
                if ("shipSpeed" in teamData)
                    Globals.teamShipSpeeds[i] = teamData.shipSpeed;
                if ("shipAttack" in teamData)
                    Globals.teamShipAttacks[i] = teamData.shipAttack;
                if ("shipDefence" in teamData)
                    Globals.teamShipDefences[i] = teamData.shipDefence;
                if ("captureSpeed" in teamData)
                    Globals.teamRepairingSpeeds[i] = Globals.teamColonizingSpeeds[i] = Globals.teamDestroyingSpeeds[i] = Globals.teamDecolonizingSpeeds[i] = teamData.captureSpeed;
                if ("repairingSpeed" in teamData)
                    Globals.teamRepairingSpeeds[i] = teamData.repairingSpeed;
                if ("colonizingSpeed" in teamData)
                    Globals.teamColonizingSpeeds[i] = teamData.colonizingSpeed;
                if ("destroyingSpeed" in teamData)
                    Globals.teamDestroyingSpeeds[i] = teamData.destroyingSpeed;
                if ("decolonizingSpeed" in teamData)
                    Globals.teamDecolonizingSpeeds[i] = teamData.decolonizingSpeed;
                if ("constructionStrength" in teamData)
                    Globals.teamConstructionStrengths[i] = teamData.constructionStrength;
                if ("nodeBuild" in teamData)
                    Globals.teamNodeBuilds[i] = teamData.nodeBuild;
                if ("nodePop" in teamData)
                    Globals.teamNodePops[i] = teamData.nodePop;
                if ("showLabel" in teamData)
                    Globals.teamShowLabels[i] = teamData.showLabel
            }
        }
        // 导入关卡文件
        public static function load():void {
            fileStream.open(file, "read"); // 以只读模式打开文件
            var data:String = String(fileStream.readMultiByte(fileStream.bytesAvailable, "utf-8"));
            rawData = JSON.parse(data).data;
            fileStream.close(); // 关闭文件
        }
    }
}
