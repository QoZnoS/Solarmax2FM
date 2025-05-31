package {
    import flash.desktop.NativeApplication;
    import flash.display.Bitmap;
    import flash.display.Shape;
    import flash.display.Sprite;
    import flash.events.KeyboardEvent;
    import flash.events.MouseEvent;
    import flash.filesystem.File;
    import flash.geom.Rectangle;
    import flash.system.Capabilities;
    import flash.html.HTMLLoader;
    import starling.core.Starling;
    import starling.textures.Texture;
    import starling.utils.AssetManager;
    import starling.utils.RectangleUtil;
    import starling.utils.Color;
    import flash.display.StageDisplayState;

    [SWF(frameRate = "120", backgroundColor = "0x00000")]
    public class Main extends Sprite {

        private static var Background:Class = EmbeddedAssets.startup_png;
        private static var pause_img:Class = EmbeddedAssets.paused_png;
        private var mStarling:Starling;
        public var cover:Sprite;
        private var keyWidth:Number;
        private var screenWidth:Number;
        private var screenHeight:Number;
        private var scaleFactor:Number;
        private var assetDir:String;
        private var background:Bitmap;
        private var fullScreenWidth:Number;
        private var fullScreenHeight:Number;

        public function Main() {
            super();
            if (stage)
                load();
            else
                addEventListener("addedToStage", onAddedToStage);
        }

        public function onAddedToStage(param1:Object):void {
            removeEventListener("addedToStage", onAddedToStage);
            load();
        }

        public function load():void {
            Globals.device = getPlatform();
            Globals.margin = 0; // 边距，影响按钮到左右两侧的相对位置
            scaleFactor = 2; // 比例因子，缩放贴图大小，值越大图越小
            Globals.textSize = 1; // 文本大小参数
            assetDir = "2048px"; // 图片文件夹
            background = new Background(); // 创建背景实例
            Globals.main = this; // 
            Globals.load(); // 导入存档，然后执行start()
        }

        public function start():void {
            // 声明舞台缩放、尺寸、视口和资源的变量
            var stageScale:Number;
            var stageWidth:int;
            var stageHeight:int;
            var appDir:File;
            var assets:AssetManager;
            var shape:Shape;
            var pauseImg:Bitmap;
            // 将舞台缩放模式设置为“noScale”并与左上角对齐
            stage.scaleMode = "noScale";
            stage.align = "TL";
            // 根据全屏模式设定窗口大小
            if (Globals.fullscreen) {
                stage.stageWidth = stage.fullScreenWidth;
                stage.stageHeight = stage.fullScreenHeight;
                stage.displayState = "fullScreenInteractive";
            } else {
                stage.stageWidth = 1024;
                stage.stageHeight = 640;
                stage.displayState = "normal";
            }
            // 设置渲染的舞台尺寸
            stageWidth = 1024;
            stageHeight = 768;
            // 为Starling插件启用多点触控和丢失上下文处理
            Starling.multitouchEnabled = true;
            Starling.handleLostContext = true;
            // 根据屏幕和舞台尺寸计算视口矩形
            fullScreenWidth = Globals.stageWidth = stage.stageWidth;
            fullScreenHeight = Globals.stageHeight = stage.stageHeight;
            // 获取应用程序目录并创建 AssetManager
            appDir = File.applicationDirectory;
            assets = new AssetManager(scaleFactor, true);
            assets.verbose = Capabilities.isDebugger;
            // 将音频、字体和纹理资源加入队列
            assets.enqueue(appDir.resolvePath("audio"), appDir.resolvePath("fonts/" + assetDir), appDir.resolvePath("textures/" + assetDir), appDir.resolvePath("metadata"));
            assets.enqueue("backgrounds/" + assetDir + "/bg01.png");
            assets.enqueue("backgrounds/" + assetDir + "/bg02.png");
            assets.enqueue("backgrounds/" + assetDir + "/bg03.png");
            assets.enqueue("backgrounds/" + assetDir + "/bg04.png");
            Globals.scaleFactor = scaleFactor; // 设置全局比例因子
            // 使用指定参数创建一个新的 Starling 实例
            mStarling = new Starling(Root, stage, on_resize(null), null, "auto", "baseline");
            mStarling.stage.stageWidth = stageWidth;
            mStarling.stage.stageHeight = stageHeight;
            mStarling.enableErrorChecking = Capabilities.isDebugger;
            mStarling.antiAliasing = Math.pow(2, Globals.antialias);
            // 设置背景位置、尺寸和平滑度
            background.x = mStarling.viewPort.x;
            background.y = mStarling.viewPort.y;
            background.width = mStarling.viewPort.width;
            background.height = mStarling.viewPort.height;
            background.smoothing = true;
            addChild(background);
            // 为暂停覆盖创建封面精灵和形状
            cover = new Sprite();
            shape = new Shape();
            shape.graphics.beginFill(0);
            shape.graphics.drawRect(-10, -10, fullScreenWidth + 20, fullScreenHeight + 20);
            shape.graphics.endFill();
            shape.alpha = 0.5;
            cover.addChild(shape);
            // 创建暂停图像并将其添加到封面精灵
            pauseImg = new pause_img();
            pauseImg.scaleY = pauseImg.scaleX = fullScreenWidth / 1024 * 0.5;
            pauseImg.x = int(shape.width * 0.5 - pauseImg.width * 0.5 - 10);
            pauseImg.y = int(shape.height * 0.5 - pauseImg.height * 0.5 - 10);
            pauseImg.smoothing = true;
            cover.addChild(pauseImg);
            // 为“rootCreated”事件添加事件监听器
            mStarling.addEventListener("rootCreated", (function():* {
                var onRootCreated:Function = function(param1:Object, _root:Root):void {
                    mStarling.removeEventListener("rootCreated", onRootCreated);
                    removeChild(background);
                    _root.start(Texture.fromBitmap(background, false, false, scaleFactor), assets);
                    mStarling.start();
                };
                return onRootCreated;
            })());
            // 添加事件监听器，用于应用程序激活、停用和舞台调整大小
            NativeApplication.nativeApplication.addEventListener("activate", on_activate); // 监听程序得到焦点
            NativeApplication.nativeApplication.addEventListener("deactivate", on_deactivate); // 监听程序失去焦点
            stage.addEventListener("resize", on_resize); // 监听程序窗口缩放
        }

        public function getPlatform():String {
            var os:String = Capabilities.os.toLowerCase();
            var userAgent:String;
            // 尝试获取User Agent
            try {
                userAgent = new HTMLLoader().userAgent.toLowerCase();
            } catch (e:Error) {
                userAgent = "";
            }

            if (userAgent.indexOf("android") != -1) {
                return "Mobile"; // Android（User Agent中包含"android"）
            }
            else if (userAgent.indexOf("iphone") != -1 || userAgent.indexOf("ipad") != -1 || os.indexOf("iphone") != -1 || os.indexOf("ipad") != -1 || os.indexOf("ios") != -1) {
                return "Mobile"; // iOS（User Agent或os中包含iphone/ipad/ios）
            }
            else if (os.indexOf("win") != -1) {
                return "PC"; // Windows
            }
            else if (os.indexOf("mac") != -1) {
                return "PC"; // Mac OS
            }
            else if (os.indexOf("linux") != -1) {
                return "PC"; // Linux桌面（非Android情况）
            }
            else {
                return "PC"; // 未知平台
            }
        }

        public function on_fullscreen():void {
            if (Globals.device == "Mobile")
                return;
            if (Globals.fullscreen) {
                stage.stageWidth = stage.fullScreenWidth;
                stage.stageHeight = stage.fullScreenHeight;
                stage.displayState = "fullScreenInteractive";
            } else {
                stage.stageWidth = 1024;
                stage.stageHeight = 640;
                stage.displayState = "normal";
            }
            on_resize(null);
        }

        public function on_resize(param1:*):Rectangle {

            // 1. DPI感知：获取物理像素尺寸
            var actualScaleFactor:Number = stage.contentsScaleFactor || 1.0;
            fullScreenWidth = Globals.stageWidth = stage.stageWidth;
            fullScreenHeight = Globals.stageHeight = stage.stageHeight;

            // 2. 动态计算基准设计分辨率（推荐1024x768）
            var designWidth:Number = 1024;
            var designHeight:Number = 768;
            var designAspect:Number = 1024 / 540;
            var screenAspect:Number = fullScreenWidth / fullScreenHeight;

            // 3. 智能缩放因子计算（保持宽高比）
            var contentScale:Number = (screenAspect > designAspect) ? fullScreenHeight / 540 : // 竖屏主导
                fullScreenWidth / designWidth; // 横屏主导

            // 4. 视口计算（使用letterbox模式保持比例）
            var viewPortContent:Rectangle = new Rectangle(0, 0, designWidth * contentScale, designHeight * contentScale);
            var viewPort:Rectangle = RectangleUtil.fit(viewPortContent, new Rectangle(0, 0, fullScreenWidth, fullScreenHeight), "none");

            if (!mStarling || !mStarling.root)
                return viewPort;

            // 5. 应用更新到Starling
            mStarling.viewPort = viewPort;
            mStarling.stage.stageWidth = designWidth;
            mStarling.stage.stageHeight = designHeight;

            // 6. 覆盖层适配（全屏蒙版）
            var _shape:Shape = cover.getChildAt(0) as Shape;
            _shape.graphics.clear();
            _shape.graphics.beginFill(0, 0.5);
            _shape.graphics.drawRect(-10, -10, fullScreenWidth + 20, fullScreenHeight + 20);
            _shape.graphics.endFill();

            // 7. 暂停按钮动态适配（保持居中）
            var _pause:Bitmap = cover.getChildAt(1) as Bitmap;
            _pause.scaleX = _pause.scaleY = contentScale * 0.5; // 基于设计比例缩放
            _pause.x = (fullScreenWidth - _pause.width) * 0.5;
            _pause.y = (fullScreenHeight - _pause.height) * 0.5;
            _pause.smoothing = true;

            return null;
        }

        public function on_antialias():void {
            mStarling.antiAliasing = Math.pow(2, Globals.antialias);
        }

        public function on_activate(param1:*):void {
        }

        public function on_deactivate(param1:*):void {
            if (!Globals.nohup) { // 调整后台运行
                mStarling.stop();
                GS.pauseMusic();
                addChild(cover);
                cover.addEventListener("click", on_resume);
            }
        }

        public function on_resume(param1:MouseEvent):void {
            cover.removeEventListener("click", on_resume);
            removeChild(cover);
            mStarling.start();
            GS.resumeMusic();
        }
    }
}
