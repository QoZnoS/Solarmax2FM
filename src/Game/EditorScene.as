package Game {

    import starling.core.Starling;
    import Entity.EntityPool;
    import Entity.EntityContainer;
    import starling.events.EnterFrameEvent;
    import Entity.Node;
    import Entity.EntityHandler;
    import utils.Drawer;
    import UI.UIContainer;
    import Entity.Node.NodeType;
    import Entity.Node.NodeStaticLogic;

    public class EditorScene extends BasicScene {

        // private const defaultNode:Object = {"x": 980,"y": 154,"type": "planet"};
        private const defaultNode:Object = {"x": 512, "y": 384, "type": "planet"};

        public var focusNode:Node; // 打开了选择器的天体
        public var switchDistance:Number = 0; // 选择器移动距离
        public var switchInRows:Boolean = true; // 选择器是横向排列还是纵向排列

        public var moveNodes:Vector.<Node>;

        private var rowPrefabs:Vector.<NodePreview>;
        private var columnPrefabs:Vector.<NodePreview>;

        public function EditorScene(scene:SceneController) {
            super(scene);
            visible = false;
        }

        public function init():void {
            this.alpha = 1;
            this.visible = true;
            this.ui = scene.ui;
            createPrefabs();
            addEventListener("enterFrame", update);
            animateIn();
            var node:Node = EntityHandler.addNode(defaultNode);
            node.update(0);
            moveNodes = new Vector.<Node>;
        }

        public function createPrefabs():void {
            rowPrefabs = new Vector.<NodePreview>;
            var types:Vector.<String> = NodeType.getTypeVector();
            for (var i:int = 0; i < types.length; i++) {
                var preview:NodePreview = new NodePreview(types[i]);
                rowPrefabs.push(preview);
            }
            columnPrefabs = new Vector.<NodePreview>;
            for (i = 0; i < Globals.teamCount; i++) {
                preview = new NodePreview(NodeType.PLANET);
                preview.color = uint(Globals.teamColors[i]);
                columnPrefabs.push(preview);
            }
        }

        public function deInit():void {
            for each (var pool:EntityPool in EntityContainer.entityPool)
                pool.deInit();
            removeEventListener("enterFrame", update); // 移除更新帧监听器
            visible = false;
            moveNodes = new Vector.<Node>;
            for each (var np:NodePreview in rowPrefabs)
                np.deInit();
            for each (np in columnPrefabs)
                np.deInit();
        }

        override public function update(e:EnterFrameEvent):void {
            var dt:Number = e.passedTime;
            ui.update();
            drawSuperSwitchBar();
        }

        public function updateFocusNode():void {
            if (!focusNode)
            return;
            var best:NodePreview = null;
            var bestAlpha:Number = -1;
            var np:NodePreview;
            if (switchInRows) {
            for each (np in rowPrefabs) {
                if (np.nodeAlpha > bestAlpha) {
                bestAlpha = np.nodeAlpha;
                best = np;
                }
            }
            if (!best || bestAlpha <= 0)
                return;
            var newType:String = best.type;
            NodeStaticLogic.changeType(focusNode, newType);
            } else {
            for each (np in columnPrefabs) {
                if (np.nodeAlpha > bestAlpha) {
                bestAlpha = np.nodeAlpha;
                best = np;
                }
            }
            if (!best || bestAlpha <= 0)
                return;
            var col:uint = best.color;
            var teamIndex:int = 0;
            for (var ti:int = 0; ti < Globals.teamCount; ti++) {
                if (uint(Globals.teamColors[ti]) == col) {
                teamIndex = ti;
                break;
                }
            }
                NodeStaticLogic.changeTeam(focusNode, teamIndex, false);
            }
            focusNode.update(0);
            var offset:Number = switchInRows ? (best.image.x - focusNode.nodeData.x) : (best.image.y - focusNode.nodeData.y);
            var target:Number = switchDistance - offset;
            Starling.juggler.tween(this, Globals.transitionSpeed, {switchDistance: target});
        }

        public function drawSuperSwitchBar():void {
            if (!focusNode)
                return;
            focusNode.moveState.visible = false;
            var xLeft:Number = focusNode.nodeData.x - focusNode.nodeData.lineDist;
            var yTop:Number = focusNode.nodeData.y - focusNode.nodeData.lineDist;
            var xRight:Number = focusNode.nodeData.x + focusNode.nodeData.lineDist;
            var yBottom:Number = focusNode.nodeData.y + focusNode.nodeData.lineDist;
            Drawer.drawTweenedLine(UIContainer.behaviorBatch, xLeft - 512, yTop, xRight + 512, yTop, 0x00FF00, 2, 0.5);
            Drawer.drawTweenedLine(UIContainer.behaviorBatch, xLeft - 512, yBottom, xRight + 512, yBottom, 0x00FF00, 2, 0.5);
            Drawer.drawTweenedLine(UIContainer.behaviorBatch, xLeft, yTop - 384, xLeft, yBottom + 384, 0x00FF00, 2, 0.5);
            Drawer.drawTweenedLine(UIContainer.behaviorBatch, xRight, yTop - 384, xRight, yBottom + 384, 0x00FF00, 2, 0.5);

            var fx:Number = focusNode.nodeData.x;
            var fy:Number = focusNode.nodeData.y;
            var fc:uint = uint(Globals.teamColors[focusNode.nodeData.team]);
            var ft:String = focusNode.nodeData.type;
            var fl:Number = focusNode.nodeData.lineDist;

            var ri:int = 0;
            var ci:int = 0;
            var fri:int = 0;
            var fci:int = 0;
            var np:NodePreview;
            for each (np in rowPrefabs) {
                if (np.type == ft) {
                    fri = ri;
                    break;
                }
                ri++;
            }
            for each (np in columnPrefabs) {
                if (np.color == fc) {
                    fci = ci;
                    break;
                }
                ci++;
            }
            const spacing:Number = 80;
            var indexStep:int = Math.floor(switchDistance / spacing);
            ri = 0;
            if (switchInRows) {
                for each (np in rowPrefabs) {
                    var npx:Number = fx + ((fri + ri + indexStep + rowPrefabs.length + 4) % rowPrefabs.length - 4) * spacing + ((switchDistance % spacing) + spacing) % spacing;
                    if (npx < fx - spacing * 3)
                        np.shapeAlpha = 1 - (fx - spacing * 3 - npx) / spacing;
                    else if (npx > fx + spacing * 3)
                        np.shapeAlpha = 1 - (npx - (fx + spacing * 3)) / spacing;
                    else
                        np.shapeAlpha = 1;
                    if (fx - fl < npx && npx < fx + fl) {
                        np.nodeAlpha = 1 - Math.abs(npx - fx) / fl;
                        np.scale = (1 + 0.2 * np.nodeAlpha);
                    } else {
                        np.nodeAlpha = 0;
                        np.scale = 1;
                    }
                    np.shapeAlpha -= np.nodeAlpha;
                    np.shapeAlpha *= 0.5;
                    np.moveTo(npx, fy);
                    ri++;
                }
            } else {
                ci = 0;
                for each (np in columnPrefabs) {
                    var npy:Number = fy + ((fci + ci + indexStep + columnPrefabs.length + 2) % columnPrefabs.length - 2) * spacing + ((switchDistance % spacing) + spacing) % spacing;
                    if (npy < fy - spacing * 1)
                        np.shapeAlpha = 1 - (fy - spacing * 1 - npy) / spacing;
                    else if (npy > fy + spacing * 1)
                        np.shapeAlpha = 1 - (npy - (fy + spacing * 1)) / spacing;
                    else
                        np.shapeAlpha = 1;
                    if (fy - fl < npy && npy < fy + fl) {
                        np.nodeAlpha = 1 - Math.abs(npy - fy) / fl;
                        np.scale = (1 + 0.2 * np.nodeAlpha);
                    } else {
                        np.nodeAlpha = 0;
                        np.scale = 1;
                    }
                    np.shapeAlpha -= np.nodeAlpha;
                    np.shapeAlpha *= 0.5;
                    np.moveTo(fx, npy);
                    ci++;
                }
            }
        }

        public function clearSuperSwitchBar():void {
            for each (var np:NodePreview in rowPrefabs)
                np.nodeAlpha = np.shapeAlpha = 0;
            for each (np in columnPrefabs)
                np.nodeAlpha = np.shapeAlpha = 0;
            focusNode.moveState.visible = true;
        }

        public function quit():void {
            animateOut();
            scene.exit2TitleMenu(3);
            Starling.juggler.tween(this, Globals.transitionSpeed, {onComplete: deInit});
        }

    }
}

