// 处理各种特效

package Entity
{
    import Game.GameScene;
    import starling.errors.AbstractClassError;
    import Entity.Node;
    import Entity.Ship;
    import Entity.FX.*;

    public class FXHandler{
        public static var game:GameScene;

        public function FXHandler() {
            throw new AbstractClassError();
        }

        public static function addBarrier(_x:Number, _y:Number, _Angle:Number, _Color:uint):void {
            var _BarrierFX:BarrierFX = game.barriers.getReserve() as BarrierFX;
            if (!_BarrierFX)
                _BarrierFX = new BarrierFX();
            _BarrierFX.initBarrier(game, _x, _y, _Angle, _Color);
            game.barriers.addEntity(_BarrierFX);
        }

        public static function addWarp(_GameScene:Number, _x:Number, _y:Number, _prevX:Number, _prevY:uint, _foreground:Boolean):void {
            var _warp:WarpFX = game.warps.getReserve() as WarpFX;
            if (!_warp)
                _warp = new WarpFX();
            _warp.initWarp(game, _GameScene, _x, _y, _prevX, _prevY, _foreground);
            game.warps.addEntity(_warp);
        }

        public static function addBeam(_Node:Node, _Ship:Ship):void {
            var _BeamFX:BeamFX = game.beams.getReserve() as BeamFX;
            if (!_BeamFX)
                _BeamFX = new BeamFX();
            _BeamFX.initBeam(game, _Node.x, _Node.y, _Ship.x, _Ship.y, Globals.teamColors[_Node.team], _Node);
            game.beams.addEntity(_BeamFX);
        }

        public static function addPulse(_Node:Node, _Color:uint, _type:int, _delay:Number = 0):void {
            var _NodePulse:NodePulse = game.pulses.getReserve() as NodePulse;
            if (!_NodePulse)
                _NodePulse = new NodePulse();
            _NodePulse.initPulse(game, _Node, _Color, _type, _delay);
            game.pulses.addEntity(_NodePulse);
        }

        public static function addDarkPulse(_Node:Node, _Color:uint, _type:int, _maxSize:Number, _rate:Number, _angle:Number, _delay:Number = 0):void {
            var _DarkPulse:DarkPulse = game.darkPulses.getReserve() as DarkPulse;
            if (!_DarkPulse)
                _DarkPulse = new DarkPulse();
            _DarkPulse.initPulse(game, _Node, _Color, _type, _maxSize, _rate, _angle, _delay);
            game.darkPulses.addEntity(_DarkPulse);
        }

        // type 0为扩散式 1为收缩式
        public static function addFade(_x:Number, _y:Number, _size:Number, _color:uint, _type:int):void {
            var _SelectFade:SelectFade = game.fades.getReserve() as SelectFade;
            if (!_SelectFade)
                _SelectFade = new SelectFade();
            _SelectFade.initSelectFade(game, _x, _y, _size, _color, _type);
            game.fades.addEntity(_SelectFade);
        }

        // 摧毁飞船特效
        public static function addFlash(_x:Number, _y:Number, _Color:uint, _foreground:Boolean):void {
            var _Flash:FlashFX = game.explosions.getReserve() as FlashFX;
            if (!_Flash)
                _Flash = new FlashFX();
            _Flash.initExplosion(game, _x, _y, _Color, _foreground);
            game.flashes.addEntity(_Flash);
        }

        public static function addExplosion(_x:Number, _y:Number, _Color:uint, _foreground:Boolean):void {
            var _Explode:ExplodeFX = game.explosions.getReserve() as ExplodeFX;
            if (!_Explode)
                _Explode = new ExplodeFX();
            _Explode.initExplosion(game, _x, _y, _Color, _foreground);
            game.explosions.addEntity(_Explode);
        }

    }
}