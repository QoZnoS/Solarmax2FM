// 该类管理整个设置界面
package scenes {
    import managers.Globals;

    import scenes.menus.IMenu;
    import scenes.menus.MapackMenu;
    import scenes.menus.ReplayMenu;
    import scenes.menus.SettingMenu;
    import scenes.menus.StaffMenu;

    import starling.core.Starling;
    import starling.display.Quad;
    import starling.display.Sprite;
    import starling.events.Event;

    import ui.components.MenuButton;
    import ui.components.OptionButton;
    import scenes.menus.EmptyMenu;
    import scenes.menus.TeamEditorMenu;
    import starling.filters.BlurFilter;
    import managers.SaveManager;
    import scenes.menus.AdvancedSettingMenu;

    public class StartMenu extends Sprite {
        public var title:TitleMenu; // 接入标题类
        private var menuBtn:MenuButton;
        private var menus:Vector.<IMenu>;

        private const MAX_PAGE:int = 8;
        private const COLOR:uint = 0xFF9DBB;
        private const pageName:Array = ["SETTING", "MAPACKS", "STAFF", "REPLAY", "", "", "", ""];
        public var pages:Array;

        public function StartMenu(titleMenu:TitleMenu) {
            super();
            this.title = titleMenu;
            var bg:Quad = new Quad(1024, 768, 0);
            bg.alpha = 0.5;
            addChild(bg);
            menus = new Vector.<IMenu>(MAX_PAGE, true);
            menus[0] = new SettingMenu(title);
            menus[1] = new MapackMenu(title);
            menus[2] = new StaffMenu(title);
            menus[3] = new ReplayMenu(title);
            menus[4] = new EmptyMenu();
            menus[5] = new EmptyMenu();
            menus[6] = new AdvancedSettingMenu();
            menus[7] = new TeamEditorMenu();
            for (var i:int = 0; i < MAX_PAGE; i++) {
                menus[i].x = menus[i].pivotX = 512;
                menus[i].y = menus[i].pivotY = 384;
                if (i == 1 || i == 0)
                    menus[i].x += 72;
                addChild(menus[i] as Sprite);
                menus[i].animateOut();
            }
            pages = [];
            for (i = 0; i < MAX_PAGE; i++) {
                pages.push(new OptionButton(pageName[i], COLOR, pages));
                if (pageName[i] == "")
                    continue;
                pages[i].x = 15;
                pages[i].y = 160 + i * 48;
                pages[i].label.fontName = "Downlink18";
                pages[i].labelBG.width = pages[i].quad.width = 144;
                pages[i].labelBG.height = 36;
                pages[i].quad.height = 48;
                pages[i].label.x += 4;
                pages[i].label.y += 4;
                pages[i].addEventListener("clicked", on_page);
                addChild(pages[i]);
            }
            pages[0].toggle();
            menuBtn = new MenuButton("btn_menu");
            menuBtn.x = 15 + Globals.margin;
            menuBtn.y = 124;
            menuBtn.blendMode = "add";
            addChild(menuBtn);
            menuBtn.init();
            menuBtn.addEventListener("clicked", on_menu);
        }

        public function animateIn():void {
            this.alpha = 0;
            this.visible = true;
            menuBtn.touchable = true;
            for (var i:int = 0; i < MAX_PAGE; i++)
                if (pages[i].toggled && !menus[i].visible)
                    menus[i].animateIn();
            Starling.juggler.removeTweens(this);
            Starling.juggler.tween(this, 0.15, {"alpha": 1});
            SaveManager.textSize == 2 ? menuBtn.setImage("btn_menu2x", 0.75) : menuBtn.setImage("btn_menu");
            title.titleBox.filter = new BlurFilter();
            title.scene.getChildAt(0).filter = new BlurFilter();
        }

        public function animateOut():void {
            menuBtn.touchable = false;
            for (var i:int = 0; i < MAX_PAGE; i++)
                if (pages[i].toggled && menus[i].visible)
                    menus[i].animateOut();
            Starling.juggler.removeTweens(this);
            Starling.juggler.tween(this, 0.15, {"alpha": 0,
                    "onComplete": hide});
            title.titleBox.filter.dispose();
            title.titleBox.filter = null;
            title.scene.getChildAt(0).filter.dispose();
            title.scene.getChildAt(0).filter = null;
        }

        public function hide():void {
            this.visible = false;
        }

        public function on_menu(click:Event):void {
            SaveManager.save();
            animateOut();
        }

        public function on_page(click:Event):void {
            for (var i:int = 0; i < MAX_PAGE; i++) {
                if (pages[i].toggled && !menus[i].visible)
                    menus[i].animateIn();
                if (!pages[i].toggled && menus[i].visible)
                    menus[i].animateOut();
            }
        }
    }
}