import starling.display.Image;
import Entity.Node.NodeType;
import UI.UIContainer;
import Entity.Node.NodeData;
import UI.LayerFactory;

class NodePreview {
    public var image:Image;
    public var glow:Image;
    public var halo:Image;
    public var type:String;

    private var _scale:Number = 1;

    public function NodePreview(type:String) {
        image = new Image(Root.assets.getTexture("planet01"));
        image.pivotX = image.pivotY = image.width * 0.5;
        halo = new Image(Root.assets.getTexture("halo"));
        halo.pivotX = halo.pivotY = halo.width * 0.5;
        glow = new Image(Root.assets.getTexture("planet_shape"));
        glow.pivotX = glow.pivotY = glow.width * 0.5;
        image.scaleX = image.scaleY = halo.scaleX = halo.scaleY = glow.scaleX = glow.scaleY = 0.5;
        updateType(type);
        LayerFactory.execute(LayerFactory.ADD_NODE, image, halo, glow, false);
    }

    public function updateType(type:String):void {
        this.type = type;
        if (type == NodeType.PLANET) {
            var imageID:String = (Math.random() * 16 + 1 >> 0) + "";
            if (imageID.length == 1)
                imageID = "0" + imageID;
            image.texture = Root.assets.getTexture("planet" + imageID);
            halo.texture = Root.assets.getTexture("halo");
            glow.texture = Root.assets.getTexture("planet_shape");
            image.scaleX = image.scaleY = glow.scaleX = glow.scaleY = NodeType.getDefaultSize(type);
        } else {
            image.texture = Root.assets.getTexture(type);
            halo.texture = Root.assets.getTexture(type + "_glow");
            glow.texture = Root.assets.getTexture(type + "_shape");
        }
        halo.readjustSize();
        halo.scaleY = halo.scaleX = 1;
        halo.pivotY = halo.pivotX = halo.width * 0.5;
        image.rotation = halo.rotation = glow.rotation = NodeType.getDefaultRotation(type);
        if (type == NodeType.PLANET)
            halo.scaleY = halo.scaleX = NodeType.getDefaultSize(type) * 0.5;
        else
            image.scaleX = image.scaleY = halo.scaleX = halo.scaleY = glow.scaleX = glow.scaleY = NodeType.getDefaultScale(type);
        _originalImageScale = image.scaleX;
        _originalGlowScale = glow.scaleX;
        _originalHaloScale = halo.scaleX;
    }

