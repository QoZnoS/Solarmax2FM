package scenes {
    import core.EntityContainer;
    import core.EntityHandler;
    import core.EntityPool;
    import core.entities.Node;
    import starling.core.Starling;
    import starling.events.EnterFrameEvent;
    import ui.UIContainer;
    import managers.SaveManager;

    public class EditorScene extends BasicScene {
        // private const defaultNode:Object = {"x": 980,"y": 154,"type": "planet"};
        private const defaultNode:Object = {"x": 990, "y": 620, "type": "planet", "size":0.5};

        public var history:Vector.<String>; // 操作记录

        public function EditorScene(scene:SceneController) {
            super(scene);
            visible = false;
            history = new Vector.<String>;
        }

        public function init():void {
            this.alpha = 1;
            this.visible = true;
            animateIn();
            EntityContainer.shipTagCounter = 0;
            addEventListener("enterFrame", update);

            var node:Node = EntityHandler.addNode(defaultNode);
            node.update(0);

            history.length = 0;
        }

        public function deInit():void {
            for each (var pool:EntityPool in EntityContainer.entityPool)
                pool.deInit();
            removeEventListener("enterFrame", update); // 移除更新帧监听器
            visible = false;
        }

        public function quit():void {
            animateOut();
            scene.exit2TitleMenu(3);
            Starling.juggler.tween(this, SaveManager.transitionSpeed, {onComplete: deInit});
        }

        override public function update(e:EnterFrameEvent):void {
            var dt:Number = e.passedTime;
            UIContainer.i.update();
        }

        private function exeCode(code:Array):void {
            // TODO: 执行外部指令
        }

        private function genCode(code:String):void {
            // TODO: 生成可执行指令
        }

        public function undo():void {
            // TODO: 撤销
        }

        public function redo():void {
            // TODO: 重做
        }

    }
}