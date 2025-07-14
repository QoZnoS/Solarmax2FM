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
        public var popLabel:TextField;
        public var popLabel2:TextField;
        public var popLabel3:TextField;

        // #endregion
        public function GameUI() // 构造函数，初始化对象
        {
            super();
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
                    break;
                case 1:
                    popLabel.fontName = "Downlink12";
                    popLabel2.fontName = "Downlink12";
                    popLabel3.fontName = "Downlink12";
                    break;
                case 2:
                    popLabel.fontName = "Downlink18";
                    popLabel2.fontName = "Downlink18";
                    popLabel3.fontName = "Downlink18";
            }
            popLabel.fontSize = -1;
            popLabel2.fontSize = -1;
            popLabel3.fontSize = -1;
            _GameScene.uiLayer.addChild(popLabel);
            _GameScene.uiLayer.addChild(popLabel2);
            _GameScene.uiLayer.addChild(popLabel3);
            var _SpeedButton:SpeedButton = null;
            Starling.current.nativeStage.addEventListener("mouseWheel", on_wheel);
        }

        public function deInit():void // 移除相关控件
        {
            Starling.current.nativeStage.removeEventListener("mouseWheel", on_wheel);
        }

        public function on_wheel(_Mouse:MouseEvent):void // 鼠标滚轮（控制分兵条）
        {
            if (game.alpha == 0)
                return;
            // if (_Mouse.delta < 0)
            //     movePerc -= 0.1;
            // else
            //     movePerc += 0.1;
            // if (movePerc < 0)
            //     movePerc = 0.0001;
            // if (movePerc > 1)
            //     movePerc = 1;
            // movePercentBar(movePerc);
        }

        // #endregion


        // #region 更新
        public function update(_dt:Number):void {
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
                Drawer.drawCircle(game.uiBatch, _Fade.x, _Fade.y, _Fade.color, _R, _voidR, false, _Fade.alpha);
            }
        }

        // #endregion
    }
}
