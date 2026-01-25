package Entity.FX {
    public interface IParticle {
        function get imageName():String;
        function init(p:BasicParticle, config:Object):void;
        function update(dt:Number):void;
    }
}
