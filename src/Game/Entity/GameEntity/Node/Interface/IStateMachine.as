package Game.Entity.GameEntity.Node.Interface
{
    import Game.Entity.GameEntity.Node
    
    public interface IStateMachine{
        function update(node:Node, dt:Number):void;
        function enter(node:Node):void;
        function exit(node:Node):void;
        function get stateType():String;
    }
}