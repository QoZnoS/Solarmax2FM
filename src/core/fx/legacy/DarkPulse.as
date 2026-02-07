// initPulse(gameScene, node, color, type, maxSize, rate, angle, delay)
// node为天体，color为颜色，type为类型，maxSize为最大大小，rate为速度，angle为角度，delay为延迟
// 类型的意义详见update(dt)
package core.fx.legacy {
    import core.entities.GameEntity;
    import core.entities.Node;

    import scenes.GameScene;

    import starling.display.Image;
    import ui.layers.LayerFactory;

    public class DarkPulse extends GameEntity {
        public static const TYPE_GROW:int = 0;
        public static const TYPE_SHRINK:int = 1;
        public static const TYPE_BLOB:int = 2;
        public static const TYPE_BLOOM:int = 3;
        public static const TYPE_BLACKHOLE_ATTACK:int = 4;
        public static const TYPE_DIFFUSION_ARC:int = 8;
        public static const TYPE_SHIP_PULSE_SHRINK:int = 9;
        public static const TYPE_SHIP_PULSE_GROW:int = 10;

        private var x:Number;
        private var y:Number;
        private var size:Number;
        private var maxSize:Number;
        private var delay:Number;
        private var rate:Number;
        private var angle:Number;
        private var image:Image;
        private var type:int;
        private var deepColor:Boolean;

        public function DarkPulse() {
            super();
            image = new Image(Root.assets.getTexture("halo"));
            image.pivotX = image.pivotY = image.width * 0.5;
        }

        public function initPulse(gameScene:GameScene, node:Node, color:uint, type:int, maxSize:Number, rate:Number, angle:Number, deepColor:Boolean, delay:Number = 0):void {
            super.init(gameScene);
            image.rotation = 0;
            switch (type) {
                case TYPE_GROW:
                case TYPE_SHRINK:
                    image.texture = Root.assets.getTexture("halo");
                    break;
                case TYPE_BLOB:
                case TYPE_BLOOM:
                    image.texture = Root.assets.getTexture("spot_glow");
                    break;
                case TYPE_BLACKHOLE_ATTACK:
                    image.texture = Root.assets.getTexture("blackhole_pulse");
                    break;
                case TYPE_DIFFUSION_ARC:
                    var imageID:int = Math.floor(Math.random() * 16) + 1;
                    image.texture = Root.assets.getTexture("elecarc" + (imageID < 10 ? "0" + imageID : imageID.toString()));
                    break;
                case TYPE_SHIP_PULSE_SHRINK:
                case TYPE_SHIP_PULSE_GROW:
                    image.texture = Root.assets.getTexture("ship_pulse");
            }
            image.readjustSize();
            image.width = image.texture.width;
            image.height = image.texture.height;
            image.scaleX = image.scaleY = 1;
            image.pivotX = image.pivotY = image.width * 0.5;
            image.color = color;
            this.x = node.nodeData.x;
            this.y = node.nodeData.y;
            this.type = type;
            this.maxSize = maxSize;
            this.rate = rate;
            this.angle = angle;
            this.delay = delay;
            this.deepColor = deepColor;
            image.x = x;
            image.y = y;
            image.color = color;
            image.visible = true;
            switch (type) {
                case TYPE_GROW:
                case TYPE_SHIP_PULSE_GROW:
                    size = 0;
                    image.alpha = 1;
                    image.scaleX = image.scaleY = size;
                    break;
                case TYPE_SHRINK:
                case TYPE_SHIP_PULSE_SHRINK:
                    size = maxSize;
                    image.alpha = 0;
                    image.scaleX = image.scaleY = size;
                    break;
                case TYPE_BLOB:
                    size = maxSize;
                    image.alpha = 0;
                    image.scaleX = image.scaleY = size * 6;
                    break;
                case TYPE_BLOOM:
                    size = 0;
                    image.alpha = 1;
                    image.scaleX = image.scaleY = size;
                    break;
                case TYPE_BLACKHOLE_ATTACK:
                case TYPE_DIFFUSION_ARC:
                    image.alpha = rate * 0.8;
                    image.scaleX = image.scaleY = maxSize;
                    image.rotation = angle;
            }
            if (type == TYPE_BLACKHOLE_ATTACK)
                LayerFactory.call(LayerFactory.ADD_BLACKHOLE)(image);
            else
                LayerFactory.call(LayerFactory.ADD_GROW)(image, deepColor);
        }

        override public function deInit():void {
            LayerFactory.call(LayerFactory.REMOVE_GROW)(image);
        }

        override public function update(dt:Number):void {
            if (delay > 0) {
                image.visible = false;
                delay -= dt;
                if (delay <= 0)
                    image.visible = true;
                return;
            }
            switch (type) {
                case TYPE_GROW: // 使用halo，贴图大小递增
                    updateGrow(dt);
                    break;
                case TYPE_SHRINK: // 使用halo，贴图大小递减
                    updateShrink(dt);
                    break;
                case TYPE_BLOB: // 使用spot_glow，贴图大小递减
                    updateBlob(dt);
                    break;
                case TYPE_BLOOM: // 使用spot_glow，贴图大小递增
                    updateBloom(dt);
                    break;
                case TYPE_SHIP_PULSE_SHRINK:
                    updateFullShrink(dt);
                    break;
                case TYPE_SHIP_PULSE_GROW:
                    updateFullGrow(dt);
                    break;
                default: // 只播放一帧的特效
                    updateFrame(dt);
            }
        }

        private function updateGrow(dt:Number):void {
            var scale:Number = size / maxSize;
            size += dt * rate;
            if (size > maxSize) {
                size = maxSize;
                active = false;
            }
            image.alpha = 1 - scale;
            image.scaleY = size * scale;
            image.scaleX = maxSize * 0.5;
            image.rotation = angle;
        }

        private function updateFullGrow(dt:Number):void {
            var scale:Number = size / maxSize;
            size += dt * rate;
            if (size > maxSize) {
                size = maxSize;
                active = false;
            }
            image.alpha = 1 - scale;
            image.scaleY = size * scale;
            image.scaleX = size * scale;
            image.rotation = angle;
        }

        private function updateShrink(dt:Number):void {
            var scale:Number = size / maxSize;
            size -= dt * rate;
            if (size < 0) {
                size = 0;
                active = false;
            }
            image.alpha = 1 - scale;
            image.scaleY = size * scale;
            image.scaleX = maxSize * 0.5;
            image.rotation = angle;
        }

        private function updateFullShrink(dt:Number):void {
            var scale:Number = size / maxSize;
            size -= dt * rate;
            if (size < 0) {
                size = 0;
                active = false;
            }
            image.alpha = 1 - scale;
            image.scaleY = size * scale;
            image.scaleX = size * scale;
            image.rotation = angle;
        }

        private function updateBlob(dt:Number):void {
            var scale:Number = size / maxSize;
            size -= dt * rate;
            if (size < 0) {
                size = 0;
                active = false;
            }
            image.alpha = 1 - scale;
            image.scaleX = image.scaleY = size * 6;
        }

        private function updateBloom(dt:Number):void {
            var scale:Number = size / maxSize;
            size += dt * rate;
            if (size > maxSize) {
                size = maxSize;
                active = false;
            }
            image.alpha = 1 - scale;
            image.scaleX = image.scaleY = size;
        }

        private function updateFrame(dt:Number):void {
            active = false;
        }
    }
}
