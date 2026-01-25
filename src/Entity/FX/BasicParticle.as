package Entity.FX {

    import starling.display.Image;
    import starling.textures.Texture;

    public class BasicParticle {

        // 粒子类型，与所用的贴图绑定，一经确认不可修改，方便复用纹理资源
        private var type:String;
        private var pClass:IParticle;
        public var image:Image;

        public var active:Boolean = false;

        // 基本粒子
        public function BasicParticle(type:String, pClass:IParticle) {
            this.type = type;
            this.pClass = pClass;
            this.image = new Image(Root.assets.getTexture(pClass.imageName));
        }

        public function init(config:Object):void {
            pClass.init(this, config)
        }

        public function update(dt:Number):void {

        }

        public function reset():void {
        }

        public function set x(value:Number):void {
            image.x = value;
        }

        public function set y(value:Number):void {
            image.y = value;
        }

        public function set scale(value:Number):void {
            image.scaleX = image.scaleY = value;
        }

        public function set scaleX(value:Number):void {
            image.scaleX = value;
        }

        public function set scaleY(value:Number):void {
            image.scaleY = value;
        }
        public function pivotToCenter():void {
            // 确保纹理已加载
            var texture:Texture = image.texture;
            if (texture) {
                image.pivotX = texture.width * 0.5;
                image.pivotY = texture.height * 0.5;
            } else {
                // 延迟设置或使用默认值
                trace("Warning: Texture not loaded when setting pivot. type: " + type);
                image.pivotX = 0;
                image.pivotY = 0;
            }
        }

        public function set rotation(value:Number):void {
            image.rotation = value;
        }

        public function set color(value:Number):void {
            image.color = value;
        }
    }
}
