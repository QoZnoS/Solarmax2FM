// 处理各种特效

package Entity
{
    import starling.errors.AbstractClassError;
    import Entity.Node;
    import Entity.Ship;
    import Entity.FX.*;
    import Game.GameScene;

    public class FXHandler{
        public static var game:GameScene;

        public function FXHandler() {
            throw new AbstractClassError();
        }

        public static function addBarrier(x:Number, y:Number, angle:Number, color:uint):void {
            var barrierFX:BarrierFX = EntityContainer.getReserve(EntityContainer.INDEX_BARRIERS) as BarrierFX;
            if (!barrierFX)
                barrierFX = new BarrierFX();
            barrierFX.initBarrier(game, x, y, angle, color);
            EntityContainer.addEntity(EntityContainer.INDEX_BARRIERS, barrierFX);
        }

        public static function addWarp(gameScene:Number, x:Number, y:Number, prevX:Number, prevY:uint, foreground:Boolean):void {
            var warp:WarpFX = EntityContainer.getReserve(EntityContainer.INDEX_WARPS) as WarpFX;
            if (!warp)
                warp = new WarpFX();
            warp.initWarp(game, gameScene, x, y, prevX, prevY, foreground);
            EntityContainer.addEntity(EntityContainer.INDEX_WARPS, warp);
        }

        public static function addBeam(node:Node, ship:Ship):void {
            var beamFX:BeamFX = EntityContainer.getReserve(EntityContainer.INDEX_BEAMS) as BeamFX;
            if (!beamFX)
                beamFX = new BeamFX();
            beamFX.initBeam(game, node.nodeData.x, node.nodeData.y, ship.x, ship.y, Globals.teamColors[node.nodeData.team], node);
            EntityContainer.addEntity(EntityContainer.INDEX_BEAMS, beamFX);
        }

        public static function addLightning(node1:Node, node2:Node, color:uint):void {
            var lightningFX:LightningFX = EntityContainer.getReserve(EntityContainer.INDEX_BEAMS) as LightningFX;
            if (!lightningFX) {
                var imageID:int = Math.floor(Math.random() * 3 + 1);
                lightningFX = new LightningFX(imageID);
            }
            lightningFX.initLightning(game, node1.nodeData.x, node1.nodeData.y, node2.nodeData.x, node2.nodeData.y, color, node1);
            EntityContainer.addEntity(EntityContainer.INDEX_BEAMS, lightningFX);
        }

        public static function addPulse(node:Node, color:uint, type:int, delay:Number = 0):void {
            var nodePulse:NodePulse = EntityContainer.getReserve(EntityContainer.INDEX_PULSES) as NodePulse;
            if (!nodePulse)
                nodePulse = new NodePulse();
            nodePulse.initPulse(game, node, color, type, delay);
            EntityContainer.addEntity(EntityContainer.INDEX_PULSES, nodePulse);
        }

        public static function addDarkPulse(node:Node, color:uint, type:int, maxSize:Number, rate:Number, angle:Number, delay:Number = 0):void {
            var darkPulse:DarkPulse = EntityContainer.getReserve(EntityContainer.INDEX_DARKPLUSES) as DarkPulse;
            if (!darkPulse)
                darkPulse = new DarkPulse();
            darkPulse.initPulse(game, node, color, type, maxSize, rate, angle, delay);
            EntityContainer.addEntity(EntityContainer.INDEX_DARKPLUSES, darkPulse);
        }

        // type 0为扩散式 1为收缩式
        public static function addFade(x:Number, y:Number, size:Number, color:uint, type:int):void {
            var selectFade:SelectFade = EntityContainer.getReserve(EntityContainer.INDEX_FADES) as SelectFade;
            if (!selectFade)
                selectFade = new SelectFade();
            selectFade.initSelectFade(game, x, y, size, color, type);
            EntityContainer.addEntity(EntityContainer.INDEX_FADES, selectFade);
        }

        // 摧毁飞船特效
        public static function addFlash(x:Number, y:Number, color:uint, foreground:Boolean):void {
            var flash:FlashFX = EntityContainer.getReserve(EntityContainer.INDEX_FLASHES) as FlashFX;
            if (!flash)
                flash = new FlashFX();
            flash.initExplosion(game, x, y, color, foreground);
            EntityContainer.addEntity(EntityContainer.INDEX_FLASHES, flash);
        }

        public static function addExplosion(x:Number, y:Number, color:uint, foreground:Boolean):void {
            var explode:ExplodeFX = EntityContainer.getReserve(EntityContainer.INDEX_EXPLOSIONS) as ExplodeFX;
            if (!explode)
                explode = new ExplodeFX();
            explode.initExplosion(game, x, y, color, foreground);
            EntityContainer.addEntity(EntityContainer.INDEX_EXPLOSIONS, explode);
        }

    }
}