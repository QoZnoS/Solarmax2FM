package Menus {
    import flash.desktop.NativeApplication;
    import flash.geom.Point;
    import starling.core.Starling;
    import starling.display.Image;
    import starling.display.Quad;
    import starling.display.QuadBatch;
    import starling.display.Sprite;
    import starling.events.EnterFrameEvent;
    import starling.events.Event;
    import starling.events.Touch;
    import starling.events.TouchEvent;
    import starling.text.TextField;
    import utils.GS;
    import UI.Component.MenuButton;
    import UI.Component.LevelButtons;
    import UI.Component.DifficultyButton;
    import utils.Drawer;
    import UI.UIContainer;
    import starling.utils.HAlign;
    import starling.utils.VAlign;
    import starling.display.BlendMode;
    import Entity.Node.NodeType;

    public class TitleMenu extends Sprite {
        public var cover:Quad; // 进入游戏和通关36时的白光遮罩
        public var title:Image; // Solarmax2 标题
        public var title_blur:Image; // Solarmax2 标题模糊光圈
        public var credits:Array; // 显示作者信息
        public var previewBox:Sprite; // 预览信息根图层，不受scale影响
        public var previewLayer:Sprite; // 天体预览图层
        public var uiLayer:Sprite;
        public var levels:LevelButtons;
        public var deltaScroll:Point;
        public var mouseDown:Boolean;
        public var quad:Quad;
        public var bQuad:Quad;
        public var touchQuad:Quad;
        public var selector:QuadBatch;
        public var preview:QuadBatch;
        public var preview2:QuadBatch;
        public var previewQuad:QuadBatch;
        public var quadImage:Image;
        public var shapeImage:Image;
        public var menuBtn:MenuButton;
        public var editorBtn:MenuButton;
        public var optionsMenu:StartMenu;
        public var currentIndex:int;
        public var barrierData:Array; // 三维数组，第一层为关卡，第二层为障碍线，第三层为 [中点X，中点Y，距离，角度]
        public var orbitData:Array; // 三维数组，第一层为关卡，第二层为轨道，第三层为 [中心，距离]
        public var difficultyButtons:Array;
        public var difficultyHolder:Sprite;
        public var starIcon:Image;
        public var starLabel:TextField;

        private var downIndex:int;
        private var dragging:Boolean;
        private var hoverIndex:int;
        public var scene:SceneController;

        private var infoTexts:Vector.<TextField> = new Vector.<TextField>();

        public function TitleMenu(sce:SceneController) {
            this.scene = sce;
            var i:int = 0;
            dragging = false;
            hoverIndex = -1;
            super();
            quad = new Quad(2, 2, 16777215);
            quadImage = new Image(Root.assets.getTexture("quad8x4"));
            quadImage.adjustVertices();
            deltaScroll = new Point(0, 0);
            previewBox = new Sprite();
            previewLayer = new Sprite();
            uiLayer = new Sprite();
            addChild(previewBox);
            previewBox.addChild(previewLayer);
            addChild(uiLayer);
            // 障碍线预览
            bQuad = new Quad(160, 6, 16733525);
            bQuad.pivotX = 80;
            bQuad.pivotY = 3;
            bQuad.alpha = 1;
            // 
            title = new Image(Root.assets.getTexture("title_logo"));
            title.pivotX = title.width * 0.5;
            title.pivotY = title.height * 0.5;
            title.x = 512;
            title.y = 384;
            title.color = 16755370;
            title.alpha = 0.5;
            title.blendMode = "add";
            addChild(title);
            title_blur = new Image(Root.assets.getTexture("title_logo_blur"));
            title_blur.pivotX = title.width * 0.5;
            title_blur.pivotY = title.height * 0.5;
            title_blur.x = 512;
            title_blur.y = 384;
            title_blur.color = 16755370;
            title_blur.alpha = 0.3;
            title_blur.blendMode = "add";
            addChild(title_blur);
            credits = [];
            credits.push(new TextField(600, 40, "CREATED BY NICO TUASON", "Downlink12", -1, 16755370));
            credits.push(new TextField(600, 40, "MODIFIED BY QoZnoS", "Downlink12", -1, 16755370));
            for (i = 0; i < credits.length; i++) // 留作彩蛋 :P
            {
                credits[i].pivotX = 300;
                credits[i].pivotY = 20;
                credits[i].x = title.x;
                credits[i].y = title.y + 20 * i + 50;
                credits[i].blendMode = "add";
                credits[i].alpha = 0.2;
            }
            levels = new LevelButtons();
            levels.x = title.x;
            levels.y = title.y + 200;
            addChild(levels);
            preview = new QuadBatch();
            preview.blendMode = "add";
            preview.alpha = 0.4;
            previewLayer.addChild(preview);
            preview2 = new QuadBatch();
            preview2.alpha = 0.8;
            previewLayer.addChild(preview2);
            previewQuad = new QuadBatch();
            previewQuad.blendMode = "add";
            previewQuad.alpha = 0.4;
            previewLayer.addChild(previewQuad);
            previewBox.x = previewBox.pivotX = 512;
            previewBox.y = previewBox.pivotY = 384;
            previewBox.y -= 30;
            previewBox.scaleX = previewBox.scaleY = 0.7;
            previewLayer.x = previewLayer.pivotX = 512;
            previewLayer.y = previewLayer.pivotY = 384;
            shapeImage = new Image(Root.assets.getTexture("planet_shape"));
            shapeImage.pivotX = shapeImage.pivotY = shapeImage.width * 0.5;
            selector = new QuadBatch();
            Drawer.drawCircle(selector, 0, 0, 16755370, 48, 46);
            selector.x = title.x;
            selector.y = levels.y - 1;
            selector.blendMode = "add";
            selector.alpha = 0;
            addChild(selector);
            cover = new Quad(1024, 768, 16777215);
            cover.blendMode = "add";
            cover.touchable = false;
            addChild(cover);
            touchQuad = new Quad(1024, 768, 16711680);
            touchQuad.alpha = 0;
            addChild(touchQuad);
            difficultyHolder = new Sprite();
            difficultyButtons = [];
            var dBtn:DifficultyButton = null;
            for (i = 0; i < 3; i++) {
                dBtn = new DifficultyButton(i, difficultyButtons);
                dBtn.x = i * 100;
                difficultyHolder.addChild(dBtn);
                difficultyButtons.push(dBtn);
            }
            difficultyHolder.x = 412;
            difficultyHolder.y = 150;
            addChild(difficultyHolder);
            starLabel = new TextField(120, 40, "0", "Downlink22", -1, 16755370);
            starLabel.hAlign = "right";
            starLabel.pivotX = 120;
            starLabel.pivotY = 20;
            starLabel.y = 137;
            starLabel.x = 974 - Globals.margin;
            starLabel.blendMode = "add";
            starLabel.alpha = 0.5;
            addChild(starLabel);
            starIcon = new Image(Root.assets.getTexture("star"));
            starIcon.pivotX = starIcon.width * 0.5;
            starIcon.pivotY = starIcon.height * 0.5;
            starIcon.y = 136;
            starIcon.x = 994 - Globals.margin;
            starIcon.alpha = 0.4;
            starIcon.blendMode = "add";
            addChild(starIcon);
            menuBtn = new MenuButton("btn_menu");
            menuBtn.x = 15 + Globals.margin;
            menuBtn.y = 124;
            menuBtn.blendMode = "add";
            addChild(menuBtn);
            editorBtn = new MenuButton("btn_close");
            editorBtn.x = menuBtn.width + 15 + Globals.margin * 2;
            editorBtn.y = 120;
            editorBtn.blendMode = "add";
            editorBtn.rotation = Math.PI / 4;
            addChild(editorBtn);
            optionsMenu = new StartMenu(this);
            addChild(optionsMenu);
            optionsMenu.visible = false;
            // 这部分是计算内容
            getBarrierData();
            getOrbitData();
            getMoreInfoTexts();
        }

        public function getMoreInfoTexts():void {
            var infoText:TextField = null;
            var levelData:Array = LevelData.level;
            for (var i:int = 0; i < levelData.length; i++) {
                var text:String = "";
                infoText = new TextField(400, 100, text, "Downlink18", -1, 16755370);
                infoText.pivotX = 200;
                infoText.pivotY = 50;
                infoText.x = 512;
                infoText.y = 192;
                infoText.hAlign = HAlign.CENTER;
                infoText.vAlign = VAlign.CENTER;
                infoText.blendMode = BlendMode.ADD;
                infoText.alpha = 0.5;
                infoText.visible = false;
                infoText.touchable = false;
                infoTexts.push(infoText);
                previewBox.addChild(infoText);
            }
        }

        // #region 障碍轨道计算器
        public function getBarrierData():void {
            barrierData = [];
            var levelList:Array = LevelData.level
            for (var i:int = 0; i < levelList.length; i++) {
                var barriers:Array = [];
                var levelNode:Array = levelList[i].node;
                var nodeLength:int = levelNode.length;
                for (var j:int = 0; j < nodeLength; j++) {
                    if (!levelNode[j].barrierLinks)
                        continue;
                    if ("isBarrier" in levelNode[j]) {
                        if (levelNode[j].isBarrier == false)
                            continue;
                    } else if (!NodeType.isBarrier(levelNode[j].type))
                        continue;
                    processBarrier(levelNode, j, barriers);
                }
                barrierData.push(barriers);
            }
        }

        private function processBarrier(level:Array, node:int, barriers:Array):void {
            var connectedBarriers:Array = level[node].barrierLinks is Array ? level[node].barrierLinks : [int(level[node].barrierLinks)];
            for (var k:int = 0; k < connectedBarriers.length; k++) {
                var connectedIndex:int = connectedBarriers[k];
                if ("isBarrier" in level[connectedIndex]) {
                    if (level[connectedIndex].isBarrier == false)
                        continue;
                } else if (!NodeType.isBarrier(level[connectedIndex].type))
                    continue;
                var barrierInfo:Array = calculateBarrierInfo(level[node], level[connectedIndex]);
                addUniqueBarrier(barriers, barrierInfo);
            }
        }

        private function calculateBarrierInfo(barrier1:Object, barrier2:Object):Array {
            var dx:Number = barrier2.x - barrier1.x;
            var dy:Number = barrier2.y - barrier1.y;
            var distance:Number = Math.sqrt(dx * dx + dy * dy);
            var angle:Number = Math.atan2(dy, dx);
            var midX:Number = barrier1.x + Math.cos(angle) * distance * 0.5;
            var midY:Number = barrier1.y + Math.sin(angle) * distance * 0.5;
            return [midX, midY, distance - 10, angle];
        }

        private function addUniqueBarrier(barriers:Array, newBarrier:Array):void {
            for (var i:int = 0; i < barriers.length; i++)
                if (check4same(newBarrier, barriers[i]))
                    return;
            barriers.push(newBarrier);
        }

        private function check4same(array1:Array, array2:Array):Boolean { // 用于障碍线查重
            if (array1[0] == array2[0] && array1[1] == array2[1] && array1[2] == array2[2] && array1[3] == array2[3])
                return true;
            return false;
        }

        public function getOrbitData():void {
            orbitData = [];
            for (var i:int = 0; i < LevelData.level.length; i++) {
                var orbit:Array = [];
                var nodeData:Array = LevelData.level[i].node;
                var nodeLength:int = nodeData.length;
                for (var j:int = 0; j < nodeLength; j++) {
                    var orbitNode:int = nodeData[j].orbitNode;
                    if (!("orbitNode" in nodeData[j]) || nodeData[j].orbitNode == -1)
                        continue;
                    var dx:Number = nodeData[j].x - nodeData[orbitNode].x;
                    var dy:Number = nodeData[j].y - nodeData[orbitNode].y;
                    var distance:Number = Math.sqrt(dx * dx + dy * dy);
                    addUniqueOrbit(orbit, [orbitNode, distance]);
                }
                orbitData.push(orbit);
            }
        }

        private function addUniqueOrbit(orbit:Array, newOrbit:Array):void {
            for (var k:int = 0; k < orbit.length; k++)
                if (orbit[k][0] == newOrbit[0] && Math.abs(orbit[k][1] - newOrbit[1]) < 0.01)
                    return;
            orbit.push(newOrbit);
        }

        // #endregion
        // #region 界面载入卸载
        public function init():void {
            commonInit();
        }

        public function firstInit():void {
            cover.visible = true;
            cover.alpha = 1;
            commonInit();
            GS.playMusic("bgm01");
        }

        public function initAfterEnd():void {
            alpha = 1;
            visible = true;
            currentIndex = 0;
            levels.x = 512;
            deltaScroll.x = 0;
            cover.alpha = 1;
            Root.bg.x = 0;
            previewBox.y = 354;
            previewBox.scaleY = 0.7;
            previewBox.scaleX = 0.7;
            commonInit();
            Starling.juggler.removeTweens(this);
            Starling.juggler.removeTweens(previewBox);
            GS.playMusic("bgm01");
        }

        public function commonInit():void {
            mouseDown = false;
            dragging = false;
            menuBtn.init();
            menuBtn.addEventListener("clicked", on_menu);
            editorBtn.init();
            editorBtn.addEventListener("clicked", on_editor);
            levels.updateLevels();
            for (var i:int = 0; i < difficultyButtons.length; i++) {
                difficultyButtons[i].init();
                difficultyButtons[i].addEventListener("clicked", on_difficultyButton);
                if (i == Globals.difficultyInt - 1)
                    difficultyButtons[i].toggle();
            }
            updateStarCount();
            addEventListener("enterFrame", update);
            touchQuad.addEventListener("touch", on_touch);
        }

        public function deInit():void {
            for each (var difficultyBtn:DifficultyButton in difficultyButtons) {
                difficultyBtn.deInit();
                difficultyBtn.removeEventListener("clicked", on_difficultyButton);
            }
            menuBtn.deInit();
            menuBtn.removeEventListener("clicked", on_menu);
            editorBtn.deInit();
            editorBtn.removeEventListener("clicked", on_editor);
            removeEventListener("enterFrame", update);
            touchQuad.removeEventListener("touch", on_touch);
        }

        // #endregion
        // #region 按钮和动画
        public function on_menu(click:Event):void {
            //  menuBtn.deInit();
            //  menuBtn.removeEventListener("clicked", on_menu);
            optionsMenu.animateIn();
        }

        public function on_editor(click:Event):void {
            Starling.juggler.advanceTime(Globals.transitionSpeed);
            scene.editorMap();
            animateOut();
            GS.playClick();
        }

        public function on_quit(click:Event):void {
            NativeApplication.nativeApplication.exit();
        }

        public function on_difficultyButton(click:Event):void {
            Globals.currentDifficulty = DifficultyButton.btnText[difficultyButtons.indexOf(click.target)].toLowerCase();
            LevelData.updateLevelData();
            levels.updateLevels();
        }

        public function animateIn():void {
            updateStarCount();
            this.alpha = 0;
            this.visible = true;
            Starling.juggler.removeTweens(this);
            Starling.juggler.removeTweens(previewBox);
            Starling.juggler.tween(this, Globals.transitionSpeed, {"alpha": 1,
                    "transition": "easeInOut"});
            Starling.juggler.tween(previewBox, Globals.transitionSpeed, {"y":354,
                    "scaleX": 0.7,
                    "scaleY": 0.7,
                    "transition": "easeInOut"});
        }

        public function animateOut():void {
            deInit();
            Starling.juggler.removeTweens(this);
            Starling.juggler.removeTweens(previewBox);
            Starling.juggler.tween(this, Globals.transitionSpeed, {"alpha": 0,
                    "transition": "easeInOut",
                    "onComplete": hide});
            Starling.juggler.tween(previewBox, Globals.transitionSpeed, {"y":384,
                    "scaleX": 1,
                    "scaleY": 1,
                    "transition": "easeInOut"});
        }

        public function hide():void {
            this.visible = false;
        }

        public function nextLevel():void {
            if (Globals.level == LevelData.level.length - 1)
                return;
            Starling.juggler.delayCall(function():void {
                currentIndex = Globals.level + 2;
                scrollTo(currentIndex, Globals.transitionSpeed);
            }, Globals.transitionSpeed * 0.75);
        }

        public function on_resize():void {
            if (Globals.textSize == 2)
                menuBtn.setImage("btn_menu2x", 0.75);
            else
                menuBtn.setImage("btn_menu");
            levels.updateSize();
        }

        public function on_reset():void {
            Globals.levelReached = 0;
            for each (var star:int in Globals.levelData)
                star = 0;
            Globals.save();
            initAfterEnd();
        }

        // #endregion
        // #region 更新
        public function update(e:EnterFrameEvent):void {
            var x:Number = NaN;
            var y:Number = NaN;
            var radiu:Number = NaN;
            var voidR:Number = NaN;
            var dt:Number = e.passedTime;
            if (this.alpha == 0)
                return;
            if (cover.alpha > 0) {
                var fadeSpeed:Number = currentIndex > 0 ? 0.75 : 0.12;
                cover.alpha = Math.max(0, cover.alpha - dt * fadeSpeed);
            }
            if (!Starling.juggler.containsTweens(levels)) {
                var scrollDamping:Number = mouseDown ? 0.5 : 0.025;
                deltaScroll.x *= (1 - scrollDamping);
                levels.x += deltaScroll.x;
                if (!mouseDown && Math.abs(deltaScroll.x) < 2) {
                    deltaScroll.x = 0;
                    var targetX:Number = Math.round((levels.x - 512) / 120) * 120;
                    levels.x += (targetX - (levels.x - 512)) * 0.1;
                }
            }
            var minX:Number = 512 - levels.width + 100 + (LevelData.level.length - (Math.min(Globals.levelReached, LevelData.level.length - 1) + 1)) * 120;
            levels.x = Math.max(minX, Math.min(512, levels.x));
            levels.update(dt, hoverIndex);
            currentIndex = -Math.round((levels.x - 512) / 120);
            var scale:Number = (levels.x - 512) / -(levels.width - 100);
            Root.bg.setX(Root.bg.x + (-scale * 1024 * 3 - Root.bg.x) * 0.05);
            updatePreview();
            selector.reset();
            scale = 1 - Math.abs(levels.x + currentIndex * 120 - 512) / 60;
            radiu = 48 * scale;
            voidR = radiu - 2;
            if (Globals.textSize == 2)
                voidR = radiu - 3;
            if (voidR < 0)
                voidR = 0;
            Drawer.drawCircle(selector, 0, 0, 16755370, radiu, voidR);
            selector.blendMode = "add";
            selector.alpha = scale * 0.5;
            for each (var difficultyBtn:DifficultyButton in difficultyButtons) {
                if (currentIndex > 0)
                    difficultyBtn.scaleX = difficultyBtn.scaleY = difficultyBtn.alpha = scale;
                else
                    difficultyBtn.scaleX = difficultyBtn.scaleY = difficultyBtn.alpha = 0;
                if (Globals.levelData[currentIndex - 1] > 0 && difficultyButtons.indexOf(difficultyBtn) + 1 <= Globals.levelData[currentIndex - 1])
                    difficultyBtn.showStar(true);
                else
                    difficultyBtn.showStar(false);
            }
            if (currentIndex == 0) { // 处理进游戏后的 SOLARMAX2 标题渐变
                if (title.alpha < 0.5)
                    title.alpha = Math.min(0.5, title.alpha + dt * 0.5);
            } else if (title.alpha > 0)
                title.alpha = Math.max(0, title.alpha - dt * 0.5);
            title_blur.alpha = title.alpha * 0.6;
            for each (var text:TextField in credits)
                text.alpha = title.alpha / 0.5 * 0.2;
        }

        public function updateStarCount():void {
            var allStar:int = 0;
            for each (var star:int in Globals.levelData)
                allStar += star;
            starLabel.text = allStar.toString();
        }

        private function updatePreview():void {
            preview.reset();
            preview2.reset();
            previewQuad.reset();
            for each (var infoText:TextField in infoTexts)
                infoText.visible = false;
            if (currentIndex > 0 && LevelData.level[currentIndex - 1]) {
                var orbit:Array = null;
                var x:Number = NaN;
                var y:Number = NaN;
                var distence:Number = NaN;
                var inDistence:Number = NaN;
                var scale:Number = 1 - Math.abs(levels.x + currentIndex * 120 - 512) / 60;
                var levelData:Object = LevelData.level[currentIndex - 1];
                for each (var node:Object in levelData.node) {
                    shapeImage.x = node.x;
                    shapeImage.y = node.y;
                    var textureName:String = node.type;
                    shapeImage.texture = Root.assets.getTexture(textureName + "_shape");
                    if (node.type == NodeType.PLANET)
                        shapeImage.scaleX = shapeImage.scaleY = node.size ? node.size * scale : 0.3 * scale;
                    else
                        shapeImage.scaleX = shapeImage.scaleY = NodeType.getDefaultScale(node.type, node.size) * scale;
                    if (node.team)
                        shapeImage.color = Globals.teamColors[node.team];
                    else
                        shapeImage.color = Globals.teamColors[0];
                    if (shapeImage.color == 0)
                        preview2.addImage(shapeImage);
                    else
                        preview.addImage(shapeImage);
                }
                for each (var _barrier:Array in barrierData[currentIndex - 1]) {
                    bQuad.rotation = 0;
                    bQuad.width = _barrier[2] * scale;
                    bQuad.x = _barrier[0];
                    bQuad.y = _barrier[1];
                    bQuad.rotation = _barrier[3];
                    previewQuad.addQuad(bQuad);
                }
                for each (orbit in orbitData[currentIndex - 1]) {
                    x = Number(levelData.node[orbit[0]].x);
                    y = Number(levelData.node[orbit[0]].y);
                    distence = orbit[1] * scale + 2;
                    inDistence = Math.max(0, distence - 2);
                    Drawer.drawCircle(preview, x, y, 16777215, distence, inDistence, false, 0.5, 1, 0, 128);
                }

                var info:TextField = infoTexts[currentIndex - 1];
                info.visible = true;
                info.alpha = 0.5 * scale;
                info.scaleX = info.scaleY = scale;

                scale = LevelData.level[currentIndex - 1].gameScale;
                if (scale)
                    previewLayer.scaleX = previewLayer.scaleY = scale;
                else
                    previewLayer.scaleX = previewLayer.scaleY = 1;
            }
            preview.blendMode = "add";
        }

        public function on_touch(getTouch:TouchEvent):void {
            var endPoint:Point = null;
            var level:int = 0;
            var touch:Touch = getTouch.getTouch(touchQuad);
            if (!touch)
                return;
            switch (touch.phase) {
                case "hover":
                    hoverIndex = getClosestIndex(touch.globalX, touch.globalY);
                    break;
                case "began":
                    Starling.juggler.removeTweens(levels);
                    downIndex = getClosestIndex(touch.globalX, touch.globalY);
                    mouseDown = true;
                    break;
                case "moved":
                    endPoint = touch.getMovement(this);
                    if (Math.abs(endPoint.x) > 2) {
                        downIndex = -1;
                        dragging = true;
                    }
                    deltaScroll.x += endPoint.x;
                    break;
                case "ended":
                    if (downIndex > -1 && getClosestIndex(touch.globalX, touch.globalY) == downIndex && !dragging) {
                        if (downIndex > 0 && downIndex == currentIndex)
                            loadMap();
                        else {
                            level = Math.min(Globals.levelReached, LevelData.level.length - 1);
                            if (downIndex <= level + 1)
                                scrollTo(downIndex);
                        }
                    } else if (!dragging && currentIndex > 0)
                        if (touch.globalX > 140 && touch.globalX < 884 && touch.globalY > 220 && touch.globalY < 508)
                            loadMap();
                    mouseDown = false;
                    dragging = false;
            }
        }

        public function scrollTo(level:int, time:Number = 0.5):void {
            deltaScroll.x = 0;
            Starling.juggler.tween(levels, time, {"x": -level * 120 + 512,
                    "transition": "easeOut"});
        }

        public function scrollToCurrent():void {
            var levelReached:int = Math.min(Globals.levelReached, LevelData.level.length - 1);
            if (levelReached > 0) {
                scrollTo(levelReached + 1, Globals.transitionSpeed);
                currentIndex = levelReached + 1;
            }
        }

        // #endregion
        // #region 功能函数
        public function loadMap(seed:uint = 0):void {
            Starling.juggler.advanceTime(Globals.transitionSpeed);
            Globals.level = currentIndex - 1;
            scene.playMap(seed);
            animateOut();
            GS.playClick();
        }

        public function getClosestIndex(mouseX:Number, mouseY:Number):int {
            var index:int = Math.round((mouseX - levels.x) / 120);
            if (index < 0)
                return -1;
            var dx:Number = index * 120 + levels.x - mouseX;
            var dy:Number = levels.y - mouseY;
            var distance:Number = dx * dx + dy * dy;
            return (distance < 2304) ? index : -1; // 2304 is 48^2 保证鼠标在关卡按钮附近
        }
        // #endregion
    }
}
