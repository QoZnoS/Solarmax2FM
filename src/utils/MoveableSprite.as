package utils {
    import starling.display.Sprite;
    import flash.geom.Point;
    import starling.events.Touch;
    import starling.events.TouchEvent;
    import flash.events.MouseEvent;
    import starling.core.Starling;
    import starling.events.TouchPhase;
    import starling.display.Quad;

    public class MoveableSprite extends Sprite {
        public function MoveableSprite() {
        }

        private var dragable:Boolean = false;
        private var isDragging:Boolean = false;
        private var dragOffsetX:Number = 0;
        private var dragOffsetY:Number = 0;

        private var scaleable:Boolean = false;
        private var isScaling:Boolean = false;
        private var initialDistance:Number = 0;
        private var initialScale:Number = 1;

        private var _bg:Quad;

        override public function dispose():void {
            if (dragable)
                removeEventListener(TouchEvent.TOUCH, onTouch);
            if (scaleable)
                Starling.current.nativeStage.removeEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);
            super.dispose();
        }

        public function enableDrag():void {
            dragable = true;
            addEventListener(TouchEvent.TOUCH, onTouch);
        }

        public function enableScale():void {
            scaleable = true;
            Starling.current.nativeStage.addEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);
        }

        private function onTouch(event:TouchEvent):void {
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
                        initialScale = this.scaleX;
                    } else {
                        var scale:Number = initialScale * (dist / initialDistance);
                        scale = Math.max(0.5, Math.min(2, scale));
                        this.scaleX = this.scaleY = scale;
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
                    if (touch.isTouching(_bg)) {
                        isDragging = true;
                        var localPos:Point = touch.getLocation(this);
                        dragOffsetX = this.x - localPos.x;
                        dragOffsetY = this.y - localPos.y;
                    }
                } else if (touch.phase == TouchPhase.MOVED && isDragging) {
                    var movePos:Point = touch.getLocation(this.parent);
                    this.x = Math.max(Math.min(movePos.x + dragOffsetX, 1024 - this.width / 2), this.width / 2);
                    this.y = Math.max(Math.min(movePos.y + dragOffsetY, 768 - this.height / 2), this.height / 2);
                } else if (touch.phase == TouchPhase.ENDED) {
                    isDragging = false;
                }
            }
        }

        // 鼠标滚轮缩放
        private function onMouseWheel(e:MouseEvent):void {
            var scale:Number = this.scaleX + (e.delta > 0 ? 0.1 : -0.1);
            scale = Math.max(0.5, Math.min(2, scale));
            this.scaleX = this.scaleY = scale;
        }

        public function set bg(value:Quad):void {
            this._bg = value;
        }
    }
}
