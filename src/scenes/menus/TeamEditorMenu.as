package scenes.menus {
    import starling.display.Sprite;
    import starling.core.Starling;
    import managers.Globals;
    import starling.display.Image;
    import starling.display.BlendMode;
    import starling.events.TouchEvent;
    import starling.events.Touch;
    import flash.events.MouseEvent;
    import starling.text.TextField;
    import starling.display.Quad;
    import utils.ShadowLabel;
    import starling.text.TextFormat;
    import core.node.NodeStaticLogic;

    public class TeamEditorMenu extends Sprite implements IMenu {
        
        // ==================== 几何尺寸常量 ====================
        private static const LIST_BOX_X:int = 154;
        private static const LIST_BOX_Y:int = 168;
        private static const LIST_BOX_WIDTH:int = 870;
        private static const LIST_BOX_HEIGHT:int = 486;
        
        private static const DATA_BAR_BOX_X:int = 244;
        private static const DATA_BAR_BOX_Y:int = 0;
        private static const DATA_BAR_BOX_WIDTH:int = 752;
        private static const DATA_BAR_BOX_HEIGHT:int = 660;
        
        private static const DATA_BOX_X:int = 244;
        private static const DATA_BOX_Y:int = 168;
        private static const DATA_BOX_WIDTH:int = 752;
        private static const DATA_BOX_HEIGHT:int = 486;
        
        private static const QUAD1_X:int = 154;
        private static const QUAD1_Y:int = 164;
        private static const QUAD1_WIDTH:int = 1024;
        private static const QUAD1_HEIGHT:int = 4;
        
        private static const QUAD2_X:int = 240;
        private static const QUAD2_Y:int = 114;
        private static const QUAD2_WIDTH:int = 4;
        private static const QUAD2_HEIGHT:int = 540;
        
        private static const PREVIEW_IMAGE_X:int = 200;
        private static const PREVIEW_IMAGE_BASE_Y:int = 200;
        private static const PREVIEW_IMAGE_Y_SPACING:int = 100;
        
        private static const DATA_LABEL_WIDTH:int = 150;
        private static const DATA_LABEL_HEIGHT:int = 60;
        private static const DATA_LABEL_X_SPACING:int = 160;
        private static const DATA_LABEL_BASE_Y:int = 200;
        
        private static const GRID_LINE_WIDTH:int = 1024;
        private static const GRID_LINE_HEIGHT:int = 2;
        private static const GRID_LINE_BASE_Y:int = 250;
        
        private static const GRID_COL_WIDTH:int = 2;
        private static const GRID_COL_HEIGHT:int = 540;
        private static const GRID_COL_BASE_X:int = 160;
        private static const GRID_COL_X_SPACING:int = 160;
        private static const GRID_COL_Y:int = 114;
        
        private static const DATA_BAR_X:int = 244;
        private static const DATA_BAR_TITLE_Y:int = 108;
        private static const DATA_LAYER_Y_OFFSET:int = -32;
        
        private static const LIST_LAYER_MAX_Y:int = 12;
        private static const LIST_LAYER_MIN_HEIGHT_DIFF:int = 420;
        
        private static const DATA_LAYER_MAX_X:int = 244;
        private static const DATA_LAYER_MIN_WIDTH_DIFF:int = 752;
        
        // ==================== 颜色常量 ====================
        private static const WHITE_COLOR:uint = 0xFFFFFF;
        private static const TITLE_TEXT_COLOR:uint = 0xFF9DBB;
        private static const DATA_TEXT_COLOR:uint = 0xFFFFFF;
        
        // ==================== 透明度常量 ====================
        private static const QUAD1_ALPHA:Number = 0.6;
        private static const QUAD2_ALPHA:Number = 0.6;
        private static const GRID_LINE_ALPHA:Number = 0.4;
        private static const GRID_COL_ALPHA:Number = 0.4;
        
        // ==================== 动画常量 ====================
        private static const ANIMATION_DURATION:Number = 0.15;
        
        // ==================== 滚动常量 ====================
        private static const MOUSE_WHEEL_SCROLL_AMOUNT:int = 60;
        
        // ==================== 索引常量 ====================
        private static const DATA_COLOR_INDEX:int = 0;
        private static const PLANET_TEXTURE_PADDING_DIGITS:int = 2;
        
        // ==================== 缩放常量 ====================
        private static const PLANET_IMAGE_SCALE:Number = 0.5;
        private static const HALO_IMAGE_SCALE:Number = 0.25;

        // 图层结构：此菜单为根
        private var listBox:Sprite; // 遮罩层 - 包含竖向滚动内容
        private var listLayer:Sprite; // 竖向滚动层 - 包含预览图
        private var previewLayer:Sprite; // 预览内容层

        private var dataBarBox:Sprite; // 信息栏顶部遮罩层
        private var dataBar:Sprite; // 信息栏标题层

        private var dataBox:Sprite; // 信息栏遮罩层 - 支持横向滚动
        private var dataLayer:Sprite; // 信息内容层

        // 2.8 特供遮罩 以后再重构
        private var listMask:Quad;
        private var dataBarMask:Quad;
        private var dataMask:Quad;

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
            listLayer = new Sprite();
            previewLayer = new Sprite();
            listMask = new Quad(LIST_BOX_WIDTH, LIST_BOX_HEIGHT, 0x0);
            listMask.x = LIST_BOX_X;
            listMask.y = LIST_BOX_Y;
            listBox.mask = listMask;
            
            addChild(listBox);
            listBox.addChild(listLayer);
            listLayer.addChild(previewLayer);

            // 初始化信息栏顶部（右上）
            dataBarBox = new Sprite();
            dataBar = new Sprite();
            dataBarMask = new Quad(DATA_BAR_BOX_WIDTH, DATA_BAR_BOX_HEIGHT, 0x0);
            dataBarMask.x = DATA_BAR_BOX_X;
            dataBarMask.y = DATA_BAR_BOX_Y;
            dataBarBox.mask = dataBarMask;
            
            addChild(dataBarBox);
            dataBarBox.addChild(dataBar);

            // 初始化信息栏（右下，横向和竖向滚动）
            dataBox = new Sprite();
            dataLayer = new Sprite();
            dataMask = new Quad(DATA_BOX_WIDTH, DATA_BOX_HEIGHT, 0x0);
            dataMask.x = DATA_BOX_X;
            dataMask.y = DATA_BOX_Y;
            dataBox.mask = dataMask;
            
            addChild(dataBox);
            dataBox.addChild(dataLayer);

            listLayer.y = LIST_LAYER_MAX_Y;
            dataLayer.x = dataBar.x = DATA_BAR_X;
            dataLayer.y = listLayer.y + DATA_LAYER_Y_OFFSET;

            // 初始化数据
            dataList.push(["Color", "DeepColor", "ColorEnhance", "ShipSpeed", "ShipAttack", "ShipDefence", "Repairing\nSpeed", "Colonizing\nSpeed", "Destroying\nSpeed", "Decolonizing\nSpeed", "Construction\nStrength", "NodeBuild", "NodePop", "ShowLabel"])
            for (var i:int = 0; i < dataList[0].length; i++) {
                var label:ShadowLabel = new ShadowLabel(DATA_LABEL_WIDTH, DATA_LABEL_HEIGHT, dataList[0][i], new TextFormat("downlink", 18, TITLE_TEXT_COLOR));
                label.x = i * DATA_LABEL_X_SPACING + 5;
                label.y = DATA_BAR_TITLE_Y;
                dataBar.addChild(label);
            }
            var quad1:Quad = new Quad(QUAD1_WIDTH, QUAD1_HEIGHT, WHITE_COLOR);
            quad1.alpha = QUAD1_ALPHA;
            quad1.x = QUAD1_X;
            quad1.y = QUAD1_Y;
            addChild(quad1);
            var quad2:Quad = new Quad(QUAD2_WIDTH, QUAD2_HEIGHT, WHITE_COLOR);
            quad2.alpha = QUAD2_ALPHA;
            quad2.x = QUAD2_X;
            quad2.y = QUAD2_Y;
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
            if (dataList.length != 1)
                for (var i:int = 1; i < dataList.length; i++)
                    for (var j:int = 0; j < dataList[i].length; j++)
                        dataLayer.removeChildAt(0);
            previewImages.length = 0;
            grids.length = 0;
            dataList.length = 1; // 保留标题行，清空数据行
            for (i = 0; i < Globals.teamCount; i++) {
                previewImages.push([]);
                previewImages[i].push(new Image(Root.assets.getTexture(NodeStaticLogic.getRandomPlanetImage())));
                previewImages[i].push(new Image(Root.assets.getTexture("halo")));
                for (j = 0; j < previewImages[i].length; j++) {
                    previewImages[i][j].pivotX = previewImages[i][j].pivotY = previewImages[i][j].width / 2;
                    previewImages[i][j].x = PREVIEW_IMAGE_X;
                    previewImages[i][j].y = PREVIEW_IMAGE_BASE_Y + i * PREVIEW_IMAGE_Y_SPACING;
                    previewImages[i][j].color = Globals.teamColors[i];
                    previewLayer.addChild(previewImages[i][j]);
                }
                previewImages[i][0].scaleX = previewImages[i][0].scaleY = PLANET_IMAGE_SCALE;
                previewImages[i][1].scaleX = previewImages[i][1].scaleY = HALO_IMAGE_SCALE;
                previewImages[i][1].blendMode = Globals.teamDeepColors[i] ? BlendMode.NORMAL : BlendMode.ADD;

                dataList.push([Globals.teamColors[i], Globals.teamDeepColors[i], Globals.teamColorEnhances[i], Globals.teamShipSpeeds[i], Globals.teamShipAttacks[i], Globals.teamShipDefences[i], Globals.teamRepairingSpeeds[i], Globals.teamColonizingSpeeds[i], Globals.teamDestroyingSpeeds[i], Globals.teamDecolonizingSpeeds[i], Globals.teamConstructionStrengths[i], Globals.teamNodeBuilds[i], Globals.teamNodePops[i], Globals.teamShowLabels[i]]);
                for (j = 0; j < dataList[i + 1].length; j++) {
                    var dataLabel:TextField = new TextField(DATA_LABEL_WIDTH, DATA_LABEL_HEIGHT, String(dataList[i + 1][j]));
                    dataLabel.format.setTo("downlink", 18, DATA_TEXT_COLOR);
                    if (j == DATA_COLOR_INDEX) {
                        dataLabel.text = "0x" + uint(dataList[i + 1][j]).toString(16).toUpperCase();
                        dataLabel.format.color = Globals.teamColors[i];
                    }
                    dataLabel.x = j * DATA_LABEL_X_SPACING + 5;
                    dataLabel.y = DATA_LABEL_BASE_Y + i * PREVIEW_IMAGE_Y_SPACING;
                    dataLayer.addChild(dataLabel);
                }
                
                var gridLine:Quad = new Quad(GRID_LINE_WIDTH, GRID_LINE_HEIGHT, WHITE_COLOR);
                gridLine.alpha = GRID_LINE_ALPHA;
                gridLine.y = GRID_LINE_BASE_Y + i * PREVIEW_IMAGE_Y_SPACING;
                listLayer.addChild(gridLine);
                grids.push(gridLine);
            }
            for (i = 0; i < dataList[0].length; i++) {
                var gridCol:Quad = new Quad(GRID_COL_WIDTH, GRID_COL_HEIGHT, WHITE_COLOR);
                gridCol.alpha = GRID_COL_ALPHA;
                gridCol.x = GRID_COL_BASE_X + i * GRID_COL_X_SPACING;
                gridCol.y = GRID_COL_Y;
                dataBar.addChild(gridCol);
                grids.push(gridCol);
            }
        }

        public function animateIn():void {
            refresh();
            this.visible = true;
            Starling.juggler.removeTweens(this);
            Starling.juggler.tween(this, ANIMATION_DURATION, {"alpha": 1});
            
            // 添加事件监听
            Starling.current.nativeStage.addEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);
            listBox.addEventListener(TouchEvent.TOUCH, onListTouch);
            dataBox.addEventListener(TouchEvent.TOUCH, onDataTouch);
        }

        public function animateOut():void {
            Starling.juggler.removeTweens(this);
            Starling.juggler.tween(this, ANIMATION_DURATION, {"alpha": 0,
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
            var scrollAmount:Number = event.delta > 0 ? MOUSE_WHEEL_SCROLL_AMOUNT : -MOUSE_WHEEL_SCROLL_AMOUNT;
            
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
                dataLayer.y = lastListLayerY + deltaY + DATA_LAYER_Y_OFFSET; // 同步移动信息栏内容
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
                dataLayer.y = lastListLayerY + deltaY + DATA_LAYER_Y_OFFSET;
                listLayer.y = lastListLayerY + deltaY;
            } else if (touch.phase == "ended" || touch.phase == "cancelled") {
                activeTouchLayer = null;
            }
            onBoundary();
        }

        private function onBoundary():void {
            // 限制 listLayer 的竖向滚动范围
            if (listLayer.y > LIST_LAYER_MAX_Y) {
                listLayer.y = LIST_LAYER_MAX_Y;
                dataLayer.y = LIST_LAYER_MAX_Y + DATA_LAYER_Y_OFFSET; // 同步调整信息栏内容位置
            } else if (listLayer.y < LIST_LAYER_MAX_Y - (listLayer.height - LIST_LAYER_MIN_HEIGHT_DIFF)) {
                listLayer.y = LIST_LAYER_MAX_Y - (listLayer.height - LIST_LAYER_MIN_HEIGHT_DIFF);
                dataLayer.y = listLayer.y + DATA_LAYER_Y_OFFSET; // 同步调整信息栏内容位置
            }

            // 限制 dataLayer 的横向滚动范围
            if (dataLayer.x > DATA_LAYER_MAX_X) {
                dataLayer.x = DATA_LAYER_MAX_X;
                dataBar.x = DATA_LAYER_MAX_X; // 同步调整标题栏位置
            } else if (dataLayer.x < DATA_LAYER_MAX_X - (dataLayer.width - DATA_LAYER_MIN_WIDTH_DIFF)) {
                dataLayer.x = DATA_LAYER_MAX_X - (dataLayer.width - DATA_LAYER_MIN_WIDTH_DIFF);
                dataBar.x = dataLayer.x; // 同步调整标题栏位置
            }
        }
    }
}