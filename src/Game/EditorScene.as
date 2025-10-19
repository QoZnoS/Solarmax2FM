package Game {

    import starling.core.Starling;
    import Entity.EntityPool;
    import Entity.EntityContainer;
    import starling.events.EnterFrameEvent;

    public class EditorScene extends BasicScene {



        public function EditorScene(scene:SceneController) {
            super(scene);
            visible = false;
        }

        public function init():void {
            this.alpha = 1;
            this.visible = true;
            addEventListener("enterFrame", update); // 添加帧监听器，每帧执行一次update
            animateIn();
        }

        public function deInit():void {
            for each (var pool:EntityPool in EntityContainer.entityPool)
                pool.deInit();
            removeEventListener("enterFrame", update); // 移除更新帧监听器
            visible = false;
        }

        override public function update(e:EnterFrameEvent):void {
            var dt:Number = e.passedTime;
        }

        public function quit():void {
            animateOut();
            scene.exit2TitleMenu(3);
            Starling.juggler.tween(this, Globals.transitionSpeed, {onComplete: deInit});
        }

    }
}
