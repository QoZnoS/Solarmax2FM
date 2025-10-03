package Game.SpecialEvent {
    import UI.Component.TutorialSprite;
    import Entity.EntityContainer;
    import Game.GameScene;
    import Entity.Node;

    public class MoveGuideSE implements ISpecialEvent {
        private static const STATE_START:int = 0;
        private static const STATE_END:int = 1;

        private var tutorial:TutorialSprite;
        private var state:int;
        private var _game:GameScene;

        public function MoveGuideSE(trigger:Object) {
            tutorial = new TutorialSprite();
            tutorial.init(TutorialSprite.TYPE_L1);
            if (EntityContainer.nodes[0].ships[1].length == 0)
                tutorial.type = TutorialSprite.TYPE_END;
            state = STATE_START;
        }

        public function update(dt:Number):void {
            switch (state) {
                case STATE_START:
                    if (EntityContainer.nodes[0].ships[1].length < 60) {
                        state = STATE_END;
                        tutorial.type = TutorialSprite.TYPE_END;
                    }
                    break;
                case STATE_END:
                    for each (var node:Node in EntityContainer.nodes)
                        if (node.nodeData.team != Globals.playerTeam)
                            return;
                    _game.winningTeam = Globals.playerTeam;
                    break;
            }
        }

        public function deinit():void {
            if (state == STATE_END)
                return;
            tutorial.deInit();
        }

        public function get type():String {
            return SpecialEventFactory.MOVE_GUIDE;
        }

        public function set game(value:GameScene):void {
            _game = value;
        }
    }
}
