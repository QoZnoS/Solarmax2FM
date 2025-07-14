package Menus.StartMenus {
    import starling.display.Sprite;
    import Menus.TitleMenu;
    import starling.text.TextField;
    import starling.events.Event;
    import starling.core.Starling;
    import utils.GS;
    import UI.Component.OptionButton;

    public class StaffMenu extends Sprite implements IMenu {

        private const staffString:Array = [["ORIGINAL", "Downlink18"], ["DESIGN, ART, CODE:", "Downlink12"], ["NICO TUASON", "Downlink12"], ["MUSIC:", "Downlink12"], ["JOHN CAMARA", "Downlink12"], ["PLAYTESTING:", "Downlink12"], ["TERRY TUASON", "Downlink12"], ["MODIFIED", "Downlink18"], ["CODE:", "Downlink12"], ["QoZnoS", "Downlink12"], ["SPECIAL THANKS:", "Downlink18"], ["Solarmax23333", "Downlink12"], ["supercluster", "Downlink12"], ["Solarmax33", "Downlink12"], ["Thirdsister", "Downlink12"], ["Tuetiedove", "Downlink12"]]
        private const COLOR:uint = 0xFF9DBB;
        private const lineHeight:Number = 36;

        private var components:Array;
        private var title:TitleMenu;

        private var nicobtn:OptionButton;

        public function StaffMenu(_title:TitleMenu):void {
            this.title = _title;
            components = [];
            init();
        }

        public function init():void {
            for each (var _string:Array in staffString) {
                components.push(new TextField(400, 40, _string[0], _string[1], -1, COLOR));
            }
            var _y:Number = 120;
            var _side:int = 0;
            for (var i:int = 0; i < components.length; i++) {
                if (components[i].fontName == "Downlink18") {
                    addLabel(components[i], 312, _y, "center");
                    _y += lineHeight * 1.6;
                } else {
                    if (_side == 0) {
                        addLabel(components[i], 100, _y, "right");
                        _side = 1;
                        _y += lineHeight;
                    } else {
                        addLabel(components[i], 520, _y, "left");
                        _side = 0;
                    }
                }
                components[i].y = _y;
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

        private function addLabel(_label:TextField, _x:Number, _y:Number, _hAlign:String = "right"):void {
            _label.hAlign = _hAlign;
            _label.vAlign = "top";
            _label.x = _x;
            _label.y = _y;
            this.addChild(_label);
        }

        private var nicoClickTime:int = 0

        private function invisibleMode(_click:Event):void {
            if (title.currentIndex == 0)
                return;
            nicoClickTime += 1;
            nicobtn.label.color = uint(Math.random() * uint.MAX_VALUE)
            GS.playClick()
            if (nicoClickTime == 5) {
                nicoClickTime = 0;
                nicobtn.label.color = COLOR;
                title.on_menu(null);
                // 以隐形模式进入关卡...
                title.loadMap();
                title.scene.gameScene.invisibleMode();
            }
        }
    }
}
