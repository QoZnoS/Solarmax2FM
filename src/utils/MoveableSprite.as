package utils {
    import starling.display.Sprite;
    import flash.geom.Point;
    import starling.events.Touch;
    import starling.events.TouchEvent;
    import flash.events.MouseEvent;
    import starling.core.Starling;
    import starling.events.TouchPhase;
    import starling.display.Quad;
    import starling.display.DisplayObject;

    public class MoveableSprite extends Sprite {

        private var cover:Quad;
        private var container:Sprite;

        public function MoveableSprite() {
            cover = new Quad(1024, 768);
            cover.alpha = 0;
            container = new Sprite();
            container.x = container.pivotX = 512;
            container.y = container.pivotY = 384;
            super.addChild(cover);
            super.addChild(container);
            bg = new Quad(256, 192, 0x000000);
            bg.x = 512;
            bg.y = 384;
            bg.pivotX = 128;
            bg.pivotY = 96;
            bg.alpha = 0.4;
            bg.touchable = true;
            container.addChild(bg);
        }

        public function setBox(width:Number, height:Number):void {
            container.removeChild(bg);
            bg = new Quad(width, height, 0x000000);
            bg.x = 512;
            bg.y = 384;
            bg.pivotX = width / 2;
            bg.pivotY = height / 2;
            bg.alpha = 0.4;
            bg.touchable = true;
            container.addChild(bg);
        }

        // #region 拖动与缩放逻辑
        private var dragable:Boolean = false;
        private var isDragging:Boolean = false;
        private var dragOffsetX:Number = 0;
        private var dragOffsetY:Number = 0;

        private var scaleable:Boolean = false;
        private var isScaling:Boolean = false;
        private var initialDistance:Number = 0;
        private var initialScale:Number = 1;

        private var bg:Quad;

        override public function dispose():void {
            if (dragable)
                removeEventListener(TouchEvent.TOUCH, onTouch);
            if (scaleable)
                Starling.current.nativeStage.removeEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);
            super.dispose();
        }

        public function enableDrag():void {
            if (dragable)
                return;
            dragable = true;
            addEventListener(TouchEvent.TOUCH, onTouch);
        }

        public function enableScale():void {
            if (scaleable)
                return;
            scaleable = true;
            Starling.current.nativeStage.addEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);
        }

        public function disableDrag():void {
            if (!dragable)
                return;
            dragable = false;
            removeEventListener(TouchEvent.TOUCH, onTouch);
        }

        public function disableScale():void {
            if (!scaleable)
                return;
            scaleable = false;
            Starling.current.nativeStage.removeEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);
        }

        public function onTouch(event:TouchEvent):void {
            // 双指缩放
            if (scaleable) {
                var touches:Vector.<Touch> = event.getTouches(this);
                if (touches.length == 2) {
                    var t1:Touch = touches[0];
                    var t2:Touch = touches[1];
                    var p1:Point = t1.getLocation(this);
                    var p2:Point = t2.getLocation(this);
                    var dist:Number = Point.distance(p1, p2);

                    if (!isScaling) {
                        isScaling = true;
                        initialDistance = dist;
                        initialScale = container.scaleX;
                    } else {
                        var scale:Number = initialScale * (dist / initialDistance);
                        scale = Math.max(0.5, Math.min(2, scale));
                        container.scaleX = container.scaleY = scale;
                    }
                    isDragging = false; // 禁止拖动
                    return;
                } else {
                    isScaling = false;
                }
            }

            // 单指拖动
            if (dragable) {
                var touch:Touch = event.getTouch(this);
                if (!touch)
                    return;

                if (touch.phase == TouchPhase.BEGAN) {
                    if (touch.isTouching(bg)) {
                        isDragging = true;
                        var localPos:Point = touch.getLocation(this);
                        dragOffsetX = container.x - localPos.x;
                        dragOffsetY = container.y - localPos.y;
                    }
                } else if (touch.phase == TouchPhase.MOVED && isDragging) {
                    var movePos:Point = touch.getLocation(this);
                    container.x = Math.max(Math.min(movePos.x + dragOffsetX, 1024 - bg.width / 2), bg.width / 2);
                    container.y = Math.max(Math.min(movePos.y + dragOffsetY, 768 - bg.height / 2), bg.height / 2);
                } else if (touch.phase == TouchPhase.ENDED) {
                    isDragging = false;
                }
            }
        }

        public function onMouseWheel(e:MouseEvent):void {
            var scale:Number = container.scaleX + (e.delta > 0 ? 0.1 : -0.1);
            scale = Math.max(0.5, Math.min(2, scale));
            container.scaleX = container.scaleY = scale;
        }
        // #endregion
        // #region 重写父类逻辑
        override public function addChild(child:DisplayObject):DisplayObject {
            return container.addChild(child);
        }

        override public function addChildAt(child:DisplayObject, index:int):DisplayObject {
            if (child == cover || child == container)
                return super.addChildAt(child, index);

            return container.addChildAt(child, index);
        }

        override public function swapChildren(child1:DisplayObject, child2:DisplayObject):void {
            return container.swapChildren(child1, child2);
        }

        override public function swapChildrenAt(index1:int, index2:int):void {
            return container.swapChildrenAt(index1, index2);
        }
        // #endregion
    }
}