    public function deInit():void {
        image.removeFromParent(true);
        halo.removeFromParent(true);
        glow.removeFromParent(true);
    }
    private var _originalImageScale:Number = 1;
    private var _originalGlowScale:Number = 1;
    private var _originalHaloScale:Number = 1;

    public function set scale(value:Number):void {
        _scale = value;
        image.scaleX = image.scaleY = _originalImageScale * value;
        glow.scaleX = glow.scaleY = _originalGlowScale * value;
        halo.scaleX = halo.scaleY = _originalHaloScale * value;
    }

    public function get scale():Number {
        return _scale;
    }

    public function set nodeAlpha(value:Number):void {
        image.alpha = halo.alpha = value;
        image.visible = halo.visible = (value != 0);
    }

    public function get nodeAlpha():Number {
        return image.alpha;
    }

    public function set shapeAlpha(value:Number):void {
        glow.alpha = value;
        glow.visible = (value != 0);
    }

    public function get shapeAlpha():Number {
        return glow.alpha;
    }

    public function set color(value:uint):void {
        image.color = halo.color = glow.color = value;
    }

    public function get color():uint {
        return image.color;
    }

    public function moveTo(xPos:Number, yPos:Number):void {
        image.x = halo.x = glow.x = xPos;
        image.y = halo.y = glow.y = yPos;
    }
}
