package Entity.Node.Attack
{
    import Entity.Node
    
    public interface IAttackStrategy{
        function executeAttack(node:Node, dt:Number):void;
        function get attackType():String;
        function set attackTimer(value:Number):void
        function get attackTimer():Number
        function set attackRate(value:Number):void
        function get attackRate():Number
        function set attackRange(value:Number):void
        function get attackRange():Number
        function set attackLast(value:Number):void
        function get attackLast():Number
        function set attacking(value:Boolean):void
        function get attacking():Boolean
    }
}