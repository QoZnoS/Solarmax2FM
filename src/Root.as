package {
    import starling.core.Starling;
    import starling.display.Image;
    import starling.display.Sprite;
    import starling.textures.Texture;
    import starling.utils.AssetManager;
    import utils.ProgressBar;
    import utils.ScrollingBackground;
    import utils.GS;
    import utils.Drawer;
    import Entity.ParticleSystem;

    public class Root extends Sprite {

        private static var sAssets:AssetManager;
        public static var bg:ScrollingBackground;

        private var mActiveScene:Sprite;
        private var scene:SceneController;

        public function Root() {
            super();
        }

        public static function get assets():AssetManager {
            return sAssets;
        }

        public function start(param1:Texture, param2:AssetManager):void {
            var bgImage:Image;
            var progressBar:ProgressBar;
            var background:Texture = param1;
            var assets:AssetManager = param2;
            sAssets = assets;
            this.alpha = 0.9999;
            bgImage = new Image(background);
            addChild(bgImage);
            progressBar = new ProgressBar(512, 3);
            progressBar.x = (background.width - progressBar.width) / 2;
            progressBar.y = background.height * 0.55;
            addChild(progressBar);
            assets.loadQueue((function():* {
                var onProgress:Function = function(param1:Number):void {
                    var ratio:Number = param1;
                    progressBar.ratio = ratio;
                    if (ratio == 1) // 加载完成时
                    {
                        Starling.juggler.delayCall(function():void {
                            progressBar.removeFromParent(true);
                            removeChildAt(0);
                            Drawer.init();
                            LevelData.init();
                            bg = new ScrollingBackground();
                            addChild(bg);
                            scene = new SceneController()
                            addChild(scene);
                            GS.init();
                            ParticleSystem.init();
                        }, 0.05);
                    }
                }; // 声明函数对象
                return onProgress;
            })());
        }
    }
}
