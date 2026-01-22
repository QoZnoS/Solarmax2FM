// Entity/FX/ParticleData.as
package Entity.FX {
    import starling.display.Image;

    public class ParticleData {
        public var id:int;
        public var type:String;
        public var config:Object;
        public var active:Boolean = false;
        public var visible:Boolean = true;
        public var image:Image;
        
        // 变换属性
        public var x:Number = 0;
        public var y:Number = 0;
        public var scaleX:Number = 1;
        public var scaleY:Number = 1;
        public var rotation:Number = 0;
        public var alpha:Number = 1;
        public var color:uint = 0xFFFFFF;
        
        // 动画属性
        public var size:Number = 0;
        public var currentState:int = 0;
        public var delay:Number = 0;
        public var age:Number = 0;
        public var lifetime:Number = 1.0;
        
        // 物理属性
        public var velocityX:Number = 0;
        public var velocityY:Number = 0;
        public var accelerationX:Number = 0;
        public var accelerationY:Number = 0;
        
        // 特殊属性
        public var deepColor:Boolean = false;
        public var foreground:Boolean = true;
        public var secondaryScale:Number = 1;
        public var secondaryAlpha:Number = 1;
        public var growthRate:Number = 1;
        public var shrinkRate:Number = 1;
        
        public function ParticleData() {
            // 空构造函数
        }
        
        public function reset():void {
            id = -1;
            type = null;
            config = null;
            active = false;
            visible = true;
            
            x = y = 0;
            scaleX = scaleY = 1;
            rotation = 0;
            alpha = 1;
            color = 0xFFFFFF;
            
            size = 0;
            currentState = 0;
            delay = 0;
            age = 0;
            lifetime = 1.0;
            
            velocityX = velocityY = 0;
            accelerationX = accelerationY = 0;
            
            deepColor = false;
            foreground = true;
            secondaryScale = secondaryAlpha = 1;
            growthRate = shrinkRate = 1;
        }
    }
}