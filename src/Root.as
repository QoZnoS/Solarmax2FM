package {
    import starling.display.Image;
    import starling.assets.AssetManager;
    import starling.display.Sprite;
    import starling.textures.Texture;

    import utils.Drawer;
    import utils.ProgressBar;
    import utils.ScrollingBackground;

    import managers.LevelData;
    import managers.AudioManager;

    import core.ParticleSystem;
    import starling.assets.AssetReference;

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
            assets.loadQueue(function(manager:AssetManager):void {
                progressBar.removeFromParent(true);
                removeChildAt(0);
                Drawer.init();
                LevelData.init();
                bg = new ScrollingBackground();
                scene = new SceneController()
                scene.addChildAt(bg, 0);
                addChild(scene);
                AudioManager.init();
                ParticleSystem.init();
            }, function(error:String, reference:AssetReference):void {
                trace("加载失败: " + error + " 资源名: " + reference.name);
            }, function(ratio:Number):void {
                progressBar.ratio = ratio;
            });
        }
    }
}
