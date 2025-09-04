package Game.VictoryType {

    import Entity.Node;
    import utils.Drawer;
    import UI.UIContainer;

    public class TargetVictory implements IVictoryType {

        public var target:Node;

        private var angle:Number;

        public function TargetVictory(trigger:Object) {
            target = trigger as Node;
            angle = 0;
        }

        public function update(dt:Number):int {
            if (target.nodeData.team == Globals.playerTeam)
                return Globals.playerTeam;
            Drawer.drawCircle(UIContainer.ui.behaviorBatch, target.nodeData.x, target.nodeData.y, 0xFFFFFF, target.nodeData.lineDist - 5, target.nodeData.lineDist - 7, false, 1, 0.125, angle);
            Drawer.drawCircle(UIContainer.ui.behaviorBatch, target.nodeData.x, target.nodeData.y, 0xFFFFFF, target.nodeData.lineDist - 5, target.nodeData.lineDist - 7, false, 1, 0.125, angle + Math.PI * 0.5);
            Drawer.drawCircle(UIContainer.ui.behaviorBatch, target.nodeData.x, target.nodeData.y, 0xFFFFFF, target.nodeData.lineDist - 5, target.nodeData.lineDist - 7, false, 1, 0.125, angle + Math.PI * 1);
            Drawer.drawCircle(UIContainer.ui.behaviorBatch, target.nodeData.x, target.nodeData.y, 0xFFFFFF, target.nodeData.lineDist - 5, target.nodeData.lineDist - 7, false, 1, 0.125, angle + Math.PI * 1.5);
            angle += Math.PI / 256;
            if (angle > Math.PI * 2)
                angle -= Math.PI * 2;
            return -1;
        }

        public function get type():String {
            return VictoryTypeFactory.TARGET_TYPE;
        }
    }
}
