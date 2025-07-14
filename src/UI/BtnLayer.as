package UI {
    import starling.display.Sprite;
    import Game.GameScene;
    import starling.core.Starling;
    import flash.events.MouseEvent;
    import UI.Component.MenuButton;
    import UI.Component.SpeedButton;
    import UI.Component.FleetSlider;

    public class BtnLayer extends Sprite {
        /**
         * <p>游玩关卡为退出、暂停、重开</p>
         * 编辑关卡为退出、保存、测试
         */
        private var gameBtn:Vector.<MenuButton>
        private var speedBtns:Vector.<SpeedButton>;
        public var fleetSlider:FleetSlider;

        private var game:GameScene;

        private var scene:SceneController;

        public function BtnLayer(_scene:SceneController) {
            this.scene = _scene
            this.game = _scene.gameScene;
            gameBtn = new Vector.<MenuButton>(3, true);
            speedBtns = new Vector.<SpeedButton>(3, true);
        }

        public function initLevel():void {
            //#region 界面按钮
            if (Globals.textSize <= 1) {
                gameBtn[0] = new MenuButton("btn_close");
                gameBtn[1] = new MenuButton("btn_pause");
                gameBtn[2] = new MenuButton("btn_restart");

            } else {
                gameBtn[0] = new MenuButton("btn_close2x", 0.75);
                gameBtn[1] = new MenuButton("btn_pause2x", 0.75);
                gameBtn[2] = new MenuButton("btn_restart2x", 0.75);
            }
            for (var i:int = 0; i < 3; i++) {
                var _btn:MenuButton = gameBtn[i]
                i == 0 ? _btn.x = 15 + Globals.margin : _btn.x = gameBtn[i - 1].x + gameBtn[i - 1].width * 1.1;
                _btn.y = 124;
                _btn.init();
                addChild(_btn);
            }
            gameBtn[0].addEventListener("clicked", on_closeBtn);
            gameBtn[1].addEventListener("clicked", on_pauseBtn);
            gameBtn[2].addEventListener("clicked", on_restartBtn);
            //#endregion
            //#region 加速按钮
            for (i = 0; i < 3; i++) {
                var _SpeedBtn:SpeedButton = new SpeedButton(scene, "btn_play" + (i + 1).toString(), speedBtns);
                if (i == 1)
                    _SpeedBtn = new SpeedButton(scene, "btn_speed1x", speedBtns, 0.75 + 0.6 * Globals.textSize);
                else
                    _SpeedBtn = new SpeedButton(scene, "btn_play" + (i + 1).toString(), speedBtns, 0.6 + 0.4 * Globals.textSize);
                _SpeedBtn.x = 870 + i * (gameBtn[1].width - 2); // 计算x坐标
                _SpeedBtn.y = 124; // 设定y坐标
                _SpeedBtn.init();
                if (i == 1) {
                    _SpeedBtn.toggled = true;
                    _SpeedBtn.image.alpha = 0.6;
                }
                addChild(_SpeedBtn);
                speedBtns[i] = _SpeedBtn;
            }
            speedBtns[2].x = 1024 - speedBtns[2].width + 5 - Globals.margin;
            speedBtns[1].x = speedBtns[2].x - speedBtns[1].width * 0.8 - 9;
            speedBtns[0].x = speedBtns[1].x - speedBtns[0].width * 1.25;
            //#endregion
            //#region 分兵条
            switch (Globals.fleetSliderPosition) {
                case 0: // 左
                    fleetSlider = new FleetSlider(3)
                    fleetSlider.y = 210;
                    fleetSlider.x = 20;
                    break;
                case 2: // 右
                    fleetSlider = new FleetSlider(3)
                    fleetSlider.y = 210;
                    fleetSlider.x = 950;
                    break;
                case 1: // 下
                    if (Globals.textSize <= 1) {
                        fleetSlider = new FleetSlider(1)
                        fleetSlider.x = 256;
                        fleetSlider.y = 640 - fleetSlider.height * 0.5;
                    } else {
                        fleetSlider = new FleetSlider(2)
                        fleetSlider.x = 192;
                        fleetSlider.y = 640 - fleetSlider.height * 0.5;
                    }
            }
            fleetSlider.init();
            addChild(fleetSlider);
            Starling.current.nativeStage.addEventListener("mouseWheel", on_wheel);
            //#endregion
        }

        public function deinitLevel():void {
            for each (var _btn:MenuButton in gameBtn) {
                _btn.deInit();
                removeChild(_btn);
            }
            for each (var _SpeedBtn:SpeedButton in speedBtns) {
                _SpeedBtn.deInit();
                removeChild(_SpeedBtn);
            }
            gameBtn[0].removeEventListener("clicked", on_closeBtn);
            gameBtn[1].removeEventListener("clicked", on_pauseBtn);
            gameBtn[2].removeEventListener("clicked", on_restartBtn);
            fleetSlider.deInit();
            removeChild(fleetSlider)
            Starling.current.nativeStage.removeEventListener("mouseWheel", on_wheel);
        }

        private function on_closeBtn():void {
            game.quit();
        }

        private function on_pauseBtn():void {
            game.pause();
        }

        private function on_restartBtn():void {
            game.restart();
        }

        private function on_wheel(_Mouse:MouseEvent):void {
            if (game.alpha == 0)
                return;
            if (_Mouse.delta < 0)
                fleetSlider.perc -= 0.1;
            else
                fleetSlider.perc += 0.1;
            if (fleetSlider.perc < 0)
                fleetSlider.perc = 0.0001;
            if (fleetSlider.perc > 1)
                fleetSlider.perc = 1;
        }

    }
}
