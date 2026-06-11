package scenes.menus {
    import managers.AudioManager;
    import managers.Globals;

    import scenes.TitleMenu;

    import starling.core.Starling;
    import starling.display.Sprite;
    import starling.events.EnterFrameEvent;
    import starling.events.Event;
    import starling.events.Touch;
    import starling.events.TouchEvent;

    import ui.components.OptionButton;
    import ui.components.OptionSlider;
    import ui.components.Tooltip;
    import managers.SaveManager;
    import starling.text.TextFormat;
    import starling.utils.Align;
    import utils.ShadowLabel;
    import i18n.I18n;

    public class SettingMenu extends Sprite implements IMenu {
        private var windowStrings:Array; // 窗口模式文本
        private const aaStrings:Array = ["0x", "2x", "4x", "8x", "16x"]; // 抗锯齿文本（无翻译）
        private var sizeStrings:Array; // 字体大小文本
        private var languageStrings:Array; // 可用语言
        private var controlStrings:Array; // 控制方式文本
        private var fleetSliderPositionStrings:Array; // 分兵条位置
        private var yesORno:Array;
        private const COLOR:uint = 0xFF9DBB;

        private var fullscreen:Array;
        private var antialias:Array;
        private var textsizes:Array;
        private var languages:Array;
        private var controls:Array;
        private var fleetSliderPositions:Array;
        private var audioSlider:OptionSlider;
        private var musicSlider:OptionSlider;
        private var satSlider:OptionSlider;
        private var resetBtn:OptionButton;
        private var resetBtn2:OptionButton;
        private var exitBtn:OptionButton;
        private var tooltip1:Tooltip;
        private var tooltip2:Tooltip;

        private var components:Array;
        /** 所有使用了 I18n 的 ShadowLabel 引用 */
        private var _i18nLabels:Vector.<ShadowLabel>;
        private var _i18nLabelCode:Vector.<String>;
        /** 所有使用了 I18n 的 OptionButton 组 */
        private var _i18nButtonGroups:Array;

        private var title:TitleMenu;

        public function SettingMenu(title:TitleMenu) {
            this.title = title;
            _i18nLabels = new Vector.<ShadowLabel>();
            _i18nLabelCode = new Vector.<String>();
            _i18nButtonGroups = [];
            I18n.addEventListener(Event.CHANGE, on_languageChanged);
            init();
        }

        /** 初始化所有可变字符串数组（语言切换时也会调用） */
        private function _initStrings():void {
            windowStrings = [I18n._("setting.fullscreen"), I18n._("setting.resizable")];
            sizeStrings = [I18n._("setting.small"), I18n._("setting.medium"), I18n._("setting.large")];
            languageStrings = I18n.availableLanguages;
            controlStrings = [I18n._("setting.multitouch"), I18n._("setting.traditional")];
            fleetSliderPositionStrings = [I18n._("setting.left"), I18n._("setting.down"), I18n._("setting.right")];
            yesORno = [I18n._("game.yes"), I18n._("game.no")];
        }

        /** 添加一个 i18n 标签并记录引用 */
        private function _addI18nLabel(w:int, h:int, key:String, fmt:TextFormat):ShadowLabel {
            var label:ShadowLabel = new ShadowLabel(w, h, I18n._(key), fmt);
            _i18nLabels.push(label);
            _i18nLabelCode.push(key);
            return label;
        }

        public function init():void {
            var i:int;
            var btn:OptionButton;
            _i18nLabels.length = 0;
            _i18nLabelCode.length = 0;
            _i18nButtonGroups.length = 0;
            _initStrings();
            // #region VIDEO
            components = [];
            components.push(_addI18nLabel(200, 40, "setting.video", new TextFormat("downlink", 18, COLOR)));
            if (Globals.device == "PC")
                components.push(_addI18nLabel(200, 40, "setting.windowMode", new TextFormat("downlink", 12, COLOR)));
            fullscreen = [];
            for (i = 0; i < windowStrings.length; i++) {
                btn = new OptionButton(windowStrings[i], COLOR, fullscreen);
                btn.x = 330 + i * 140;
                btn.addEventListener("clicked", on_fullscreen);
                fullscreen.push(btn);
                // if (Globals.device == "PC")
                components.push(fullscreen);
            }
            _i18nButtonGroups.push({keys: ["setting.fullscreen", "setting.resizable"], btns: fullscreen});
            components.push(_addI18nLabel(200, 40, "setting.language", new TextFormat("downlink", 12, COLOR)));
            languages = [];
            for (i = 0; i < languageStrings.length; i++) {
                btn = new OptionButton(languageStrings[i], COLOR, languages);
                btn.x = 330 + i * 140;
                btn.addEventListener("clicked", on_language);
                languages.push(btn);
                components.push(languages);
            }
            _i18nButtonGroups.push({keys: null, btns: languages});
            components.push(_addI18nLabel(200, 40, "setting.antialias", new TextFormat("downlink", 12, COLOR)));
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
            components.push(_addI18nLabel(200, 40, "setting.audio", new TextFormat("downlink", 18, COLOR)));
            components.push(_addI18nLabel(200, 40, "setting.musicVol", new TextFormat("downlink", 12, COLOR)));
            musicSlider = new OptionSlider(1);
            musicSlider.x = 330;
            musicSlider.init();
            components.push(musicSlider);
            components.push(_addI18nLabel(200, 40, "setting.soundVol", new TextFormat("downlink", 12, COLOR)));
            audioSlider = new OptionSlider(1);
            audioSlider.x = 330;
            audioSlider.init();
            components.push(audioSlider);
            // #endregion
            // #region GAME
            components.push(_addI18nLabel(200, 40, "setting.game", new TextFormat("downlink", 18, COLOR)));
            components.push(_addI18nLabel(200, 40, "setting.uiSize", new TextFormat("downlink", 12, COLOR)));
            textsizes = [];
            for (i = 0; i < sizeStrings.length; i++) {
                btn = new OptionButton(sizeStrings[i], COLOR, textsizes);
                btn.x = 330 + i * 90;
                btn.addEventListener("clicked", on_textsize);
                textsizes.push(btn);
            }
            components.push(textsizes);
            _i18nButtonGroups.push({keys: ["setting.small", "setting.medium", "setting.large"], btns: textsizes});
            components.push(_addI18nLabel(200, 40, "setting.control", new TextFormat("downlink", 12, COLOR)));
            controls = [];
            for (i = 0; i < controlStrings.length; i++) {
                btn = new OptionButton(controlStrings[i], COLOR, controls);
                btn.x = 330 + i * 130;
                btn.addEventListener("clicked", on_controls);
                controls.push(btn);
            }
            components.push(controls);
            _i18nButtonGroups.push({keys: ["setting.multitouch", "setting.traditional"], btns: controls});
            components.push(_addI18nLabel(200, 40, "setting.fleetPos", new TextFormat("downlink", 12, COLOR)));
            fleetSliderPositions = [];
            for (i = 0; i < fleetSliderPositionStrings.length; i++) {
                btn = new OptionButton(fleetSliderPositionStrings[i], COLOR, fleetSliderPositions);
                btn.x = 330 + i * 90;
                btn.addEventListener("clicked", on_fleetSliderPosition);
                fleetSliderPositions.push(btn);
            }
            components.push(fleetSliderPositions);
            _i18nButtonGroups.push({keys: ["setting.left", "setting.down", "setting.right"], btns: fleetSliderPositions});
            components.push(_addI18nLabel(200, 40, "setting.saveFile", new TextFormat("downlink", 12, COLOR)));
            resetBtn = new OptionButton(I18n._("setting.resetProgress"), 0xFF7777, null);
            resetBtn.x = 330;
            resetBtn.addEventListener("clicked", on_show_reset);
            components.push(resetBtn);
            resetBtn2 = new OptionButton(I18n._("setting.confirm"), 0xFF2222, null);
            resetBtn2.x = 330 + resetBtn.width - 60;
            resetBtn2.addEventListener("clicked", on_reset);
            resetBtn2.touchable = false;
            components.push(resetBtn2);
            exitBtn = new OptionButton(I18n._("setting.exitGame"), COLOR, null);
            exitBtn.x = 660;
            exitBtn.addEventListener("clicked", title.on_quit);
            components.push(exitBtn);
            // #endregion
            // #region 添加实例化对象
            var y:Number = 100;
            var lineHeight:Number = 540 / components.length * 2;
            for (i = 0; i < components.length; i++) {
                if (components[i] is ShadowLabel) {
                    addLabel(components[i], 100, y);
                    components[i].format.size == 18 ? y += lineHeight * 1.25 : y += lineHeight;
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
            tooltip1 = new Tooltip();
            tooltip1.visible = false;
            tooltip1.x = controls[0].x;
            tooltip1.y = controls[0].y;
            addChild(tooltip1);
            tooltip1.title = I18n._("tooltip.multitouch.title");
            tooltip1.content = I18n._("tooltip.multitouch.content");
            controls[0].quad.addEventListener("touch", on_tooltip1);
            tooltip2 = new Tooltip();
            tooltip2.visible = false;
            tooltip2.x = controls[1].x;
            tooltip2.y = controls[1].y;
            addChild(tooltip2);
            tooltip2.title = I18n._("tooltip.traditional.title");
            tooltip2.content = I18n._("tooltip.traditional.content");
            controls[1].quad.addEventListener("touch", on_tooltip2);
        }

        public function deinit():void {
            throw new Error("Method not implemented.");
        }

        public function animateIn():void {
            SaveManager.fullscreen ? fullscreen[0].toggle() : fullscreen[1].toggle();
            SaveManager.touchControls ? controls[0].toggle() : controls[1].toggle();
            antialias[SaveManager.antialias].toggle();
            textsizes[SaveManager.textSize].toggle();
            languages[I18n.getLanguageIDByRegisteCode(SaveManager.languages)].toggle();
            fleetSliderPositions[SaveManager.fleetSliderPosition].toggle();
            audioSlider.total = SaveManager.soundVolume;
            musicSlider.total = SaveManager.musicVolume;
            Starling.juggler.removeTweens(resetBtn2);
            resetBtn2.alpha = 0;
            resetBtn2.touchable = false;
            audioSlider.update();
            musicSlider.update();
            this.visible = true;
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

        // #region 私有方法
        private function addLabel(label:ShadowLabel, x:Number, y:Number, hAlign:String = Align.RIGHT):void {
            label.format.horizontalAlign = hAlign;
            label.format.verticalAlign = Align.TOP;
            label.x = x;
            label.y = y;
            this.addChild(label);
        }

        private function update(e:EnterFrameEvent):void {
            SaveManager.soundVolume = audioSlider.total;
            SaveManager.musicVolume = musicSlider.total;
            AudioManager.updateTransforms();
        }

        private function on_fullscreen(click:Event):void {
            fullscreen.indexOf(click.target) == 0 ? SaveManager.fullscreen = true : SaveManager.fullscreen = false;
            Globals.main.on_fullscreen();
        }

        private function on_antialias(click:Event):void {
            SaveManager.antialias = antialias.indexOf(click.target);
        }

        private function on_textsize(click:Event):void {
            SaveManager.textSize = textsizes.indexOf(click.target);
            title.on_resize();
        }

        private function on_language(click:Event):void {
            I18n.setLocale(I18n.getLanguageCodeByRegisteID(languages.indexOf(click.target)));
        }

        /** 语言变更回调 — 刷新所有文本 */
        private function on_languageChanged(e:Event):void {
            refreshTexts();
            languages[I18n.getLanguageIDByRegisteCode(SaveManager.languages)].toggle();
        }

        /** 刷新所有使用 I18n 的文本 */
        public function refreshTexts():void {
            _initStrings();
            // 刷新所有标签文本
            for (var i:int = 0; i < _i18nLabels.length; i++)
                _i18nLabels[i].text = I18n._(_i18nLabelCode[i]);
            // 刷新按钮组
            for each (var group:Object in _i18nButtonGroups) {
                var btns:Array = group.btns;
                var keys:Array = group.keys;
                if (keys) {
                    for (i = 0; i < btns.length; i++) {
                        btns[i].label.text = I18n._(keys[i]);
                        btns[i].resizeToText();
                    }
                } else {
                    // language 按钮（显示 displayName）
                    for (i = 0; i < btns.length; i++) {
                        btns[i].label.text = languageStrings[i];
                        btns[i].resizeToText();
                    }
                }
            }
            // 单独按钮
            resetBtn.label.text = I18n._("setting.resetProgress");
            resetBtn.resizeToText();
            resetBtn2.label.text = I18n._("setting.confirm");
            resetBtn2.resizeToText();
            exitBtn.label.text = I18n._("setting.exitGame");
            exitBtn.resizeToText();
            tooltip1.title = I18n._("tooltip.multitouch.title");
            tooltip1.content = I18n._("tooltip.multitouch.content");
            tooltip2.title = I18n._("tooltip.traditional.title");
            tooltip2.content = I18n._("tooltip.traditional.content");
        }

        private function on_controls(click:Event):void {
            controls.indexOf(click.target) == 0 ? SaveManager.touchControls = true : SaveManager.touchControls = false;
        }

        private function on_fleetSliderPosition(click:Event):void {
            SaveManager.fleetSliderPosition = fleetSliderPositions.indexOf(click.target);
        }

        private function on_show_reset(click:Event):void {
            Starling.juggler.tween(resetBtn2, 0.5, {"alpha": 1});
            resetBtn2.touchable = true;
        }

        private function on_reset(click:Event):void {
            title.on_reset();
            title.optionsMenu.animateOut();
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
        // #endregion
    }
}
