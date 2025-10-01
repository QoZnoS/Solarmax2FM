// 该类管理整个设置界面
package Menus {
    import starling.core.Starling;
    import starling.display.Quad;
    import starling.display.Sprite;
    import starling.events.Event;
    import Menus.StartMenus.IMenu;
    import Menus.StartMenus.SettingMenu;
    import Menus.StartMenus.MapackMenu;
    import Menus.StartMenus.StaffMenu;
    import UI.Component.MenuButton;
    import UI.Component.OptionButton;
    import Menus.StartMenus.ReplayMenu;

    public class StartMenu extends Sprite {
        public var title:TitleMenu; // 接入标题类
        private var menuBtn:MenuButton;
        private var menus:Vector.<IMenu>;

        private const MAX_PAGE:int = 4;
        private const COLOR:uint = 0xFF9DBB;
        private const pageName:Array = ["SETTING", "MAPACKS", "STAFF", "REPLAY"]
        private var pages:Array;

        public function StartMenu(_titleMenu:TitleMenu) {
            super();
            this.title = _titleMenu;
            var bg:Quad = new Quad(1024, 768, 0);
            bg.alpha = 0.65;
            addChild(bg);
            menus = new Vector.<IMenu>(MAX_PAGE, true)
            menus[0] = new SettingMenu(title);
            menus[1] = new MapackMenu(title);
            menus[2] = new StaffMenu(title);
            menus[3] = new ReplayMenu(title);
            for (var i:int = 0; i < MAX_PAGE; i++) {
                menus[i].x = menus[i].pivotX = 512;
                menus[i].y = menus[i].pivotY = 384;
                if (i == 1 || i == 0)
                    menus[i].x += 72;
                addChild(menus[i] as Sprite);
                menus[i].animateOut()
            }
            pages = []
            for (i = 0; i < MAX_PAGE; i++) {
                pages.push(new OptionButton(pageName[i], COLOR, pages));
                pages[i].x = 15;
                pages[i].y = 160 + i*48;
                pages[i].label.fontName = "Downlink18";
                pages[i].labelBG.width = pages[i].quad.width = 144;
                pages[i].labelBG.height = 36;
                pages[i].quad.height = 48;
                pages[i].label.x += 4;
                pages[i].label.y += 4;
                pages[i].addEventListener("clicked", on_page)
                addChild(pages[i])
            }
            pages[0].toggle()
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
            for(var i:int = 0; i < MAX_PAGE; i++)
                if (pages[i].toggled && !menus[i].visible)
                    menus[i].animateIn()
            Starling.juggler.removeTweens(this);
            Starling.juggler.tween(this, 0.15, {"alpha": 1});
            Globals.textSize == 2 ? menuBtn.setImage("btn_menu2x", 0.75) : menuBtn.setImage("btn_menu");
        }

        public function animateOut():void {
            for(var i:int = 0; i < MAX_PAGE; i++)
                if (pages[i].toggled && menus[i].visible)
                    menus[i].animateOut()
            Starling.juggler.removeTweens(this);
            Starling.juggler.tween(this, 0.15, {"alpha": 0,
                    "onComplete": hide});
        }

        public function hide():void {
            this.visible = false;
        }

        public function on_menu(_click:Event):void {
            Globals.save();
            animateOut();
        }

        public function on_page(_click:Event = null):void {
            for(var i:int = 0; i < MAX_PAGE; i++)
            {
                if (pages[i].toggled && !menus[i].visible)
                    menus[i].animateIn()
                if (!pages[i].toggled && menus[i].visible)
                    menus[i].animateOut()
            }
        }
    }
}
