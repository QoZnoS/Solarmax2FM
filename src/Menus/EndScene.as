package Menus {
    import starling.display.Image;
    import starling.display.Quad;
    import starling.display.QuadBatch;
    import starling.display.Sprite;
    import starling.events.EnterFrameEvent;
    import Entity.EntityPool;
    import Entity.FX.EndStar;
    import utils.Drawer;
    import Entity.GameEntity;

    public class EndScene extends Sprite {
        public var stars:EntityPool;
        public var batch:QuadBatch;
        public var cover:Quad;
        public var quadImage:Image;
        public var pulseSize:Number;
        public var pulseWidth:Number;
        public var timer:Number;

        private var scene:SceneController

        public function EndScene(scene:SceneController) {
            super();
            this.scene = scene
            quadImage = new Image(Root.assets.getTexture("quad"));
            quadImage.adjustVertices();
            stars = new EntityPool();
            batch = new QuadBatch();
            addChild(batch);
            cover = new Quad(1024, 768, 16777215);
            cover.blendMode = "add";
            cover.alpha = 0;
            addChild(cover);
            this.touchable = false;
            this.visible = false;
        }

        public function init():void {
            var endStar1:EndStar = null;
            var distance:Number = NaN;
            var angle:Number = NaN;
            var sqrt500:Number = Math.sqrt(500);
            var endStar2:EndStar = makeStar(512, 384);
            endStar2.mult = 1;
            for (var i:int = 0; i < 50; i++) {
                endStar1 = makeStar(512, 384);
                distance = Math.random() * sqrt500;
                distance = distance * distance + 50;
                angle = Math.random() * 3.141592653589793 * 2;
                endStar1.x = 512 + Math.cos(angle) * distance;
                endStar1.y = 384 + Math.sin(angle) * distance;
                while (checkProximity(stars.active, endStar1, 60)) {
                    distance = Math.random() * sqrt500;
                    distance = distance * distance + 50;
                    angle = Math.random() * 3.141592653589793 * 2;
                    endStar1.x = 512 + Math.cos(angle) * distance;
                    endStar1.y = 384 + Math.sin(angle) * distance;
                }
            }
            for each (endStar1 in stars.active) {
                if (endStar1 == endStar2)
                    continue;
                endStar1.delay = getDistance(endStar2, endStar1) * 0.05;
            }
            pulseSize = 0;
            pulseWidth = 10;
            timer = 20;
            cover.alpha = 0;
            cover.visible = true;
            this.visible = true;
            addEventListener("enterFrame", update);
        }

        // 检测_EndStar1 距数组每项的距离是否均小于_Distance
        public function checkProximity(starVector:Vector.<GameEntity>, endStar1:EndStar, distance:Number):Boolean {
            for each (var endStar2:EndStar in starVector) {
                if (endStar2 == endStar1)
                    continue;
                if (getDistance(endStar1, endStar2) > distance)
                    continue;
                return true;
            }
            return false;
        }

        // 计算距离
        public function getDistance(endStar1:EndStar, endStar2:EndStar):Number {
            var dx:Number = endStar1.x - endStar2.x;
            var dy:Number = endStar1.y - endStar2.y;
            return Math.sqrt(dx * dx + dy * dy);
        }

        public function deInit():void {
            stars.deInit();
            cover.alpha = 0;
            cover.visible = false;
            batch.reset();
            this.visible = false;
            this.touchable = false;
            removeEventListener("enterFrame", update);
        }

        public function makeStar(x:Number, y:Number, delay:Number = 0):EndStar {
            var endStar:EndStar = stars.getReserve() as EndStar;
            if (!endStar)
                endStar = new EndStar();
            endStar.initStar(this, x, y, delay);
            stars.addEntity(endStar);
            return endStar;
        }

        public function update(e:EnterFrameEvent):void {
            var dt:Number = e.passedTime;
            timer -= dt;
            if (cover.alpha == 1) {
                if (timer <= 0) {
                    timer = 0;
                    deInit();
                    scene.exit2TitleMenu(2);
                }
            } else if (timer <= 0) {
                timer = 0;
                if (cover.alpha < 1) {
                    cover.alpha += dt * 0.1;
                    if (cover.alpha >= 1) {
                        cover.alpha = 1;
                        timer = 5;
                    }
                }
            }
            stars.update(dt);
            pulseSize += dt * 20;
            pulseWidth += dt * 3;
            var model:Number = pulseSize - pulseWidth;
            if (model < 0)
                model = 0;
            var alpha:Number = (1 - pulseSize / 512) * 0.4;
            if (alpha < 0)
                alpha = 0;
            var quality:int = 8 + pulseSize / 512 * 248;
            batch.reset();
            Drawer.drawCircle(batch, 512, 384, Globals.teamColors[1], pulseSize, model, true, alpha, 1, 0, quality);
            Globals.teamColors[1] == 0 ? batch.blendMode = "normal" : batch.blendMode = "add";
        }

    }
}
