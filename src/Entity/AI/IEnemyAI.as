package Entity.AI
{
    public interface IEnemyAI {
        function update(dt:Number):void
        function get type():String
        function set team(team:int):void
        function get team():int
    }
}