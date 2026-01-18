package Menus.StartMenus {
    import starling.display.Sprite;
    import starling.text.TextField;
    import starling.events.Event;
    import starling.core.Starling;
    import Menus.TitleMenu;
    import starling.events.TouchEvent;
    import starling.events.Touch;
    import starling.events.EnterFrameEvent;
    import utils.GS;
    import UI.Component.OptionButton;
    import UI.Component.OptionSlider;
    import UI.Component.Tooltip;

    public class SettingMenu extends Sprite implements IMenu {

        private const windowStrings:Array = ["FULLSCREEN", "RESIZEABLE WINDOW"]; // 窗口模式文本
        private const aaStrings:Array = ["0x", "2x", "4x", "8x", "16x"]; // 抗锯齿文本
        private const sizeStrings:Array = ["SMALL", "MEDIUM", "LARGE"]; // 字体大小文本
        private const controlStrings:Array = ["MULTI-TOUCH", "TRADITIONAL"]; // 控制方式文本
        private const fleetSliderPositionStrings:Array = ["LEFT", "DOWN", "RIGHT"]; // 分兵条位置
        private const yesORno:Array = ["YES", "NO"];
        private const COLOR:uint = 0xFF9DBB;

        private var fullscreen:Array;
        private var antialias:Array;
        private var textsizes:Array;
        private var controls:Array;
        private var fleetSliderPositions:Array;
        private var blackBorders:Array; // 黑边
        private var pauseAllows:Array; // 允许暂停
        private var audioSlider:OptionSlider;
        private var musicSlider:OptionSlider;
        private var satSlider:OptionSlider;
        private var resetBtn:OptionButton;
        private var resetBtn2:OptionButton;
        private var exitBtn:OptionButton;
        private var tooltip1:Tooltip;
        private var tooltip2:Tooltip;

        private var components:Array;

        private var title:TitleMenu;

        public function SettingMenu(title:TitleMenu) {
            this.title = title
            init()
        }

        public function init():void {
            var i:int;
            var btn:OptionButton;
            // #region VIDEO
            components = []
            components.push(new TextField(200, 40, "VIDEO", "Downlink18", -1, COLOR));
            if (Globals.device == "PC")
                components.push(new TextField(200, 40, "WINDOW MODE:", "Downlink12", -1, COLOR));
            fullscreen = [];
            for (i = 0; i < windowStrings.length; i++) {
                btn = new OptionButton(windowStrings[i], COLOR, fullscreen);
                btn.x = 330 + i * 140;
                btn.addEventListener("clicked", on_fullscreen);
                fullscreen.push(btn);
                if (Globals.device == "PC")
                    components.push(fullscreen);
            }
            components.push(new TextField(200, 40, "ANTI-ALIASING:", "Downlink12", -1, COLOR));
            antialias = [];
            for (i = 0; i < aaStrings.length; i++) {
                btn = new OptionButton(aaStrings[i], COLOR, antialias);
                btn.x = 330 + i * 60;
                btn.addEventListener("clicked", on_antialias);
                antialias.push(btn);
                components.push(antialias);
            }
            // #endregion
            // #region AUDIO
            components.push(new TextField(200, 40, "AUDIO", "Downlink18", -1, COLOR));
            components.push(new TextField(200, 40, "MUSIC VOLUME:", "Downlink12", -1, COLOR));
            musicSlider = new OptionSlider(1);
            musicSlider.x = 330;
            musicSlider.init();
            components.push(musicSlider);
            components.push(new TextField(200, 40, "SOUND VOLUME:", "Downlink12", -1, COLOR));
            audioSlider = new OptionSlider(1);
            audioSlider.x = 330;
            audioSlider.init();
            components.push(audioSlider);
            // #endregion
            // #region GAME
            components.push(new TextField(200, 40, "V1.2.0    GAME", "Downlink18", -1, COLOR));
            components.push(new TextField(200, 40, "UI SIZE:", "Downlink12", -1, COLOR));
            textsizes = [];
            for (i = 0; i < sizeStrings.length; i++) {
                btn = new OptionButton(sizeStrings[i], COLOR, textsizes);
                btn.x = 330 + i * 90;
                btn.addEventListener("clicked", on_textsize);
                textsizes.push(btn);
            }
            components.push(textsizes);
            components.push(new TextField(200, 40, "CONTROL METHOD:", "Downlink12", -1, COLOR));
            controls = [];
            for (i = 0; i < controlStrings.length; i++) {
                btn = new OptionButton(controlStrings[i], COLOR, controls);
                btn.x = 330 + i * 130;
                btn.addEventListener("clicked", on_controls);
                controls.push(btn);
            }
            components.push(controls);
            components.push(new TextField(200, 40, "FLEETSLIDER POSITION:", "Downlink12", -1, COLOR));
            fleetSliderPositions = [];
            for (i = 0; i < fleetSliderPositionStrings.length; i++) {
                btn = new OptionButton(fleetSliderPositionStrings[i], COLOR, fleetSliderPositions);
                btn.x = 330 + i * 90;
                btn.addEventListener("clicked", on_fleetSliderPosition);
                fleetSliderPositions.push(btn);
            }
            components.push(fleetSliderPositions);
            components.push(new TextField(200, 40, "BLACK BORDER:", "Downlink12", -1, COLOR));
            blackBorders = [];
            for (i = 0; i < yesORno.length; i++) {
                btn = new OptionButton(yesORno[i], COLOR, blackBorders);
                btn.x = 330 + i * 90;
                btn.addEventListener("clicked", on_blackBorder);
                blackBorders.push(btn);
            }
            components.push(blackBorders);
            components.push(new TextField(200, 40, "ALLOW PAUSE:", "Downlink12", -1, COLOR));
            pauseAllows = [];
            for (i = 0; i < yesORno.length; i++) {
                btn = new OptionButton(yesORno[i], COLOR, pauseAllows);
                btn.x = 330 + i * 90;
                btn.addEventListener("clicked", on_pauseAllow);
                pauseAllows.push(btn);
            }
            components.push(pauseAllows);
            components.push(new TextField(200, 40, "SAVE FILE:", "Downlink12", -1, COLOR));
            resetBtn = new OptionButton("RESET PROGRESS", 16742263, null);
            resetBtn.x = 330;
            resetBtn.addEventListener("clicked", on_show_reset);
            components.push(resetBtn);
            resetBtn2 = new OptionButton("CONFIRM?", 16720418, null);
            resetBtn2.x = 330 + resetBtn.width - 60;
            resetBtn2.addEventListener("clicked", on_reset);
            resetBtn2.touchable = false;
            components.push(resetBtn2);
            exitBtn = new OptionButton("EXIT GAME", COLOR, null);
            exitBtn.x = 660;
            exitBtn.addEventListener("clicked", title.on_quit);
            components.push(exitBtn);
            // #endregion
            // #region 添加实例化对象
            var y:Number = 100;
            var lineHeight:Number = 540 / components.length * 2
            for (i = 0; i < components.length; i++) {
                if (components[i] is TextField) {
                    addLabel(components[i], 100, y);
                    components[i].fontName == "Downlink18" ? y += lineHeight * 1.25 : y += lineHeight;
                    components[i].y = y;
                } else if (components[i] is Array) {
                    for (var j:int = 0; j < components[i].length; j++) {
                        components[i][j].y = y;
                        this.addChild(components[i][j]);
                    }
                } else {
                    components[i].y = y;
                    this.addChild(components[i]);
                }
            }
            // #endregion        
            tooltip1 = new Tooltip(0);
            tooltip1.visible = false;
            tooltip1.x = controls[0].x;
            tooltip1.y = controls[0].y;
            addChild(tooltip1);
            controls[0].quad.addEventListener("touch", on_tooltip1);
            tooltip2 = new Tooltip(1);
            tooltip2.visible = false;
            tooltip2.x = controls[1].x;
            tooltip2.y = controls[1].y;
            addChild(tooltip2);
            controls[1].quad.addEventListener("touch", on_tooltip2);
        }

        public function deinit():void {
            throw new Error("Method not implemented.");
        }

        public function animateIn():void {
            Globals.fullscreen ? fullscreen[0].toggle() : fullscreen[1].toggle();
            Globals.touchControls ? controls[0].toggle() : controls[1].toggle();
            antialias[Globals.antialias].toggle();
            textsizes[Globals.textSize].toggle();
            fleetSliderPositions[Globals.fleetSliderPosition].toggle();
            audioSlider.total = Globals.soundVolume;
            musicSlider.total = Globals.musicVolume;
            Globals.blackQuad ? blackBorders[0].toggle() : blackBorders[1].toggle();
            Globals.nohup ? pauseAllows[1].toggle() : pauseAllows[0].toggle();
            Starling.juggler.removeTweens(resetBtn2);
            resetBtn2.alpha = 0;
            resetBtn2.touchable = false;
            audioSlider.update();
            musicSlider.update();
            this.visible = true
            Starling.juggler.removeTweens(this);
            Starling.juggler.tween(this, 0.15, {"alpha": 1});
            addEventListener("enterFrame", update);
        }

        public function animateOut():void {
            Starling.juggler.removeTweens(this);
            Starling.juggler.tween(this, 0.15, {"alpha": 0,
                    "onComplete": hide});
            removeEventListener("enterFrame", update);
        }

        public function hide():void {
            this.visible = false;
        }

        //#region 私有方法
        private function addLabel(label:TextField, x:Number, y:Number, hAlign:String = "right"):void {
            label.hAlign = hAlign;
            label.vAlign = "top";
            label.x = x;
            label.y = y;
            this.addChild(label);
        }

        private function update(e:EnterFrameEvent):void {
            Globals.soundVolume = audioSlider.total;
            Globals.musicVolume = musicSlider.total;
            GS.updateTransforms();
        }

        private function on_fullscreen(click:Event):void {
            fullscreen.indexOf(click.target) == 0 ? Globals.fullscreen = true : Globals.fullscreen = false;
            Globals.main.on_fullscreen();
        }

        private function on_antialias(click:Event):void {
            Globals.antialias = antialias.indexOf(click.target);
        }

        private function on_textsize(click:Event):void {
            Globals.textSize = textsizes.indexOf(click.target);
            title.on_resize();
        }

        private function on_controls(click:Event):void {
            controls.indexOf(click.target) == 0 ? Globals.touchControls = true : Globals.touchControls = false;
        }

        private function on_fleetSliderPosition(click:Event):void {
            Globals.fleetSliderPosition = fleetSliderPositions.indexOf(click.target);
        }

        private function on_show_reset(click:Event):void {
            Starling.juggler.tween(resetBtn2, 0.5, {"alpha": 1});
            resetBtn2.touchable = true;
        }

        private function on_reset(click:Event):void {
            title.on_reset();
            title.optionsMenu.animateOut();
        }

        private function on_blackBorder(click:Event):void {
            blackBorders.indexOf(click.target) == 0 ? Globals.blackQuad = true : Globals.blackQuad = false;
            title.scene.updateBlackQuad()
        }

        private function on_pauseAllow(click:Event):void {
            pauseAllows.indexOf(click.target) == 0 ? Globals.nohup = false : Globals.nohup = true;
        }

        private function on_tooltip1(touchEvent:TouchEvent):void {
            var touch:Touch = touchEvent.getTouch(controls[0].quad);
            if (!touch) {
                tooltip1.visible = false;
                return;
            }
            if (touch.phase == "hover")
                tooltip1.visible = true;
        }

        private function on_tooltip2(touchEvent:TouchEvent):void {
            var touch:Touch = touchEvent.getTouch(controls[1].quad);
            if (!touch) {
                tooltip2.visible = false;
                return;
            }
            if (touch.phase == "hover")
                tooltip2.visible = true;
        }
        //#endregion
    }
}
