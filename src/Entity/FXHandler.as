// 处理各种特效

package Entity {
    import starling.errors.AbstractClassError;
    import Entity.Node;
    import Entity.Ship;
    import Entity.FX.*;
    import Game.GameScene;

    public class FXHandler {
        public static var game:GameScene;

        public function FXHandler() {
            throw new AbstractClassError();
        }
        private static var TEMP_ARRAY:Array = [];
        public static function addBarrier(x:Number, y:Number, angle:Number, color:uint):void {
            TEMP_ARRAY.length = 0;
            TEMP_ARRAY.push(x,y,angle,color);
            ParticleSystem.addParticle("FX", TEMP_ARRAY);
        }

        public static function addWarp(x:Number, y:Number, prevX:Number, prevY:Number, color:uint, foreground:Boolean, deepColor:Boolean):void {
            TEMP_ARRAY.length = 0;
            TEMP_ARRAY.push(x,y,prevX,prevY,color,foreground,deepColor);
            ParticleSystem.addParticle("warp", TEMP_ARRAY);
        }

        public static function addBeam(node:Node, ship:Ship):void {
            var beamFX:BeamFX = EntityContainer.getReserve(EntityContainer.INDEX_BEAMS) as BeamFX;
            if (!beamFX)
                beamFX = new BeamFX();
            beamFX.initBeam(game, node.nodeData.x, node.nodeData.y, ship.x, ship.y, node);
            EntityContainer.addEntity(EntityContainer.INDEX_BEAMS, beamFX);
        }

        public static function addLightning(node1:Node, node2:Node, color:uint, deepColor:Boolean):void {
            var lightningFX:LightningFX = EntityContainer.getReserve(EntityContainer.INDEX_BEAMS) as LightningFX;
            if (!lightningFX) {
                var imageID:int = Math.floor(Math.random() * 3 + 1);
                lightningFX = new LightningFX(imageID);
            }
            lightningFX.initLightning(game, node1.nodeData.x, node1.nodeData.y, node2.nodeData.x, node2.nodeData.y, color, node1, deepColor);
            EntityContainer.addEntity(EntityContainer.INDEX_BEAMS, lightningFX);
        }

        public static function addPulse(node:Node, color:uint, type:int, deepColor:Boolean, delay:Number = 0):void {
            TEMP_ARRAY.length = 0;
            TEMP_ARRAY.push(node, color, type, deepColor, delay);
            ParticleSystem.addParticle("nodePulse", TEMP_ARRAY);
        }

        public static function addDarkPulse(node:Node, color:uint, type:int, maxSize:Number, rate:Number, angle:Number, deepColor:Boolean, delay:Number = 0):void {
            var darkPulse:DarkPulse = EntityContainer.getReserve(EntityContainer.INDEX_DARKPLUSES) as DarkPulse;
            if (!darkPulse)
                darkPulse = new DarkPulse();
            darkPulse.initPulse(game, node, color, type, maxSize, rate, angle, deepColor, delay);
            EntityContainer.addEntity(EntityContainer.INDEX_DARKPLUSES, darkPulse);
        }

        // type 0为扩散式 1为收缩式
        public static function addFade(x:Number, y:Number, size:Number, color:uint, type:int, deepColor:Boolean):void {
            var selectFade:SelectFade = EntityContainer.getReserve(EntityContainer.INDEX_FADES) as SelectFade;
            if (!selectFade)
                selectFade = new SelectFade();
            selectFade.initSelectFade(game, x, y, size, color, type, deepColor);
            EntityContainer.addEntity(EntityContainer.INDEX_FADES, selectFade);
        }

        // 摧毁飞船特效
        public static function addFlash(x:Number, y:Number, color:uint, foreground:Boolean, deepColor:Boolean):void {
            TEMP_ARRAY.length = 0;
            TEMP_ARRAY.push(x,y,color,foreground,deepColor);
            ParticleSystem.addParticle("flash", TEMP_ARRAY);
        }

        public static function addExplosion(x:Number, y:Number, color:uint, foreground:Boolean, deepColor:Boolean):void {
            TEMP_ARRAY.length = 0;
            TEMP_ARRAY.push(x,y,color,foreground,deepColor);
            ParticleSystem.addParticle("explode", TEMP_ARRAY);
        }

    }
}
