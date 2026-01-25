package Entity.Node.States {
    public interface INodeState {
        function init():void;
        function deinit():void;
        function update(dt:Number):void;
        function toJSON(k:String):*;
        function get enable():Boolean;
        function get stateType():String;
    }
}
