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
        private var shipsBGBatch:Sprite; // 天体背后常规飞船

        // 背景NORMAL混合层
        private var bgNormalBatch:Sprite;
        private var shipsBGBatchb:Sprite; // 天体背后黑色飞船
        private var nodeBatch:Sprite; // 天体
        private var nodeGlowNormal:Sprite; // 天体光晕(NORMAL部分)

        // 前景ADD混合层
        private var fgAddBatch:Sprite;
        private var nodeGlow:Sprite; // 天体光晕(ADD部分)
        private var shipsFGBatch:Sprite; // 天体前方常规飞船
        private var fx:Sprite; // 特效

        // 前景NORMAL混合层
        private var fgNormalBatch:Sprite;
        private var shipsFGBatchb:Sprite; // 天体前方黑色飞船
        private var labels:Sprite; // 标签

        // 特殊效果层
        private var blackholePulseBatch:Sprite; // 黑洞特效

        public function EntityLayer() {
            blackholePulseBatch = new Sprite();
            blackholePulseBatch.blendMode = BlendMode.MULTIPLY;

            bgAddBatch = new Sprite();
            bgAddBatch.blendMode = BlendMode.ADD;
            shipsBGBatch = new Sprite();
            shipsBGBatch.blendMode = BlendMode.ADD;

            bgNormalBatch = new Sprite();
            bgNormalBatch.blendMode = BlendMode.NORMAL;
            shipsBGBatchb = new Sprite();
            shipsBGBatchb.blendMode = BlendMode.NORMAL;
            nodeBatch = new Sprite();
            nodeGlowNormal = new Sprite();

            fgAddBatch = new Sprite();
            fgAddBatch.blendMode = BlendMode.ADD;
            nodeGlow = new Sprite();
            shipsFGBatch = new Sprite();
            shipsFGBatch.blendMode = BlendMode.ADD;
            fx = new Sprite();

            fgNormalBatch = new Sprite();
            fgNormalBatch.blendMode = BlendMode.NORMAL;
            shipsFGBatchb = new Sprite();
            shipsFGBatchb.blendMode = BlendMode.NORMAL;
            labels = new Sprite();

            register();
        }

        //#region 公共接口
        public function init():void {
            addChild(blackholePulseBatch);

            addChild(bgAddBatch);
            bgAddBatch.addChild(shipsBGBatch);

            addChild(bgNormalBatch);
            bgNormalBatch.addChild(shipsBGBatchb);
            bgNormalBatch.addChild(nodeBatch);
            bgNormalBatch.addChild(nodeGlowNormal);

            addChild(fgAddBatch);
            fgAddBatch.addChild(nodeGlow);
            fgAddBatch.addChild(shipsFGBatch);
            fgAddBatch.addChild(fx);

            addChild(fgNormalBatch);
            fgNormalBatch.addChild(shipsFGBatchb);
            fgNormalBatch.addChild(labels);
            labels.alpha = 1;
        }

        public function deinit():void {
            removeChild(nodeGlow);
            removeChild(nodeBatch);
            removeChild(nodeGlowNormal);
            removeChild(fx);
            removeChild(labels);
            removeChild(blackholePulseBatch);

            Starling.juggler.removeTweens(labels);
        }

        public function invisibleMode():void {
            var batch:MeshBatch;
            Starling.juggler.tween(labels, 5, {"alpha": 0,
                    "delay": 22});
            Starling.juggler.tween(shipsBGBatchb, 5, {"alpha": 0,
                        "delay": 50});
            Starling.juggler.tween(shipsBGBatch, 5, {"alpha": 0,
                        "delay": 50});
            Starling.juggler.tween(shipsFGBatchb, 5, {"alpha": 0,
                        "delay": 50});
            Starling.juggler.tween(shipsFGBatch, 5, {"alpha": 0,
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

        private function addImage(image:Image, foreground:Boolean, deepColor:Boolean):void {
            if (deepColor) {
                if (foreground) {
                    fgNormalBatch.addChild(image);
                } else {
                    bgNormalBatch.addChild(image);
                }
            } else {
                if (foreground) {
                    fgAddBatch.addChild(image);
                } else {
                    bgAddBatch.addChild(image);
                }
            }
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
            blackholePulseBatch.addChild(image);
        }

        private function addFx(image:Image):void {
            fx.addChild(image);
        }
        //#endregion
    }
}
