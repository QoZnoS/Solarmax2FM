package Menus.StartMenus {
    import starling.display.Sprite;
    import Menus.TitleMenu;
    import starling.core.Starling;
    import UI.Component.OptionButton;
    import flash.filesystem.File;
    import utils.ReplayData;
    import starling.text.TextField;
    import starling.events.Event;
    import flash.display.Scene;
    import utils.Popup;
    import starling.display.Quad;
    import starling.events.EnterFrameEvent;
    import utils.GS;

    public class ReplayMenu extends Sprite implements IMenu {

        private const COLOR:uint = 0xFF9DBB;

        private var title:TitleMenu;
        private var btn:OptionButton;
        private var clearBtn:OptionButton;

        public function ReplayMenu(title:TitleMenu) {
            this.title = title;
            init()
        }

        public function init():void {
            btn = new OptionButton("Open save folder", COLOR);
            btn.x = 512;
            btn.y = 128;
            // addChild(btn);
            btn.addEventListener("clicked", open_folder);
            btn = new OptionButton("refresh", COLOR);
            btn.x = 216;
            btn.y = 128;
            addChild(btn);
            btn.addEventListener("clicked", refresh);
            clearBtn = new OptionButton("Clear replay file", COLOR);
            clearBtn.x = 512;
            clearBtn.y = 128;
            addChild(clearBtn);
            clearBtn.addEventListener("clicked", clearRep_Confirm);
        }

        public function deinit():void {
            throw new Error("Method not implemented.");
        }

        public function animateIn():void {
            this.visible = true
            Starling.juggler.removeTweens(this);
            Starling.juggler.tween(this, 0.15, {"alpha": 1});
            addEventListener("enterFrame", update);
            refresh();
        }

        public function animateOut():void {
            Starling.juggler.removeTweens(this);
            Starling.juggler.tween(this, 0.15, {"alpha": 0,
                    "onComplete": hide});
            removeEventListener("enterFrame", update);
        }

        private var repList:Vector.<ReplayData>;
        private var repFileNames:Vector.<String>;
        /** 回放按钮， 关卡， 总时长， 文件名 */
        private var components:Array;
        private var restartTime:Vector.<Number>;
        private var restartHint:Vector.<Quad>;

        public function refresh():void {
            refreshRepList();
            var len:int = repList.length;
            var rep:ReplayData;
            var repBtn:OptionButton;
            var quad:Quad;
            var j:int = 0;
            for (var i:int = 0; i < len; i++) {
                rep = repList[i];
                if (rep.level[0] != LevelData.rawData[Globals.currentData].name)
                    continue;
                repBtn = new OptionButton(rep.level[0], COLOR);
                repBtn.label.height = 20;
                repBtn.quad.color = 0x000000;
                repBtn.quad.alpha = 0.5;
                repBtn.quad.width = repBtn.labelBG.width = 196;
                repBtn.quad.height = repBtn.labelBG.height = 88;
                repBtn.addLabel(new TextField(196, 20, "level: " + rep.level[1], "Downlink12", -1, COLOR), 0, 18);
                repBtn.addLabel(new TextField(196, 20, "Time: " + rep.totalTime, "Downlink12", -1, COLOR), 0, 38);
                repBtn.addLabel(new TextField(196, 20, repFileNames[i], "Downlink12", -1, COLOR), 0, 58);
                repBtn.x = 180 + 200 * (j % 4);
                repBtn.y = 160 + 92 * int(j / 4);
                repBtn.addEventListener("clicked", playRep);
                quad = new Quad(196, 88, COLOR);
                quad.x = -4;
                quad.alpha = 0.6;
                quad.scaleX = 0;
                repBtn.addChild(quad);
                addChild(repBtn);
                components.push(repBtn);
                restartHint.push(quad);
                restartTime.push(0);
                j++;
            }
        }

        private function refreshRepList():void {
            resetRepList();
            var replayDir:File = File.applicationStorageDirectory.resolvePath("replay");
            if (!replayDir.exists)
                replayDir.createDirectory();
            var files:Array = replayDir.getDirectoryListing();
            var replayFiles:Array = [];
            for each (var f:File in files)
                if (f.extension == "s2rp")
                    replayFiles.push(f);
            // 按修改时间排序，旧的在前
            if (replayFiles.length == 0) {
                clearBtn.visible = false;
                return;
            }
            clearBtn.visible = true;
            replayFiles.sortOn("modificationDate", Array.NUMERIC);
            replayFiles.reverse();
            for each (var rep:File in replayFiles) {
                Globals.load_replay(rep.name.split(".")[0]);
                repList.push(Globals.replay.deepCopy);
                repFileNames.push(rep.name.split(".")[0]);
            }
        }

        private function resetRepList():void {
            for each (var repBtn:OptionButton in components)
                removeChild(repBtn);
            components = []
            repList = new Vector.<ReplayData>;
            repFileNames = new Vector.<String>;
            restartTime = new Vector.<Number>;
            restartHint = new Vector.<Quad>;
        }

        private function update(e:EnterFrameEvent):void {
            if (components.length == 0)
                return;
            var dt:Number = e.passedTime;
            var len:int = components.length;
            for (var i:int = 0; i < len; i++) {
                if (components[i].down)
                    restartTime[i] += dt;
                else
                    restartTime[i] -= dt;
                restartTime[i] = Math.max(0, Math.min(1, restartTime[i]))
                restartHint[i].scaleX = Math.max(0, (restartTime[i] - 0.3) * 10 / 7);
                if (restartTime[i] == 1) {
                    if (Globals.currentDifficulty != Globals.replay.difficulty) {
                        Globals.currentDifficulty = Globals.replay.difficulty;
                        LevelData.updateLevelData();
                    }
                    for each (var level:Object in LevelData.level)
                        if (level.name == repList[i].level[1])
                            Globals.level = LevelData.level.indexOf(level);
                    refresh();
                    title.optionsMenu.animateOut();
                    title.scene.playMap(repList[i].seed);
                    title.animateOut();
                    GS.playClick();
                    len = 0;
                }
            }
        }

        private function playRep(click:Event):void {
            var index:int = components.indexOf(click.target);
            if (index == -1 || restartTime[index] > 0.3)
                return;
            Starling.juggler.advanceTime(Globals.transitionSpeed);
            Globals.replay = repList[index].deepCopy;
            if (Globals.currentDifficulty != Globals.replay.difficulty) {
                Globals.currentDifficulty = Globals.replay.difficulty;
                LevelData.updateLevelData();
            }
            title.animateOut();
            SceneController.s.replayMap(Globals.replay);
        }

        private function clearRep_Confirm():void {
            var popup:Popup = new Popup(Popup.TYPE_CHOOSE, "Confirm delete all of replay?");
            popup.enableDrag();
            popup.accept.addEventListener("clicked", clearRep);
            addChild(popup);
        }

        private function clearRep():void {
            var replayDir:File = File.applicationStorageDirectory.resolvePath("replay");
            if (!replayDir.exists)
                replayDir.createDirectory();
            var files:Array = replayDir.getDirectoryListing();
            for each (var f:File in files) {
                if (f.extension == "s2rp") {
                    var repName:String = f.name.split(".")[0];
                    Globals.load_replay(repName);
                    if (Globals.replay.level[0] == LevelData.rawData[Globals.currentData].name)
                        f.deleteFile();
                }
            }
            refresh();
        }

        private function hide():void {
            this.visible = false;
        }

        private function open_folder():void {
            var file:File = File.desktopDirectory;
            try {
                file.browseForDirectory("选择路径")
            } catch (error:Error) {
                file.requestPermission();
            }
        }
    }
}
