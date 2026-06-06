package scenes.menus {
    import managers.SaveManager;

    import starling.core.Starling;
    import starling.display.Sprite;
    import starling.events.EnterFrameEvent;
    import starling.events.Event;

    import ui.components.OptionButton;
    import ui.components.OptionSlider;

    import starling.utils.Align;
    import utils.ShadowLabel;
    import starling.text.TextFormat;

    public class AdvancedSettingMenu extends Sprite implements IMenu {
        // ========== 布局常量 ==========
        private const START_X:Number = 172; // 标签起始X
        private const LABEL_WIDTH:Number = 200; // 标签宽度
        private const CONTROL_X:Number = 402; // 控件起始X
        private const START_Y:Number = 136; // 起始Y坐标
        private const LINE_HEIGHT:Number = 40; // 行高
        private const BTN_Y_FIX:Number = 12;

        private const COLOR:uint = 0xFF9DBB;
        private const YES_NO:Array = ["YES", "NO"];

        private var components:Array; // 所有UI元素（按顺序）

        // 控件引用
        private var blackBorders:Array; // OptionButton数组
        private var pauseAllows:Array; // OptionButton数组
        private var transitionSlider:OptionSlider;
        private var marginSlider:OptionSlider;

        public function AdvancedSettingMenu() {
            components = [];
            init();
        }

        public function init():void {
            // 标题
            var titleText:ShadowLabel = new ShadowLabel(400, 40, "ADVANCED SETTINGS", new TextFormat("downlink", 18, COLOR));
            titleText.format.horizontalAlign = Align.CENTER;
            components.push({type: "label", obj: titleText, align: "center"});

            // 黑边选项
            var blackLabel:ShadowLabel = new ShadowLabel(LABEL_WIDTH, 40, "BLACK BORDER:", new TextFormat("downlink", 12, COLOR));
            components.push({type: "label", obj: blackLabel, align: Align.RIGHT});

            blackBorders = [];
            for (var i:int = 0; i < YES_NO.length; i++) {
                var btn:OptionButton = new OptionButton(YES_NO[i], COLOR, blackBorders);
                btn.addEventListener("clicked", on_blackBorder);
                blackBorders.push(btn);
            }
            components.push({type: "buttonGroup", obj: blackBorders});

            // 允许暂停选项
            var pauseLabel:ShadowLabel = new ShadowLabel(LABEL_WIDTH, 40, "ALLOW PAUSE:", new TextFormat("downlink", 12, COLOR));
            components.push({type: "label", obj: pauseLabel, align: Align.RIGHT});

            pauseAllows = [];
            for (i = 0; i < YES_NO.length; i++) {
                btn = new OptionButton(YES_NO[i], COLOR, pauseAllows);
                btn.addEventListener("clicked", on_pauseAllow);
                pauseAllows.push(btn);
            }
            components.push({type: "buttonGroup", obj: pauseAllows});

            // 过渡速度
            var transLabel:ShadowLabel = new ShadowLabel(LABEL_WIDTH, 40, "TRANSITION SPEED:", new TextFormat("downlink", 12, COLOR));
            components.push({type: "label", obj: transLabel, align: Align.RIGHT});

            transitionSlider = new OptionSlider(1); // 中等大小
            transitionSlider.init();
            components.push({type: "slider", obj: transitionSlider});

            // 最大边距势力数
            var marginLabel:ShadowLabel = new ShadowLabel(LABEL_WIDTH, 40, "MAX MARGIN TEAM:", new TextFormat("downlink", 12, COLOR));
            components.push({type: "label", obj: marginLabel, align: Align.RIGHT});

            marginSlider = new OptionSlider(1);
            marginSlider.init();
            components.push({type: "slider", obj: marginSlider});

            var unlockAllLabel:ShadowLabel = new ShadowLabel(LABEL_WIDTH, 40, "UNLOCK ALL LEVEL:", new TextFormat("downlink", 12, COLOR));
            components.push({type: "label", obj: unlockAllLabel, align: Align.RIGHT});

            var unlockAllBtn:OptionButton = new OptionButton("unlock", COLOR);
            unlockAllBtn.addEventListener("clicked", on_unlockAll);
            components.push({type: "buttonGroup", obj: [unlockAllBtn]});

            // 执行布局
            layoutComponents();
        }

        private function layoutComponents():void {
            var currentY:Number = START_Y;

            for each (var item:Object in components) {
                switch (item.type) {
                    case "label":
                        var label:ShadowLabel = item.obj as ShadowLabel;
                        label.x = START_X;
                        label.y = currentY;
                        if (item.align == Align.RIGHT)
                            label.format.horizontalAlign = Align.RIGHT;
                        else if (item.align == Align.LEFT)
                            label.format.horizontalAlign = Align.LEFT;
                        addChild(label);
                        break;

                    case "buttonGroup":
                        var buttons:Array = item.obj as Array;
                        for (var i:int = 0; i < buttons.length; i++) {
                            buttons[i].x = CONTROL_X + i * 90; // 按钮间距90
                            buttons[i].y = currentY + BTN_Y_FIX;
                            addChild(buttons[i]);
                        }
                        break;

                    case "slider":
                        var slider:OptionSlider = item.obj as OptionSlider;
                        slider.x = CONTROL_X;
                        slider.y = currentY + BTN_Y_FIX;
                        addChild(slider);
                        break;
                }

                if (item.type == "label" && (item.obj as ShadowLabel).format.size == 18)
                    currentY += LINE_HEIGHT;
                else if (item.type != "label")
                    currentY += LINE_HEIGHT;
            }
        }

        public function animateIn():void {
            // 重置状态
            for each (var btn:OptionButton in blackBorders)
                btn.untoggle();
            for each (btn in pauseAllows)
                btn.untoggle();

            if (SaveManager.blackQuad)
                blackBorders[0].toggle();
            else
                blackBorders[1].toggle();

            if (SaveManager.nohup)
                pauseAllows[1].toggle();
            else
                pauseAllows[0].toggle();

            transitionSlider.total = SaveManager.transitionSpeed;
            transitionSlider.update();

            marginSlider.total = (SaveManager.maxMarginTeam - 1) / 9;
            marginSlider.update();

            this.visible = true;
            Starling.juggler.removeTweens(this);
            Starling.juggler.tween(this, 0.15, {"alpha": 1});

            addEventListener(EnterFrameEvent.ENTER_FRAME, onEnterFrame);
        }

        public function animateOut():void {
            Starling.juggler.removeTweens(this);
            Starling.juggler.tween(this, 0.15, {"alpha": 0, "onComplete": hide});
            removeEventListener(EnterFrameEvent.ENTER_FRAME, onEnterFrame);
        }

        public function hide():void {
            this.visible = false;
        }

        public function deinit():void {
            removeEventListener(EnterFrameEvent.ENTER_FRAME, onEnterFrame);
        }

        private function onEnterFrame(e:EnterFrameEvent):void {
            SaveManager.transitionSpeed = transitionSlider.total;

            var intValue:int = Math.round(1 + marginSlider.total * 9);
            intValue = Math.max(1, Math.min(10, intValue));
            if (SaveManager.maxMarginTeam != intValue)
                SaveManager.maxMarginTeam = intValue;
            marginSlider.label.text = intValue.toString();
        }

        private function on_blackBorder(click:Event):void {
            var target:OptionButton = click.target as OptionButton;
            var index:int = blackBorders.indexOf(target);
            SaveManager.blackQuad = (index == 0);
        }

        private function on_pauseAllow(click:Event):void {
            var target:OptionButton = click.target as OptionButton;
            var index:int = pauseAllows.indexOf(target);
            SaveManager.nohup = (index == 1);
        }

        private function on_unlockAll(click:Event):void {
            SaveManager.levelReached = 999;
            SaveManager.save();
            SceneController.s.titleMenu.initAfterEnd();
        }
    }
}
