package scenes.menus {
    import starling.display.Sprite;
    import starling.core.Starling;
    import managers.Globals;
    import starling.display.Image;
    import starling.display.BlendMode;
    import starling.events.TouchEvent;
    import starling.events.Touch;
    import flash.events.MouseEvent;
    import flash.geom.Rectangle;
    import starling.text.TextField;
    import starling.display.Quad;

    public class TeamEditorMenu extends Sprite implements IMenu {

        // 图层结构：此菜单为根
        private var listBox:Sprite; // 遮罩层 - 包含竖向滚动内容
        private var listLayer:Sprite; // 竖向滚动层 - 包含预览图
        private var previewLayer:Sprite; // 预览内容层

        private var dataBarBox:Sprite; // 信息栏顶部遮罩层
        private var dataBar:Sprite; // 信息栏标题层

        private var dataBox:Sprite; // 信息栏遮罩层 - 支持横向滚动
        private var dataLayer:Sprite; // 信息内容层

        // 预览数据
        private var previewImages:Array; // [[node, halo], ...]
        private var dataList:Array; // 信息数据
        private var grids:Array;

        // 触摸状态
        private var touchStartY:Number;
        private var touchStartX:Number;
        private var lastListLayerY:Number;
        private var lastDataLayerX:Number;
        private var activeTouchLayer:String; // "list" 或 "data" 用于区分当前触摸的是哪个图层

        public function TeamEditorMenu() {
            previewImages = [];
            dataList = [];
            grids = [];
            init();
        }

        public function init():void {
            // 初始化列表区域（左侧，竖向滚动）
            listBox = new Sprite();
            listBox.clipRect = new Rectangle(154, 168, 870, 486);
            listLayer = new Sprite();
            previewLayer = new Sprite();
            
            addChild(listBox);
            listBox.addChild(listLayer);
            listLayer.addChild(previewLayer);

            // 初始化信息栏顶部（右上）
            dataBarBox = new Sprite();
            dataBarBox.clipRect = new Rectangle(240, 0, 752, 660);
            dataBar = new Sprite();
            
            addChild(dataBarBox);
            dataBarBox.addChild(dataBar);

            // 初始化信息栏（右下，横向和竖向滚动）
            dataBox = new Sprite();
            dataBox.clipRect = new Rectangle(240, 168, 752, 486);
            dataLayer = new Sprite();
            
            addChild(dataBox);
            dataBox.addChild(dataLayer);

            dataLayer.x = dataBar.x = 240; // 初始位置与遮罩对齐
            dataLayer.y = listLayer.y - 18;

            // 初始化数据
            dataList.push(["Color", "DeepColor", "ColorEnhance", "ShipSpeed", "ShipAttack", "ShipDefence", "RepairingSpeed", "ColonizingSpeed", "DestroyingSpeed", "DecolonizingSpeed", "ConstructionStrength", "NodeBuild", "NodePop", "ShowLabel"])
            for (var i:int = 0; i < dataList[0].length; i++) {
                var label:TextField = new TextField(160, 40, dataList[0][i], "Downlink18", -1, 0xFF9DBB);
                label.x = i * 160;
                label.y = 120;
                dataBar.addChild(label);
            }
            var quad1:Quad = new Quad(1024, 4, 0xFFFFFF);
            quad1.alpha = 0.6;
            quad1.x = 154;
            quad1.y = 164;
            addChild(quad1);
            var quad2:Quad = new Quad(4, 540, 0xFFFFFF);
            quad2.alpha = 0.6;
            quad2.x = 236;
            quad2.y = 114;
            addChild(quad2);
        }

        public function refresh():void {
            if (previewImages.length != 0)
                for each (var team:Array in previewImages)
                    for each (var img:Image in team)
                        previewLayer.removeChild(img);
            if (grids.length != 0)
                for each (var grid:Quad in grids)
                    dataLayer.removeChild(grid);
            previewImages.length = 0;
            grids.length = 0;
            dataList.length = 1; // 保留标题行，清空数据行
            for (var i:int = 0; i < Globals.teamCount; i++) {
                previewImages.push([]);
                var imageID:String = (Math.random() * 16 + 1 >> 0) + "";
                if (imageID.length == 1)
                    imageID = "0" + imageID; // 随机取一个星球贴图的编号
                previewImages[i].push(new Image(Root.assets.getTexture("planet" + imageID)));
                previewImages[i].push(new Image(Root.assets.getTexture("halo")));
                for (var j:int = 0; j < previewImages[i].length; j++) {
                    previewImages[i][j].pivotX = previewImages[i][j].pivotY = previewImages[i][j].width / 2;
                    previewImages[i][j].x = 200;
                    previewImages[i][j].y = 200 + i * 100;
                    previewImages[i][j].color = Globals.teamColors[i];
                    previewLayer.addChild(previewImages[i][j]);
                }
                previewImages[i][0].scaleX = previewImages[i][0].scaleY = 0.5;
                previewImages[i][1].scaleX = previewImages[i][1].scaleY = 0.25;
                previewImages[i][1].blendMode = Globals.teamDeepColors[i] ? BlendMode.NORMAL : BlendMode.ADD;

                dataList.push([Globals.teamColors[i], Globals.teamDeepColors[i], Globals.teamColorEnhances[i], Globals.teamShipSpeeds[i], Globals.teamShipAttacks[i], Globals.teamShipDefences[i], Globals.teamRepairingSpeeds[i], Globals.teamColonizingSpeeds[i], Globals.teamDestroyingSpeeds[i], Globals.teamDecolonizingSpeeds[i], Globals.teamConstructionStrengths[i], Globals.teamNodeBuilds[i], Globals.teamNodePops[i], Globals.teamShowLabels[i]]);
                for (j = 0; j < dataList[i + 1].length; j++) {
                    var dataLabel:TextField = new TextField(160, 40, String(dataList[i + 1][j]), "Downlink18", -1, 0xFFFFFF);
                    if (j == 0) {
                        dataLabel.text = "0x" + uint(dataList[i + 1][j]).toString(16).toUpperCase();
                        dataLabel.color = Globals.teamColors[i];
                    }
                    dataLabel.x = j * 160;
                    dataLabel.y = 200 + i * 100;
                    dataLayer.addChild(dataLabel);
                }
                
                var gridLine:Quad = new Quad(1024, 2, 0xFFFFFF);
                gridLine.alpha = 0.4;
                gridLine.y = 250 + i * 100;
                listLayer.addChild(gridLine);
                grids.push(gridLine);
            }
            for (i = 0; i < dataList[0].length; i++) {
                var gridCol:Quad = new Quad(2, 540, 0xFFFFFF);
                gridCol.alpha = 0.4;
                gridCol.x = 160 + i * 160;
                gridCol.y = 120;
                dataBar.addChild(gridCol);
                grids.push(gridCol);
            }
        }

        public function animateIn():void {
            refresh();
            this.visible = true;
            Starling.juggler.removeTweens(this);
            Starling.juggler.tween(this, 0.15, {"alpha": 1});
            
            // 添加事件监听
            Starling.current.nativeStage.addEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);
            listBox.addEventListener(TouchEvent.TOUCH, onListTouch);
            dataBox.addEventListener(TouchEvent.TOUCH, onDataTouch);
        }

        public function animateOut():void {
            Starling.juggler.removeTweens(this);
            Starling.juggler.tween(this, 0.15, {"alpha": 0,
                    "onComplete": hide});
            
            // 移除事件监听
            Starling.current.nativeStage.removeEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);
            listBox.removeEventListener(TouchEvent.TOUCH, onListTouch);
            dataBox.removeEventListener(TouchEvent.TOUCH, onDataTouch);
        }

        public function hide():void {
            this.visible = false;
        }

        public function deinit():void {
        }

        // ==================== 鼠标滚轮事件 ====================
        private function onMouseWheel(event:MouseEvent):void {
            // 检测 Shift 键状态
            var scrollAmount:Number = event.delta > 0 ? 60 : -60;
            
            if (event.shiftKey) {
                // 按住 Shift：横向滑动 dataLayer
                dataLayer.x += scrollAmount;
                dataBar.x += scrollAmount; // 同步移动标题栏
            } else {
                // 正常滚轮：竖向滑动 listLayer
                listLayer.y += scrollAmount;
                dataLayer.y += scrollAmount; // 同步移动信息栏内容
            }
            onBoundary();
        }

        // ==================== 列表区域触摸事件（竖向滑动）====================
        private function onListTouch(event:TouchEvent):void {
            var touch:Touch = event.getTouch(listBox);
            if (!touch) return;

            if (touch.phase == "began") {
                touchStartY = touch.globalY;
                lastListLayerY = listLayer.y;
                activeTouchLayer = "list";
            } else if (touch.phase == "moved" && activeTouchLayer == "list") {
                var deltaY:Number = touch.globalY - touchStartY;
                listLayer.y = lastListLayerY + deltaY;
                dataLayer.y = lastListLayerY + deltaY - 18; // 同步移动信息栏内容
            } else if (touch.phase == "ended" || touch.phase == "cancelled") {
                activeTouchLayer = null;
            }
            onBoundary();
        }

        // ==================== 信息区域触摸事件（横向和竖向滑动）====================
        private function onDataTouch(event:TouchEvent):void {
            var touch:Touch = event.getTouch(dataBox);
            if (!touch) return;

            if (touch.phase == "began") {
                touchStartX = touch.globalX;
                touchStartY = touch.globalY;
                lastDataLayerX = dataLayer.x;
                lastListLayerY = listLayer.y;
                activeTouchLayer = "data";
            } else if (touch.phase == "moved" && activeTouchLayer == "data") {
                var deltaX:Number = touch.globalX - touchStartX;
                var deltaY:Number = touch.globalY - touchStartY;
                
                dataLayer.x = lastDataLayerX + deltaX;
                dataBar.x = lastDataLayerX + deltaX; // 同步移动标题栏
                dataLayer.y = lastListLayerY + deltaY - 18;
                listLayer.y = lastListLayerY + deltaY;
            } else if (touch.phase == "ended" || touch.phase == "cancelled") {
                activeTouchLayer = null;
            }
            onBoundary();
        }

        private function onBoundary():void {
            // 限制 listLayer 的竖向滚动范围
            if (listLayer.y > 12) {
                listLayer.y = 12;
                dataLayer.y = 12 - 18; // 同步调整信息栏内容位置
            } else if (listLayer.y < 12 - (listLayer.height - 420)) {
                listLayer.y = 12 - (listLayer.height - 420);
                dataLayer.y = listLayer.y - 18; // 同步调整信息栏内容位置
            }

            // 限制 dataLayer 的横向滚动范围
            if (dataLayer.x > 240) {
                dataLayer.x = 240;
                dataBar.x = 240; // 同步调整标题栏位置
            } else if (dataLayer.x < 240 - (dataLayer.width - 752)) {
                dataLayer.x = 240 - (dataLayer.width - 752);
                dataBar.x = dataLayer.x; // 同步调整标题栏位置
            }
        }
    }
}
