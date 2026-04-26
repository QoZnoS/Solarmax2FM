package ui.layers {
    import starling.core.Starling;
    import starling.display.BlendMode;
    import starling.display.Image;
    import starling.display.MeshBatch;
    import starling.display.Sprite;

    /** 显示天体和飞船 */
    public class EntityLayer extends Sprite {
        // 背景ADD混合层
        private var bgAddBatch:Sprite;
        private var shipsBGBatchs:Vector.<MeshBatch>; // 天体背后常规飞船

        // 背景NORMAL混合层
        private var bgNormalBatch:Sprite;
        private var shipsBGBatchbs:Vector.<MeshBatch>; // 天体背后黑色飞船
        private var nodeBatch:Sprite; // 天体
        private var nodeGlowNormal:Sprite; // 天体光晕(NORMAL部分)

        // 前景ADD混合层
        private var fgAddBatch:Sprite;
        private var nodeGlow:Sprite; // 天体光晕(ADD部分)
        private var shipsFGBatchs:Vector.<MeshBatch>; // 天体前方常规飞船
        private var fx:MeshBatch; // 特效

        // 前景NORMAL混合层
        private var fgNormalBatch:Sprite;
        private var shipsFGBatchbs:Vector.<MeshBatch>; // 天体前方黑色飞船
        private var labels:Sprite; // 标签

        // 特殊效果层
        private var blackholePulseBatch:MeshBatch; // 黑洞特效

        public function EntityLayer() {
            blackholePulseBatch = new MeshBatch();
            blackholePulseBatch.blendMode = BlendMode.MULTIPLY;

            bgAddBatch = new Sprite();
            bgAddBatch.blendMode = BlendMode.ADD;
            shipsBGBatchs = new Vector.<MeshBatch>();

            bgNormalBatch = new Sprite();
            bgNormalBatch.blendMode = BlendMode.NORMAL;
            shipsBGBatchbs = new Vector.<MeshBatch>();
            nodeBatch = new Sprite();
            nodeGlowNormal = new Sprite();

            fgAddBatch = new Sprite();
            fgAddBatch.blendMode = BlendMode.ADD;
            nodeGlow = new Sprite();
            shipsFGBatchs = new Vector.<MeshBatch>();
            fx = new MeshBatch();

            fgNormalBatch = new Sprite();
            fgNormalBatch.blendMode = BlendMode.NORMAL;
            shipsFGBatchbs = new Vector.<MeshBatch>();
            labels = new Sprite();

            register();
        }

        //#region 公共接口
        public function init():void {
            addChild(blackholePulseBatch);

            addChild(bgAddBatch);
            shipsBGBatchs.push(new MeshBatch());
            bgAddBatch.addChild(shipsBGBatchs[0]);

            addChild(bgNormalBatch);
            shipsBGBatchbs.push(new MeshBatch());
            bgNormalBatch.addChild(shipsBGBatchbs[0]);
            bgNormalBatch.addChild(nodeBatch);
            bgNormalBatch.addChild(nodeGlowNormal);

            addChild(fgAddBatch);
            fgAddBatch.addChild(nodeGlow);
            shipsFGBatchs.push(new MeshBatch());
            fgAddBatch.addChild(shipsFGBatchs[0]);
            fgAddBatch.addChild(fx);

            addChild(fgNormalBatch);
            shipsFGBatchbs.push(new MeshBatch());
            fgNormalBatch.addChild(shipsFGBatchbs[0]);
            fgNormalBatch.addChild(labels);
            labels.alpha = 1;
        }

        public function deinit():void {
            removeBatchVector(shipsBGBatchs);
            removeBatchVector(shipsBGBatchbs);
            removeBatchVector(shipsFGBatchs);
            removeBatchVector(shipsFGBatchbs);

            removeChild(nodeGlow);
            removeChild(nodeBatch);
            removeChild(nodeGlowNormal);
            removeChild(fx);
            removeChild(labels);
            removeChild(blackholePulseBatch);

            Starling.juggler.removeTweens(labels);
        }

        public function reset():void {
            blackholePulseBatch.reset();
            resetBatchVector(shipsBGBatchs);
            resetBatchVector(shipsBGBatchbs);
            resetBatchVector(shipsFGBatchs);
            resetBatchVector(shipsFGBatchbs);
            fx.reset();
        }

        public function invisibleMode():void {
            var batch:MeshBatch;
            Starling.juggler.tween(labels, 5, {"alpha": 0,
                    "delay": 22});
            for each (batch in shipsBGBatchbs)
                Starling.juggler.tween(batch, 5, {"alpha": 0,
                        "delay": 50});
            for each (batch in shipsBGBatchs)
                Starling.juggler.tween(batch, 5, {"alpha": 0,
                        "delay": 50});
            for each (batch in shipsFGBatchbs)
                Starling.juggler.tween(batch, 5, {"alpha": 0,
                        "delay": 50});
            for each (batch in shipsFGBatchs)
                Starling.juggler.tween(batch, 5, {"alpha": 0,
                        "delay": 50});
        }

        //#endregion
        //#region 内部接口
        private function register():void {
            LayerFactory.registerFunction(LayerFactory.ADD_NODE, addNode);
            LayerFactory.registerFunction(LayerFactory.REMOVE_NODE, removeNode);
            LayerFactory.registerFunction(LayerFactory.ADD_GROW, addGlow);
            LayerFactory.registerFunction(LayerFactory.REMOVE_GROW, removeGlow);
            LayerFactory.registerFunction(LayerFactory.ADD_IMAGE, addImage);
            LayerFactory.registerFunction(LayerFactory.ADD_BLACKHOLE, addBlackhole)
            LayerFactory.registerFunction(LayerFactory.ADD_FX, addFx);

            LayerFactory.registerLayer(LayerFactory.LABEL, labels);
        }

        private function removeBatchVector(batches:Vector.<MeshBatch>):void {
            for each (var batch:MeshBatch in batches) {
                Starling.juggler.removeTweens(batch);
                batch.removeFromParent();
            }
            batches.length = 0;
        }

        private function resetBatchVector(batches:Vector.<MeshBatch>):void {
            for each (var batch:MeshBatch in batches)
                batch.reset();
        }

        private function addImage(image:Image, foreground:Boolean, deepColor:Boolean):void {
            if (deepColor) {
                if (foreground) {
                    getEmptyBatch(shipsFGBatchbs, fgNormalBatch).addImage(image);
                } else {
                    getEmptyBatch(shipsBGBatchbs, bgNormalBatch).addImage(image);
                }
            } else {
                if (foreground) {
                    getEmptyBatch(shipsFGBatchs, fgAddBatch).addImage(image);
                } else {
                    getEmptyBatch(shipsBGBatchs, bgAddBatch).addImage(image);
                }
            }
        }

        private function getEmptyBatch(batches:Vector.<MeshBatch>, parent:Sprite):MeshBatch {
            for each (var batch:MeshBatch in batches)
                if (batch.numQuads <= 2048)
                    return batch
            var newBatch:MeshBatch = new MeshBatch();
            batches.push(newBatch);
            parent.addChild(newBatch);
            return newBatch;
        }

        private function addNode(node:Image, halo:Image, glow:Image, deepColor:Boolean):void {
            nodeBatch.addChild(node);
            if (deepColor) {
                nodeGlowNormal.addChild(halo);
                nodeGlowNormal.addChild(glow);
            } else {
                nodeGlow.addChild(halo);
                nodeGlow.addChild(glow);
            }
        }

        private function removeNode(node:Image, halo:Image, glow:Image):void {
            nodeBatch.removeChild(node);
            if (nodeGlowNormal.contains(halo))
                nodeGlowNormal.removeChild(halo);
            if (nodeGlowNormal.contains(glow))
                nodeGlowNormal.removeChild(glow);
            if (nodeGlow.contains(halo))
                nodeGlow.removeChild(halo);
            if (nodeGlow.contains(glow))
                nodeGlow.removeChild(glow);
        }

        private function addGlow(glow:Image, deepColor:Boolean):void {
            if (deepColor)
                nodeGlowNormal.addChild(glow);
            else
                nodeGlow.addChild(glow);
        }

        private function removeGlow(glow:Image):void {
            if (nodeGlowNormal.contains(glow))
                nodeGlowNormal.removeChild(glow);
            if (nodeGlow.contains(glow))
                nodeGlow.removeChild(glow);
        }

        private function addBlackhole(image:Image):void {
            blackholePulseBatch.addImage(image);
        }

        private function addFx(image:Image):void {
            fx.addImage(image);
        }
        //#endregion
    }
}
