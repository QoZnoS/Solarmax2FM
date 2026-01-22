package Entity.FX {

    import starling.display.Image;

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

        public function init(...prop):void {
            pClass.init(this, prop)
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

        public function pivotToCenter():void {
            image.pivotX = image.width * 0.5;
            image.pivotY = image.height * 0.5;
        }

        public function set rotation(value:Number):void {
            image.rotation = value;
        }

        public function set color(value:Number):void {
            image.color = value;
        }
    }
}
