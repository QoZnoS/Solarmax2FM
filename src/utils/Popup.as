package utils {
    import starling.display.Sprite;
    import starling.display.Quad;
    import UI.Component.OptionButton;
    import starling.text.TextField;
    import starling.utils.VAlign;
    import starling.utils.HAlign;
    import flash.geom.Point;
    import starling.events.TouchEvent;
    import starling.events.Touch;
    import starling.events.TouchPhase;
    import flash.events.MouseEvent;
    import starling.core.Starling;

    public class Popup extends Sprite {

        /** 信息提示版，确认后销毁自己，不需要回调 */
        public static const TYPE_INFORMATION:int = 0;
        /** 确认选项 */
        public static const TYPE_CHOOSE:int = 1;

        private const COLOR:uint = 0xFF9DBB;

        private var type:int = 0;
        private var popupContainer:Sprite;
        private var bg:Quad;
        private var cover:Quad;
        private var acceptBtn:OptionButton;
        private var rejectBtn:OptionButton;
        private var labels:Vector.<TextField>;

        /**
         * <p>TYPE_INFORMATION title
         * <p>TYPE_CHOOSE info
         */
        public function Popup(type:int = TYPE_INFORMATION, ...prop) {
            this.type = type;
            cover = new Quad(1024, 768);
            cover.alpha = 0;
            bg = new Quad(560, 270, 0x000000);
            bg.alpha = 0.4;
            bg.x = 512;
            bg.y = 384;
            bg.pivotX = 280;
            bg.pivotY = 135;
            bg.touchable = true;
            popupContainer = new Sprite();
            popupContainer.x = popupContainer.pivotX = 512;
            popupContainer.y = popupContainer.pivotY = 384;
            addChild(cover);
            addChild(popupContainer);
            popupContainer.addChild(bg);
            switch(type)
            {
                case TYPE_INFORMATION:
                    var title:TextField = new TextField(512, 40, prop[0], "Downlink18", -1, COLOR);
                    title.x = 256;
                    title.y = 249; //384-135
                    title.vAlign = title.hAlign = "center";
                    title.touchable = false;
                    popupContainer.addChild(title);
                    break;
                case TYPE_CHOOSE:
                    var info:TextField = new TextField (512, 200, prop[0], "Downlink18", -1, COLOR);
                    info.x = 256;
                    info.y = 180;
                    info.vAlign = info.hAlign = "center";
                    info.touchable = false;
                    popupContainer.addChild(info);
                default:
                    break;
            }
            labels = new Vector.<TextField>();
            createBtn();
        }

        public function addLabel(text:String):void {
            var label:TextField = new TextField(512, 270, text, "Downlink12", -1, COLOR);
            label.x = 256;
            label.y = 289;
            label.vAlign = VAlign.TOP;
            label.hAlign = HAlign.LEFT;
            label.touchable = false;
            popupContainer.addChild(label);
            labels.push(label)
        }

        private function createBtn():void {
            switch (type) {
                case TYPE_INFORMATION:
                    acceptBtn = new OptionButton("ACCEPT", COLOR);
                    acceptBtn.x = 480;
                    acceptBtn.y = 491;
                    acceptBtn.quad.color = COLOR;
                    acceptBtn.quad.alpha = 0.2;
                    popupContainer.addChild(acceptBtn);
                    acceptBtn.addEventListener("clicked", on_accept_deinit)
                    break;
                case TYPE_CHOOSE:
                    acceptBtn = new OptionButton("ACCEPT", COLOR);
                    acceptBtn.x = 350;
                    acceptBtn.y = 480;
                    acceptBtn.quad.color = COLOR;
                    acceptBtn.quad.alpha = 0.2;
                    popupContainer.addChild(acceptBtn);
                    acceptBtn.addEventListener("clicked", on_accept_deinit)
                    rejectBtn = new OptionButton("REJECL", COLOR);
                    rejectBtn.x = 610;
                    rejectBtn.y = 480;
                    rejectBtn.quad.color = COLOR;
                    rejectBtn.quad.alpha = 0.2;
                    popupContainer.addChild(rejectBtn);
                    rejectBtn.addEventListener("clicked", on_accept_deinit)
                    break;
                default:
                    break;
            }
        }

        //#region 拖动缩放相关逻辑
        private var dragable:Boolean = false;
        private var isDragging:Boolean = false;
        private var dragOffsetX:Number = 0;
        private var dragOffsetY:Number = 0;

        private var scaleable:Boolean = false;
        private var isScaling:Boolean = false;
        private var initialDistance:Number = 0;
        private var initialScale:Number = 1;

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
                        initialScale = popupContainer.scaleX;
                    } else {
                        var scale:Number = initialScale * (dist / initialDistance);
                        scale = Math.max(0.5, Math.min(2, scale));
                        popupContainer.scaleX = popupContainer.scaleY = scale;
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
                        dragOffsetX = popupContainer.x - localPos.x;
                        dragOffsetY = popupContainer.y - localPos.y;
                    }
                } else if (touch.phase == TouchPhase.MOVED && isDragging) {
                    var movePos:Point = touch.getLocation(this.parent);
                    popupContainer.x = Math.max(Math.min(movePos.x + dragOffsetX, 1024 - popupContainer.width / 2), popupContainer.width / 2);
                    popupContainer.y = Math.max(Math.min(movePos.y + dragOffsetY, 768 - popupContainer.height / 2), popupContainer.height / 2);
                } else if (touch.phase == TouchPhase.ENDED) {
                    isDragging = false;
                }
            }
        }

        // 鼠标滚轮缩放
        private function onMouseWheel(e:MouseEvent):void {
            var scale:Number = popupContainer.scaleX + (e.delta > 0 ? 0.1 : -0.1);
            scale = Math.max(0.5, Math.min(2, scale));
            popupContainer.scaleX = popupContainer.scaleY = scale;
        }

        //#endregion

        /**<code>accept.addEventListener("clicked", 回调函数)</code>*/
        public function get accept():OptionButton {
            return acceptBtn;
        }

        /**<code>reject.addEventListener("clicked", 回调函数)</code>*/
        public function get reject():OptionButton {
            return rejectBtn;
        }

        private function on_accept_deinit():void {
            this.parent.removeChild(this, true);
            dispose();
        }
    }
}
