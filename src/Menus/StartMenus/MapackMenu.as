package Menus.StartMenus {
    import starling.display.Sprite;
    import Menus.TitleMenu;
    import starling.text.TextField;
    import starling.display.Image;
    import starling.events.Event;
    import starling.core.Starling;
    import UI.Component.MenuButton;
    import UI.Component.OptionButton;

    public class MapackMenu extends Sprite implements IMenu {

        private const COLOR:uint = 0xFF9DBB;

        private var components:Array;
        private var mapacks:Array;
        private var mapPage:int;

        private var title:TitleMenu;

        public function MapackMenu(title:TitleMenu):void {
            this.title = title;
            components = [];
            mapacks = [];
            init();
        }

        public function init():void {
            var text:TextField = new TextField(200, 40, "MAP MANAGER", "Downlink18", -1, COLOR);
            components.push(text);
            addLabel(text, 412, 122, "center");
            var btn:MenuButton = new MenuButton("btn_restart");
            btn.x = 604;
            btn.y = 124;
            btn.init();
            btn.addEventListener("clicked", on_refresh);
            components.push(btn);
            this.addChild(btn);
            btn = new MenuButton("tutorial_arrow");
            btn.x = 670;
            btn.y = 146;
            btn.image.rotation = Math.PI;
            btn.init();
            btn.setImage("tutorial_arrow", 0.75);
            btn.addEventListener("clicked", on_prev);
            components.push(btn);
            this.addChild(btn);
            btn = new MenuButton("tutorial_arrow");
            btn.x = 680;
            btn.y = 124;
            btn.init();
            btn.setImage("tutorial_arrow", 0.75);
            btn.addEventListener("clicked", on_next);
            components.push(btn);
            this.addChild(btn);
            on_refresh();
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

        public function hide():void {
            this.visible = false;
        }

        // #region 私有方法
        private function addLabel(label:TextField, x:Number, y:Number, hAlign:String = "right"):void {
            label.hAlign = hAlign;
            label.vAlign = "top";
            label.x = x;
            label.y = y;
            this.addChild(label);
        }

        private function on_refresh():void {
            LevelData.init();
            title.getBarrierData();
            title.getOrbitData();
            title.getMoreInfoTexts();
            title.levels.updateLevels();
            var dataQuad:OptionButton;
            if (mapacks.length != 0) {
                for each (dataQuad in mapacks) {
                    dataQuad.removeEventListener("clicked", on_choose_map);
                    this.removeChild(dataQuad);
                }
                mapacks = [];
            }
            var y:Number = 160;
            for (var i:int = 0; i < LevelData.rawData.length; i++) {
                dataQuad = new OptionButton(LevelData.rawData[i].name, COLOR, mapacks);
                dataQuad.label.fontName = "Downlink18";
                dataQuad.label.width = 700;
                dataQuad.label.x += 40;
                dataQuad.addLabel(new TextField(40, 40, "#" + i, "Downlink18", -1, COLOR), 0, 0);
                dataQuad.addLabel(new TextField(600, 40, LevelData.rawData[i].describe1, "Downlink12", -1, COLOR), 40, 25);
                if ("describe2" in LevelData.rawData[i])
                    dataQuad.addLabel(new TextField(600, 40, LevelData.rawData[i].describe2, "Downlink12", -1, COLOR), 40, 40);
                if ("describe3" in LevelData.rawData[i])
                    dataQuad.addLabel(new TextField(600, 40, LevelData.rawData[i].describe3, "Downlink12", -1, COLOR), 40, 55);
                if ("describe4" in LevelData.rawData[i])
                    dataQuad.addLabel(new TextField(600, 40, LevelData.rawData[i].describe4, "Downlink12", -1, COLOR), 40, 70);
                dataQuad.addLabel(new TextField(600, 40, "MAPPER: " + LevelData.rawData[i].mapper, "Downlink12", -1, COLOR), 40, 90);
                dataQuad.addImage(new Image(Root.assets.getTexture(LevelData.rawData[i].icon)));
                dataQuad.quad.color = 0x000000;
                dataQuad.quad.alpha = 0.5;
                dataQuad.quad.width = dataQuad.labelBG.width = 768;
                dataQuad.quad.height = dataQuad.labelBG.height = 120;
                dataQuad.x = 128;
                dataQuad.y = y;
                dataQuad.addEventListener("clicked", on_choose_map);
                mapacks.push(dataQuad);
                this.addChild(dataQuad);
                y += 125;
                if (y > 600)
                    y -= 500;
            }
            mapacks[Globals.currentData].toggle();
            if (mapacks.length <= 4){
                components[2].visible = components[3].visible = false;
                return
            }
            mapPage == 0 ? components[2].visible = false : components[2].visible = true;
            mapPage == Math.floor(mapacks.length / 4) ? components[3].visible = false : components[3].visible = true;
            for (i = 0; i < mapacks.length; i++) {
                mapPage * 4 <= i && i < mapPage * 4 + 4 ? mapacks[i].visible = true : mapacks[i].visible = false;
            }
        }

        private function on_choose_map(click:Event):void {
            Globals.currentData = mapacks.indexOf(click.target);
            Globals.save();
            LevelData.init();
            title.getBarrierData();
            title.getOrbitData();
            title.getMoreInfoTexts();
            title.levels.updateLevels();
            title.optionsMenu.animateOut();
        }

        private function on_prev(click:Event):void {
            if (mapPage > 0)
                mapPage--;
            on_refresh()
        }

        private function on_next(click:Event):void {
            if (mapPage < mapacks.length - 1)
                mapPage++;
            on_refresh()
        }
    }
}
