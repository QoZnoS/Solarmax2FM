package Entity.FX {

    import starling.display.Image;
    import starling.textures.Texture;
    import UI.LayerFactory;

    public class BasicParticle {

        // 粒子类型，与所用的贴图绑定，方便复用纹理资源
        private var type:String;
        private var pClass:IParticle;
        private var image:Image;

        public var active:Boolean = true;

        // 基本粒子
        public function BasicParticle(type:String, pClass:IParticle) {
            this.type = type;
            this.pClass = pClass;
            this.image = new Image(Root.assets.getTexture(pClass.imageName));
        }

        public function init(config:Array):void {
            pClass.init(this, config)
        }

        public function update(dt:Number):void {
            pClass.update(dt);
        }

        public function texturePivotToCenter():void {
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
        private var _imagePivoted:Boolean = false;
        /** 对每个实例仅执行一次 */
        public function imagePivotToCenter():void {
            if (_imagePivoted) return;
            _imagePivoted = true;
            var texture:Texture = image.texture;
            if (texture) {
                image.pivotX = image.width * 0.5;
                image.pivotY = image.height * 0.5;
            } else {
                // 延迟设置或使用默认值
                trace("Warning: Texture not loaded when setting pivot. type: " + type);
                image.pivotX = 0;
                image.pivotY = 0;
            }
        }

        public function addToLayer():void {
            var layerArgs:Array = pClass.layerConfig;
            var arrCache:String = layerArgs.shift();
            var functionRef:Function = LayerFactory.call(arrCache);
            layerArgs.unshift(image);
            if (functionRef != null) {
                functionRef.apply(null, layerArgs);
                layerArgs.shift();
                layerArgs.unshift(arrCache);
            } else {
                trace("Error: Layer function not found for type: " + pClass.layerConfig[0]);
            }
        }

        // 执行LayerFactory.call(method)，仅传入image参数
        public function layerCall(method:String):void {
            var functionRef:Function = LayerFactory.call(method);
            if (functionRef != null) {
                functionRef(image);
            } else {
                trace("Error: Layer function not found for method: " + method);
            }
        }

        public function reset():void {
            active = true;
        }

        public function get x():Number {
            return image.x;
        }

        public function set x(value:Number):void {
            image.x = value;
        }

        public function get y():Number {
            return image.y;
        }

        public function set y(value:Number):void {
            image.y = value;
        }

        public function set scale(value:Number):void {
            image.scaleX = image.scaleY = value;
        }

        public function get scaleX():Number {
            return image.scaleX;
        }

        public function set scaleX(value:Number):void {
            image.scaleX = value;
        }

        public function get scaleY():Number {
            return image.scaleY;
        }

        public function set scaleY(value:Number):void {
            image.scaleY = value;
        }

        public function get alpha():Number {
            return image.alpha;
        }

        public function set alpha(value:Number):void {
            image.alpha = value;
        }

        public function get visible():Boolean {
            return image.visible;
        }

        public function set visible(value:Boolean):void {
            image.visible = value;
        }

        public function get rotation():Number {
            return image.rotation;
        }

        public function set rotation(value:Number):void {
            image.rotation = value;
        }

        public function set color(value:Number):void {
            image.color = value;
        }

        public function set width(value:Number):void {
            image.width = value;
        }

        public function set texture(value:String):void {
            image.texture = Root.assets.getTexture(value);
        }

        public function get debugInfo():String {
            var texture:Texture = image.texture;
            return "BasicParticle Debug: " + "pos: (" + x + ", " + y + ") " + "pivot: (" + image.pivotX + ", " + image.pivotY + ") " + "texture: " + (texture ? texture.width + "x" + texture.height : "null") + "scale: " + image.scaleX + ", " + image.scaleY;
        }
    }
}
