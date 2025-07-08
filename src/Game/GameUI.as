// 已完工

package Game {
    import flash.events.MouseEvent;
    import starling.core.Starling;
    import starling.text.TextField;
    import Game.Entity.FX.SelectFade;
    import utils.Component.MenuButton;
    import utils.Drawer;

    public class GameUI {
        // #region 类变量
        public var game:GameScene;
        public var movePerc:Number;
        public var fleetSlider:FleetSlider;
        public var sliderMedium:FleetSlider;
        public var sliderLarge:FleetSlider;
        public var sliderVertical:FleetSlider;
        public var popLabel:TextField;
        public var popLabel2:TextField;
        public var popLabel3:TextField;
        public var closeBtn:MenuButton;
        public var pauseBtn:MenuButton;
        public var restartBtn:MenuButton;
        public var speedBtns:Array;
        public var speedMult:Number;

        public var drawer:Drawer;

        // #endregion
        public function GameUI(_drawer:Drawer) // 构造函数，初始化对象
        {
            super();
            this.drawer = _drawer;
            var _Color:Number = 16755370;
            popLabel = new TextField(600, 40, "POPULATION : 50 / 50", "Downlink12", -1, _Color);
            popLabel.vAlign = popLabel.hAlign = "center";
            popLabel.pivotX = 300;
            popLabel.pivotY = 20;
            popLabel.alpha = 0.5;
            popLabel.x = 512;
            popLabel.y = 136;
            popLabel2 = new TextField(600, 40, "POPULATION : 50 / 50", "Downlink12", -1, _Color);
            popLabel2.vAlign = popLabel2.hAlign = "center";
            popLabel2.pivotX = 300;
            popLabel2.pivotY = 20;
            popLabel2.alpha = 0.5;
            popLabel2.x = popLabel.x;
            popLabel2.y = popLabel.y;
            popLabel2.alpha = 0;
            popLabel3 = new TextField(200, 40, "+ 30", "Downlink12", -1, _Color);
            popLabel3.vAlign = "center";
            popLabel3.hAlign = "left";
            popLabel3.pivotX = 0;
            popLabel3.pivotY = 20;
            popLabel3.alpha = 0.5;
            popLabel3.x = popLabel.x;
            popLabel3.y = popLabel.y;
            popLabel3.alpha = 0;
            sliderMedium = new FleetSlider(1);
            sliderMedium.x = 256;
            sliderMedium.y = 640 - sliderMedium.height * 0.5;
            sliderLarge = new FleetSlider(2);
            sliderLarge.x = 192;
            sliderLarge.y = 640 - sliderLarge.height * 0.5;
            sliderVertical = new FleetSlider(3);
            sliderVertical.y = 210;
            closeBtn = new MenuButton("btn_close");
            closeBtn.x = 15 + Globals.margin;
            closeBtn.y = 124;
            pauseBtn = new MenuButton("btn_pause");
            pauseBtn.x = closeBtn.x + closeBtn.width * 1.1;
            pauseBtn.y = 124;
            restartBtn = new MenuButton("btn_restart");
            restartBtn.x = pauseBtn.x + pauseBtn.width * 1.1;
            restartBtn.y = 123;
            speedBtns = [];
            speedMult = 1;
            var _SpeedButton:SpeedButton = null;
            for (var i:int = 0; i < 3; i++) // 遍历三个速度按钮
            {
                _SpeedButton = new SpeedButton(this, "btn_play" + (i + 1).toString(), speedBtns); // 输入的speedBtns为此按钮之前的速度按钮
                _SpeedButton.x = 870 + i * (pauseBtn.width - 2); // 计算x坐标
                _SpeedButton.y = 124; // 设定y坐标
                if (i == 2)
                    _SpeedButton.x -= 4;
                speedBtns.push(_SpeedButton);
            }
        }

        // #region 启动游戏界面UI，处理相关控件
        public function init(_GameScene:GameScene):void // 进入关卡后
        {
            this.game = _GameScene;
            switch (Globals.textSize) {
                case 0:
                    popLabel.fontName = "Downlink12";
                    popLabel2.fontName = "Downlink12";
                    popLabel3.fontName = "Downlink12";
                    fleetSlider = sliderMedium;
                    sliderMedium.visible = true;
                    sliderLarge.visible = false;
                    closeBtn.setImage("btn_close");
                    pauseBtn.setImage("btn_pause");
                    restartBtn.setImage("btn_restart");
                    break;
                case 1:
                    popLabel.fontName = "Downlink12";
                    popLabel2.fontName = "Downlink12";
                    popLabel3.fontName = "Downlink12";
                    fleetSlider = sliderMedium;
                    sliderMedium.visible = true;
                    sliderLarge.visible = false;
                    closeBtn.setImage("btn_close");
                    pauseBtn.setImage("btn_pause");
                    restartBtn.setImage("btn_restart");
                    break;
                case 2:
                    popLabel.fontName = "Downlink18";
                    popLabel2.fontName = "Downlink18";
                    popLabel3.fontName = "Downlink18";
                    fleetSlider = sliderLarge;
                    sliderMedium.visible = false;
                    sliderLarge.visible = true;
                    closeBtn.setImage("btn_close2x", 0.75);
                    pauseBtn.setImage("btn_pause2x", 0.75);
                    restartBtn.setImage("btn_restart2x", 0.75);
            }
            popLabel.fontSize = -1;
            popLabel2.fontSize = -1;
            popLabel3.fontSize = -1;
            closeBtn.x = 15 + Globals.margin;
            pauseBtn.x = closeBtn.x + closeBtn.width * 1.1;
            restartBtn.x = pauseBtn.x + pauseBtn.width * 1.1;
            movePerc = 1;
            movePercentBar(movePerc);
            switch (Globals.fleetSliderPosition) {
                case 0:
                    sliderVertical.x = 20;
                    sliderMedium.visible = false;
                    sliderLarge.visible = false;
                    sliderVertical.visible = true;
                    fleetSlider = sliderVertical;
                    break;
                case 2:
                    sliderVertical.x = 950;
                    sliderMedium.visible = false;
                    sliderLarge.visible = false;
                    sliderVertical.visible = true;
                    fleetSlider = sliderVertical;
                    break;
                case 1:
                    sliderVertical.visible = false;
            }
            fleetSlider.init();
            closeBtn.init();
            closeBtn.addEventListener("clicked", on_closeBtn);
            pauseBtn.init();
            pauseBtn.addEventListener("clicked", on_pauseBtn);
            restartBtn.init();
            restartBtn.addEventListener("clicked", on_restartBtn);
            _GameScene.uiLayer.addChild(popLabel);
            _GameScene.uiLayer.addChild(popLabel2);
            _GameScene.uiLayer.addChild(popLabel3);
            _GameScene.uiLayer.addChild(fleetSlider);
            _GameScene.uiLayer.addChild(restartBtn);
            _GameScene.uiLayer.addChild(closeBtn);
            _GameScene.uiLayer.addChild(pauseBtn);
            var _SpeedButton:SpeedButton = null;
            speedMult = 1;
            for (var i:int = 0; i < speedBtns.length; i++) {
                _SpeedButton = speedBtns[i];
                if (i == 1)
                    _SpeedButton.setImage("btn_speed1x", 0.75 + 0.6 * Globals.textSize);
                else
                    _SpeedButton.setImage("btn_play" + (i + 1).toString(), 0.6 + 0.4 * Globals.textSize);
                _GameScene.uiLayer.addChild(_SpeedButton);
                _SpeedButton.init();
                if (i == 1) {
                    _SpeedButton.toggled = true;
                    _SpeedButton.image.alpha = 0.6;
                }
            }
            speedBtns[2].x = 1024 - speedBtns[2].width + 5 - Globals.margin;
            speedBtns[1].x = speedBtns[2].x - speedBtns[1].width * 0.8 - 9;
            speedBtns[0].x = speedBtns[1].x - speedBtns[0].width * 1.25;
            Starling.current.nativeStage.addEventListener("mouseWheel", on_wheel);
        }

        public function deInit():void // 移除相关控件
        {
            fleetSlider.deInit();
            closeBtn.deInit();
            closeBtn.removeEventListener("clicked", on_closeBtn);
            pauseBtn.deInit();
            pauseBtn.removeEventListener("clicked", on_pauseBtn);
            restartBtn.deInit();
            restartBtn.removeEventListener("clicked", on_restartBtn);
            for each (var _SpeedButton:SpeedButton in speedBtns) {
                _SpeedButton.deInit();
            }
            Starling.current.nativeStage.removeEventListener("mouseWheel", on_wheel);
        }

        public function on_closeBtn():void {
            game.quit();
        }

        public function on_pauseBtn():void {
            game.pause();
        }

        public function on_restartBtn():void {
            game.restart();
        }

        public function on_wheel(_Mouse:MouseEvent):void // 鼠标滚轮（控制分兵条）
        {
            if (game.alpha == 0)
                return;
            if (_Mouse.delta < 0)
                movePerc -= 0.1;
            else
                movePerc += 0.1;
            if (movePerc < 0)
                movePerc = 0.0001;
            if (movePerc > 1)
                movePerc = 1;
            movePercentBar(movePerc);
        }

        // #endregion


        // #region 更新
        public function update(_dt:Number):void {
            movePerc = fleetSlider.total;
            movePercentBar(movePerc);
            popLabel.text = "POPULATION : " + Globals.teamPops[1] + " / " + Globals.teamCaps[1];
            popLabel2.text = popLabel.text;
            if (popLabel2.alpha > 0)
                popLabel2.alpha = Math.max(0, popLabel2.alpha - _dt * 0.5);
            if (popLabel3.alpha > 0) {
                popLabel3.x = 512 + popLabel.textBounds.width * 0.5 + 10;
                popLabel3.alpha = Math.max(0, popLabel3.alpha - _dt * 0.5);
            }
            var _R:Number = NaN;
            var _voidR:Number = NaN;
            for each (var _Fade:SelectFade in game.fades.active) {
                _R = 150 * _Fade.size - 4;
                _voidR = Math.max(0, _R - 3);
                drawer.drawCircle(game.uiBatch, _Fade.x, _Fade.y, _Fade.color, _R, _voidR, false, _Fade.alpha);
            }
        }

        public function movePercentBar(_Total:Number):void {
            fleetSlider.total = _Total;
            fleetSlider.update();
        }

        // #endregion
    }
}
