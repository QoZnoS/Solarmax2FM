package i18n.languages {
    import i18n.ILocaleData;

    public class LocaleEN implements ILocaleData {
        public function get code():String { return "en"; }
        public function get displayName():String { return "English"; }
        public function get strings():Object {
            return data;
        }

        private var data:Object = {
                // === Main Menu ===
                "menu.setting":      "SETTING",
                "menu.mappacks":     "MAPPACK",
                "menu.staff":        "STAFF",
                "menu.replay":       "REPLAY",

                // === Settings ===
                "setting.video":     "VIDEO",
                "setting.audio":     "AUDIO",
                "setting.game":      "V1.2.0    GAME",
                "setting.windowMode":"WINDOW MODE:",
                "setting.fullscreen":"FULLSCREEN",
                "setting.resizable": "RESIZEABLE WINDOW",
                "setting.language":  "LANGUAGE:",
                "setting.antialias": "ANTI-ALIASING:",
                "setting.musicVol":  "MUSIC VOLUME:",
                "setting.soundVol":  "SOUND VOLUME:",
                "setting.uiSize":    "UI SIZE:",
                "setting.small":     "SMALL",
                "setting.medium":    "MEDIUM",
                "setting.large":     "LARGE",
                "setting.control":   "CONTROL METHOD:",
                "setting.multitouch":"MULTI-TOUCH",
                "setting.traditional":"TRADITIONAL",
                "setting.fleetPos":  "FLEETSLIDER POSITION:",
                "setting.left":      "LEFT",
                "setting.down":      "DOWN",
                "setting.right":     "RIGHT",
                "setting.saveFile":  "SAVE FILE:",
                "setting.resetProgress": "RESET PROGRESS",
                "setting.confirm":   "CONFIRM?",
                "setting.exitGame":  "EXIT GAME",

                // === Another Pages === 
                "mappack.title":     "MAP MANAGER",
                "menu.test":         "TEST",

                // === Replay ===
                "replay.openFolder": "OPEN SAVE FOLDER",
                "replay.refresh":    "REFRESH",
                "replay.clearFile":  "CLEAR REPLAY FILE",
                "replay.confirmDelete": "CONFIRM DELETE ALL REPLAY?",
                "replay.level":      "LEVEL: {0}",
                "replay.time":       "TIME: {0}",
                "replay.selectPath": "SELECT FOLDER",

                // === Tooltip ===
                "tooltip.multitouch.title": "MULTI-TOUCH CONTROLS",
                "tooltip.multitouch.content": "+ Hold LEFT CLICK on a planet and drag onto target\n\n+ SCROLL WHEEL to change move percentage",
                "tooltip.traditional.title": "TRADITIONAL CONTROLS",
                "tooltip.traditional.content": "+ LEFT CLICK on a planet to select it\n\n+ LEFT CLICK and drag a box to select planets\n\n+ Hold SHIFT and LEFT CLICK to add or remove planets\n\n+ LEFT CLICK on empty space to deselect\n\n+ RIGHT CLICK on a planet to move ships\n\n+ SCROLL WHEEL to change move percentage",

                // === Advanced Settings ===
                "adv.title":         "ADVANCED SETTINGS",
                "adv.blackBorder":   "BLACK BORDER:",
                "adv.allowPause":    "ALLOW PAUSE:",
                "adv.transSpeed":    "TRANSITION SPEED:",
                "adv.maxMargin":     "MAX MARGIN TEAM:",
                "adv.unlockAll":     "UNLOCK ALL LEVEL:",
                "adv.unlock":        "UNLOCK",

                // === Difficulty ===
                "diff.easy":         "EASY",
                "diff.normal":       "NORMAL",
                "diff.hard":         "HARD",

                // === In Game ===
                "game.population":   "POPULATION : {0} / {1}",
                "game.yes":          "YES",
                "game.no":           "NO",
                "game.win":          "VICTORY",
                "game.lose":         "DEFEAT",

                // === Level Select ===
                "level.select":      "SELECT LEVEL",
                "level.mapper":      "MAPPER: {0}",

                // === Staff ===
                "staff.original":    "ORIGINAL",
                "staff.design":      "DESIGN, ART, CODE:",
                "staff.music":       "MUSIC:",
                "staff.playtesting": "PLAYTESTING:",
                "staff.modified":    "MODIFIED",
                "staff.code":        "CODE:",
                "staff.thanks":      "SPECIAL THANKS:",
                "staff.thirdsister": "Thirdsister",

                // === Title ===
                "title.createdBy":   "CREATED BY NICO TUASON",
                "title.modifiedBy":  "MODIFIED BY QoZnoS"
            };
    }
}