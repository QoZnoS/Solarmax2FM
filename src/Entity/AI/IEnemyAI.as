package Entity.AI
{
    public interface IEnemyAI {
        function update(dt:Number):void
        function get type():int
        function set type(type:int):void
        function get team():int
        function set team(team:int):void
    }
}