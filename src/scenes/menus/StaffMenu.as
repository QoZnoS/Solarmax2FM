package scenes.menus {
    import managers.AudioManager;

    import scenes.TitleMenu;

    import starling.core.Starling;
    import starling.display.Sprite;
    import starling.events.Event;

    import ui.UIContainer;
    import ui.components.OptionButton;
    import starling.utils.Align;
    import starling.text.TextFormat;
    import utils.ShadowLabel;
    import i18n.I18n;

    public class StaffMenu extends Sprite implements IMenu {
        private var staffString:Array; // [text, fontSize, isI18nKey] 元组
        private const COLOR:uint = 0xFF9DBB;
        private const lineHeight:Number = 36;

        private var components:Array;
        private var title:TitleMenu;

        private var nicobtn:OptionButton;

        public function StaffMenu(title:TitleMenu):void {
            this.title = title;
            components = [];
            I18n.addEventListener(Event.CHANGE, on_languageChanged);
            init();
        }

        /** 构建 staffString 数组：三元组 [text, fontSize, i18nKey|null] */
        private function _buildStaffStrings():void {
            staffString = [
                [I18n._("staff.original"), 18, "staff.original"],
                [I18n._("staff.design"), 12, "staff.design"],
                ["NICO TUASON", 12, null],
                [I18n._("staff.music"), 12, "staff.music"],
                ["JOHN CAMARA", 12, null],
                [I18n._("staff.playtesting"), 12, "staff.playtesting"],
                ["TERRY TUASON", 12, null],
                [I18n._("staff.modified"), 18, "staff.modified"],
                [I18n._("staff.code"), 12, "staff.code"],
                ["QoZnoS", 12, null],
                [I18n._("staff.thanks"), 18, "staff.thanks"],
                ["Solarmax23333", 12, null],
                ["supercluster", 12, null],
                ["Solarmax33", 12, null],
                [I18n._("staff.thirdsister"), 12, "staff.thirdsister"],
                ["Tuetiedove", 12, null],
                ["林中散步", 12, null]
            ];
        }

        public function init():void {
            _buildStaffStrings();
            for each (var strings:Array in staffString) {
                components.push(new ShadowLabel(400, 40, strings[0], new TextFormat("downlink", strings[1], COLOR)));
            }
            var y:Number = 120;
            var side:int = 0;
            for (var i:int = 0; i < components.length; i++) {
                if (components[i].format.size == 18) {
                    addLabel(components[i], 312, y, "center");
                    y += lineHeight * 1.6;
                } else {
                    if (side == 0) {
                        addLabel(components[i], 100, y, "right");
                        side = 1;
                        y += lineHeight;
                    } else {
                        addLabel(components[i], 520, y, "left");
                        side = 0;
                    }
                }
                components[i].y = y;
                if (components[i].text == "NICO TUASON") {
                    nicobtn = new OptionButton("NICO TUASON", COLOR, null);
                    nicobtn.x = components[i].x;
                    nicobtn.y = components[i].y;
                    components[i].visible = false;
                    nicobtn.addEventListener("clicked", invisibleMode);
                    this.addChild(nicobtn);

                }
            }
        }

        public function deinit():void {
            throw new Error("Method not implemented.");
        }

        public function animateIn():void {
            this.visible = true;

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

        private function addLabel(label:ShadowLabel, x:Number, y:Number, hAlign:String = Align.RIGHT):void {
            label.format.horizontalAlign = hAlign;
            label.format.verticalAlign = Align.TOP;
            label.x = x;
            label.y = y;
            this.addChild(label);
        }

        private var nicoClickTime:int = 0;

        private function on_languageChanged(e:Event):void {
            _buildStaffStrings();
            for (var i:int = 0; i < staffString.length; i++)
                if (i < components.length)
                    components[i].text = staffString[i][0];
            if (nicobtn)
                nicobtn.label.text = "NICO TUASON";
        }

        private function invisibleMode(click:Event):void {
            if (title.currentIndex == 0)
                return;
            nicoClickTime += 1;
            nicobtn.label.format.color = uint(Math.random() * uint.MAX_VALUE);
            AudioManager.playClick();

            if (nicoClickTime == 5) {
                nicoClickTime = 0;
                nicobtn.label.format.color = COLOR;
                title.on_menu(null);
                title.loadMap();
                UIContainer.invisibleMode();
            }
        }
    }
}
