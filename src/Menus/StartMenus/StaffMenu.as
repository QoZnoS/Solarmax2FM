package Menus.StartMenus {
    import starling.display.Sprite;
    import Menus.TitleMenu;
    import starling.text.TextField;
    import starling.events.Event;
    import starling.core.Starling;
    import utils.GS;
    import UI.Component.OptionButton;
    import UI.UIContainer;

    public class StaffMenu extends Sprite implements IMenu {

        private const staffString:Array = [["ORIGINAL", "Downlink18"], ["DESIGN, ART, CODE:", "Downlink12"], ["NICO TUASON", "Downlink12"], ["MUSIC:", "Downlink12"], ["JOHN CAMARA", "Downlink12"], ["PLAYTESTING:", "Downlink12"], ["TERRY TUASON", "Downlink12"], ["MODIFIED", "Downlink18"], ["CODE:", "Downlink12"], ["QoZnoS", "Downlink12"], ["SPECIAL THANKS:", "Downlink18"], ["Solarmax23333", "Downlink12"], ["supercluster", "Downlink12"], ["Solarmax33", "Downlink12"], ["Thirdsister", "Downlink12"], ["Tuetiedove", "Downlink12"], ["LinZhong", "Downlink12"]]
        private const COLOR:uint = 0xFF9DBB;
        private const lineHeight:Number = 36;

        private var components:Array;
        private var title:TitleMenu;

        private var nicobtn:OptionButton;

        public function StaffMenu(title:TitleMenu):void {
            this.title = title;
            components = [];
            init();
        }

        public function init():void {
            for each (var strings:Array in staffString) {
                components.push(new TextField(400, 40, strings[0], strings[1], -1, COLOR));
            }
            var y:Number = 120;
            var side:int = 0;
            for (var i:int = 0; i < components.length; i++) {
                if (components[i].fontName == "Downlink18") {
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
                    nicobtn = new OptionButton("NICO TUASON", COLOR, null)
                    nicobtn.x = components[i].x
                    nicobtn.y = components[i].y
                    components[i].visible = false
                    nicobtn.addEventListener("clicked", invisibleMode)
                    this.addChild(nicobtn)
                }
            }
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

        private function addLabel(label:TextField, x:Number, y:Number, hAlign:String = "right"):void {
            label.hAlign = hAlign;
            label.vAlign = "top";
            label.x = x;
            label.y = y;
            this.addChild(label);
        }

        private var nicoClickTime:int = 0

        private function invisibleMode(click:Event):void {
            if (title.currentIndex == 0)
                return;
            nicoClickTime += 1;
            nicobtn.label.color = uint(Math.random() * uint.MAX_VALUE)
            GS.playClick()
            if (nicoClickTime == 5) {
                nicoClickTime = 0;
                nicobtn.label.color = COLOR;
                title.on_menu(null);
                title.loadMap();
                UIContainer.invisibleMode();
            }
        }
    }
}
