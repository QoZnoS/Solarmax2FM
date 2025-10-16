package Menus.StartMenus {

    public interface IMenu{
        function init():void
        function deinit():void
        function animateIn():void
        function animateOut():void

        function get x():Number;
        function set x(value:Number):void;

        function get y():Number;
        function set y(value:Number):void;

        function get pivotX():Number;
        function set pivotX(value:Number):void;

        function get pivotY():Number;
        function set pivotY(value:Number):void;

        function get visible():Boolean;
    }
}
