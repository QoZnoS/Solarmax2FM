package UI
{
    import starling.display.Sprite;
    import utils.Component.MenuButton;
    import Game.SpeedButton;
    import Game.FleetSlider;

    public class BtnLayer extends Sprite{
        
        private var gameBtn:Vector.<MenuButton>

        public function BtnLayer(){

        }
        /** 退出 */
        public function addExitBtn():MenuButton{
            return null;
        }
        /** 重开 */
        public function addRestartBtn():MenuButton{
            return null;
        }
        /** 暂停 */
        public function addPauseBtn():MenuButton{
            return null;
        }
        /** 变速 */
        public function addSpeedBtns():Array{
            return null;
        }
        /** 分兵条 */
        public function addPstSlider():FleetSlider{
            return null;
        }
        /** 自定义 */
    }
}