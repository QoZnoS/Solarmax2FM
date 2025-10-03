package Menus.StartMenus {
    import starling.display.Sprite;
    import Menus.TitleMenu;
    import starling.core.Starling;
    import UI.Component.OptionButton;
    import flash.filesystem.File;

    public class ReplayMenu extends Sprite implements IMenu {

        private var title:TitleMenu;
        private var btn:OptionButton;

        public function ReplayMenu(title:TitleMenu) {
            this.title = title;
            init()
        }

        public function init():void {
            btn = new OptionButton("Open save folder", 0xFF9DBB);
            btn.x = 512;
            btn.y = 384;
            addChild(btn);
            btn.addEventListener("clicked", open_folder)
        }

        public function deinit():void {
            throw new Error("Method not implemented.");
        }

        public function animateIn():void {
            this.visible = true
            Starling.juggler.removeTweens(this);
            Starling.juggler.tween(this, 0.15, {"alpha": 1});
        }

        public function animateOut():void {
            Starling.juggler.removeTweens(this);
            Starling.juggler.tween(this, 0.15, {"alpha": 0,
                    "onComplete": hide});
        }

        private function hide():void {
            this.visible = false;
        }

        private function open_folder():void {
            var file:File = File.desktopDirectory;
            try {
                file.browseForDirectory("选择路径")
            } catch (error:Error) {
                file.requestPermission();
            }
        }
    }
}
