package Entity.FX {
    public interface IParticle {
        function get imageName():String;
        function get layerConfig():Array;
        function init(p:BasicParticle, config:Array):void;
        function update(dt:Number):void;
    }
}
