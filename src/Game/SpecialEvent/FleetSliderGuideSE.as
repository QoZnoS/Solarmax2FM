package Game.SpecialEvent {
    import UI.Component.TutorialSprite;
    import UI.UIContainer;
    import Game.GameScene;

    public class FleetSliderGuideSE implements ISpecialEvent {
        private static const STATE_START:int = 0;
        private static const STATE_END:int = 1;

        private var tutorial:TutorialSprite;
        private var state:int;

        public function FleetSliderGuideSE(trigger:Object) {
            tutorial = new TutorialSprite();
            tutorial.init(TutorialSprite.TYPE_L2);
            state = STATE_START;
        }

        public function update(dt:Number):void {
            switch (state) {
                case STATE_START:
                    if (UIContainer.fleetSlider.perc < 1) {
                        state = STATE_END;
                        tutorial.type = TutorialSprite.TYPE_END;
                    }
                    break;
                case STATE_END:
                    break;
            }
        }

        public function deinit():void {
            if (state == STATE_END)
                return;
            tutorial.deInit();
        }

        public function get type():String {
            return SpecialEventFactory.FLEET_SLIDER_GUIDE;
        }

        public function set game(value:GameScene):void {
        }
    }
}
