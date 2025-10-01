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

        public function MapackMenu(_title:TitleMenu):void {
            this.title = _title;
            components = [];
            mapacks = [];
            init();
        }

        public function init():void {
            var _text:TextField = new TextField(200, 40, "MAP MANAGER", "Downlink18", -1, COLOR);
            components.push(_text);
            addLabel(_text, 412, 122, "center");
            var _btn:MenuButton = new MenuButton("btn_restart");
            _btn.x = 604;
            _btn.y = 124;
            _btn.init();
            _btn.addEventListener("clicked", on_refresh);
            components.push(_btn);
            this.addChild(_btn);
            _btn = new MenuButton("tutorial_arrow");
            _btn.x = 670;
            _btn.y = 146;
            _btn.image.rotation = Math.PI;
            _btn.init();
            _btn.setImage("tutorial_arrow", 0.75);
            _btn.addEventListener("clicked", on_prev);
            components.push(_btn);
            this.addChild(_btn);
            _btn = new MenuButton("tutorial_arrow");
            _btn.x = 680;
            _btn.y = 124;
            _btn.init();
            _btn.setImage("tutorial_arrow", 0.75);
            _btn.addEventListener("clicked", on_next);
            components.push(_btn);
            this.addChild(_btn);
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
        private function addLabel(_label:TextField, _x:Number, _y:Number, _hAlign:String = "right"):void {
            _label.hAlign = _hAlign;
            _label.vAlign = "top";
            _label.x = _x;
            _label.y = _y;
            this.addChild(_label);
        }

        private function on_refresh():void {
            LevelData.init();
            title.getBarrierData();
            title.getOrbitData();
            title.getMoreInfoTexts();
            title.levels.updateLevels();
            var _dataQuad:OptionButton;
            if (mapacks.length != 0) {
                for each (_dataQuad in mapacks) {
                    _dataQuad.removeEventListener("clicked", on_choose_map);
                    this.removeChild(_dataQuad);
                }
                mapacks = [];
            }
            var _y:Number = 160;
            for (var i:int = 0; i < LevelData.rawData.length; i++) {
                _dataQuad = new OptionButton(LevelData.extensions.data.(@id == i).@name, COLOR, mapacks);
                _dataQuad.label.fontName = "Downlink18";
                _dataQuad.label.width = 700;
                _dataQuad.label.x += 40;
                _dataQuad.addLabel(new TextField(40, 40, "#" + i, "Downlink18", -1, COLOR), 0, 0);
                _dataQuad.addLabel(new TextField(600, 40, LevelData.extensions.data.(@id == i).@describe1, "Downlink12", -1, COLOR), 40, 25);
                if (LevelData.extensions.data.(@id == i).@describe2 != undefined)
                    _dataQuad.addLabel(new TextField(600, 40, LevelData.extensions.data.(@id == i).@describe2, "Downlink12", -1, COLOR), 40, 40);
                if (LevelData.extensions.data.(@id == i).@describe3 != undefined)
                    _dataQuad.addLabel(new TextField(600, 40, LevelData.extensions.data.(@id == i).@describe3, "Downlink12", -1, COLOR), 40, 55);
                if (LevelData.extensions.data.(@id == i).@describe4 != undefined)
                    _dataQuad.addLabel(new TextField(600, 40, LevelData.extensions.data.(@id == i).@describe4, "Downlink12", -1, COLOR), 40, 70);
                _dataQuad.addLabel(new TextField(600, 40, "MAPPER: " + LevelData.rawData[i].mapper, "Downlink12", -1, COLOR), 40, 90);
                _dataQuad.addImage(new Image(Root.assets.getTexture(LevelData.extensions.data.(@id == i).@icon)));
                _dataQuad.quad.color = 0x000000;
                _dataQuad.quad.alpha = 0.5;
                _dataQuad.quad.width = _dataQuad.labelBG.width = 768;
                _dataQuad.quad.height = _dataQuad.labelBG.height = 120;
                _dataQuad.x = 128;
                _dataQuad.y = _y;
                _dataQuad.addEventListener("clicked", on_choose_map);
                mapacks.push(_dataQuad);
                this.addChild(_dataQuad);
                _y += 125;
                if (_y > 600)
                    _y -= 500;
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

        private function on_choose_map(_click:Event):void {
            Globals.currentData = mapacks.indexOf(_click.target);
            Globals.save();
            LevelData.init();
            title.getBarrierData();
            title.getOrbitData();
            title.getMoreInfoTexts();
            title.levels.updateLevels();
            title.optionsMenu.animateOut();
        }

        private function on_prev(_click:Event):void {
            if (mapPage > 0)
                mapPage--;
        }

        private function on_next(_click:Event):void {
            if (mapPage < mapacks.length - 1)
                mapPage++;
        }
    }
}
