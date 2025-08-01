package Entity.Node.States
{
    import Entity.Node
    
    public interface INodeState{
        function update(node:Node, dt:Number):void;
        function checkEnter(node:Node):Boolean;
        function checkExit(node:Node):Boolean;
        function get stateType():String;
    }
}