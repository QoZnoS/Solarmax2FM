package managers {
    import flash.filesystem.File;
    import flash.filesystem.FileStream;

    public class SaveManager {
        public static var playerData:Array = []; // 储存玩家存档，与playerData.txt同步
        public static var levelReached:int = 0; // 已通过关卡，playerData.txt第一项
        public static var soundVolume:Number = 1; // 音乐音量，playerData.txt第二项
        public static var musicVolume:Number = 1; // 音效音量，playerData.txt第三项
        public static var transitionSpeed:Number = 1; // 动画时长，playerData.txt第四项
        public static var textSize:int = 1; // 文本大小参数，playerData.txt第六项
        public static var fullscreen:Boolean = true; // 是否全屏，playerData.txt第八项
        public static var antialias:int = 4; // 抗锯齿参数，playerData.txt第九项
        public static var touchControls:Boolean = true; // 控制方式，playerData.txt第十六项
        public static var levelData:Array = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]; // 每关已获取的星数，playerData.txt第十七项
        public static var currentDifficulty:String = "normal"; // 当前难度，playerData.txt第十八项，levelData后第一项
        public static var blackQuad:Boolean = true; // 是否生成黑边，playerData.txt第十九项，levelData后第二项
        public static var currentData:int = 0; // 当前关卡数据，playerData.txt第二十项，levelData后第三项
        public static var nohup:Boolean = false; // 禁用暂停，playerData.txt第二十一项，levelData后第四项
        public static var fleetSliderPosition:int = 1; // 分兵条位置
        public static var maxMarginTeam:int = 8; // 最大边距势力数，合作中势力数达到该值时兵力文本显示与战争状态相同

        private static var file:File; // 文件
        private static var fileStream:FileStream;

        // public static var saveData:Dictionary = new Dictionary(true);

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
                    // saveVersion = -1;
                    SceneController.alert("Failed to read the save file: " + error.message);
                }
            }

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

        // public static function save_new():void {
        //     var data:String = JSON.stringify(saveData);
        //     file = File.applicationStorageDirectory.resolvePath("saveData.json");
        //     fileStream.open(file, "write");
        //     fileStream.writeUTFBytes(data);
        //     fileStream.close();
        // }


    }
}
