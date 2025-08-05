package Entity.Node.States
{
    import Entity.Node
    
    public interface INodeState{
        function update(node:Node, dt:Number):void;
        function checkStart(node:Node):void;
        function checkEnd(node:Node):void;
        function toJSON(k:String):*;
        function get stateType():String;
        function get enable():Boolean;
    }
}