package Game.SpecialEvent {
    import Game.GameScene;

    public interface ISpecialEvent {
        function update(dt:Number):void;
        function deinit():void;
        function get type():String;
        function set game(value:GameScene):void;
    }
}
