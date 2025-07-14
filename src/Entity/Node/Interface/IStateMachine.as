package Entity.Node.Interface
{
    import Entity.Node
    
    public interface IStateMachine{
        function update(node:Node, dt:Number):void;
        function enter(node:Node):void;
        function exit(node:Node):void;
        function get stateType():String;
    }
}