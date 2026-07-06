package utils {
    import starling.text.TextField;
    import starling.display.Sprite;
    import starling.text.TextFormat;
    import starling.text.TextOptions;
    import starling.core.Starling;
    import starling.rendering.Painter;
    import flash.geom.Rectangle;
    import starling.events.Event;

    public class ShadowLabel extends Sprite {
        private var _shadow:ScaleAwareTextField;
        private var _label:ScaleAwareTextField;
        private var _autoSync:Boolean = true;

        /**
         * @param width          文本框宽度
         * @param height         文本框高度
         * @param text           文本内容
         * @param format         TextFormat（字体名、大小、颜色）
         * @param shadowOffsetX  阴影 X 偏移（默认 0）
         * @param shadowOffsetY  阴影 Y 偏移（默认 2）
         * @param shadowColor    阴影颜色（默认 0x000000）
         * @param shadowAlpha    阴影透明度（默认 0.5）
         */
        public function ShadowLabel(width:int, height:int, text:String,
                                     format:TextFormat,
                                     shadowOffsetX:Number = 0,
                                     shadowOffsetY:Number = 2,
                                     shadowColor:uint = 0x000000,
                                     shadowAlpha:Number = 0.8) {
            // 阴影层：用 clone() 分离引用，再覆写颜色
            var shadowFmt:TextFormat = format.clone();
            shadowFmt.color = shadowColor;
            _shadow = new ScaleAwareTextField(width, height, text, shadowFmt);
            _shadow.x = shadowOffsetX;
            _shadow.y = shadowOffsetY;
            _shadow.alpha = shadowAlpha;
            _shadow.touchable = false;
            addChild(_shadow);

            // 主文字层（独立 format，不共享引用）
            _label = new ScaleAwareTextField(width, height, text, format.clone());
            _label.touchable = false;
            addChild(_label);

            // ★ 监听主文字 format 变更，自动同步到阴影
            _label.format.addEventListener(Event.CHANGE, onFormatChange);
        }

        // ===== format 自动同步 =====

        private function onFormatChange(e:Event):void {
            if (!_autoSync) return;
            // 将主文字层的 format 属性复制到阴影层（保留阴影自己的颜色和偏移）
            var mainFmt:TextFormat = _label.format;
            var shadowFmt:TextFormat = _shadow.format;
            _autoSync = false; // 防止递归触发
            shadowFmt.setTo(mainFmt.font, mainFmt.size, shadowFmt.color,
                            mainFmt.horizontalAlign, mainFmt.verticalAlign);
            _autoSync = true;
        }

        // ===== 代理属性：对齐 TextField API =====

        /** 文字内容 */
        public function get text():String { return _label.text; }
        public function set text(value:String):void {
            _label.text = value;
            _shadow.text = value;
        }

        /** 文本边界 */
        public function get textBounds():Rectangle { return _label.textBounds; }

        /** 文字格式（修改任意属性后阴影自动同步） */
        public function get format():TextFormat { return _label.format; }

        // ===== 覆盖 Sprite 的 width/height，对齐 TextField 行为 =====

        /** @inheritDoc */
        override public function set width(value:Number):void {
            _label.width = value;
            _shadow.width = value;
        }

        /** @inheritDoc */
        override public function set height(value:Number):void {
            _label.height = value;
            _shadow.height = value;
        }

        // ===== 阴影控制 =====

        /** 设置阴影偏移 */
        public function setShadowOffset(offsetX:Number, offsetY:Number):void {
            _shadow.x = offsetX;
            _shadow.y = offsetY;
        }

        /** 设置阴影颜色和透明度 */
        public function setShadowAppearance(color:uint, alpha:Number):void {
            _autoSync = false;
            _shadow.format.color = color;
            _autoSync = true;
            _shadow.alpha = alpha;
        }

        // ===== 内部访问 =====

        /** 主文字层 TextField（仅特殊情况下使用，通常用代理属性即可） */
        public function get label():TextField { return _label; }

        /** 阴影文字层 TextField */
        public function get shadow():TextField { return _shadow; }

        // ===== 清理 =====

        public override function dispose():void {
            _label.format.removeEventListener(Event.CHANGE, onFormatChange);
            super.dispose();
        }
    }
}

// =================================================================================================
//
//	内部类：感知 contentScaleFactor 变化的 TextField
//
//	Starling 原生的 TextField 在构造时按当前 contentScaleFactor 生成纹理，
//	之后即使 viewport 变化（导致 contentScaleFactor 增大）也不会自动重绘，
//	造成画面模糊。此类在每帧 render() 时检测 scale 变化并自动触发重合成。
//
// =================================================================================================

import starling.text.TextField;
import starling.text.TextFormat;
import starling.text.TextOptions;
import starling.core.Starling;
import starling.rendering.Painter;

class ScaleAwareTextField extends TextField {

    private var _lastContentScale:Number = 0;

    public function ScaleAwareTextField(width:int, height:int, text:String,
                                        format:TextFormat = null,
                                        options:TextOptions = null) {
        super(width, height, text, format, options);
        _lastContentScale = Starling.contentScaleFactor;
    }

    /** @inheritDoc */
    public override function render(painter:Painter):void {
        var currentScale:Number = Starling.contentScaleFactor;
        if (_lastContentScale != currentScale) {
            _lastContentScale = currentScale;
            setRequiresRecomposition();
        }
        super.render(painter);
    }
}