package Entity.FX {
    public interface IParticle {
        function get imageName():String;
        function init(...prop):void; // 得改成config:Object
        function update(dt:Number):void;
    }
}
