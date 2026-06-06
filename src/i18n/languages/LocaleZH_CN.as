package i18n.languages {
    import i18n.ILocaleData;

    public class LocaleZH_CN implements ILocaleData {
        public function get code():String { return "zh_cn"; }
        public function get displayName():String { return "简体中文"; }
        public function get strings():Object {
            return data;
        }

        private var data:Object = {
                // === 主菜单 ===
                "menu.setting":      "设置",
                "menu.mappacks":     "地图集",
                "menu.staff":        "制作人员",
                "menu.replay":       "回放",

                // === 设置 ===
                "setting.video":     "视觉",
                "setting.audio":     "音频",
                "setting.game":      "V1.2.0    游戏",
                "setting.windowMode":"窗口模式:",
                "setting.fullscreen":"   全屏   ",
                "setting.resizable": "可变窗口",
                "setting.language":  "语言:",
                "setting.antialias": "抗锯齿:",
                "setting.musicVol":  "音乐音量:",
                "setting.soundVol":  "音效音量:",
                "setting.uiSize":    "UI 尺寸:",
                "setting.small":     "   小   ",
                "setting.medium":    "   中   ",
                "setting.large":     "   大   ",
                "setting.control":   "操控方式:",
                "setting.multitouch":"多点触控",
                "setting.traditional":"   传统   ",
                "setting.fleetPos":  "分兵条位置:",
                "setting.left":      "  左侧  ",
                "setting.down":      "  下方  ",
                "setting.right":     "  右侧  ",
                "setting.saveFile":  "存档文件:",
                "setting.resetProgress": "重置进度",
                "setting.confirm":   "确认重置?",
                "setting.exitGame":  "退出游戏",

                // === 其他页面 === 
                "mappack.title":     "图集管理器",
                "menu.test":         "测试",

                // === 回放 ===
                "replay.openFolder": "打开存档文件夹",
                "replay.refresh":    "刷新",
                "replay.clearFile":  "清空回放文件",
                "replay.confirmDelete": "确认删除所有回放?",
                "replay.level":      "关卡: {0}",
                "replay.time":       "时长: {0}",
                "replay.selectPath": "选择路径",

                // === 提示框 ===
                "tooltip.multitouch.title": "多点触控操作",
                "tooltip.multitouch.content": "+ 按住左键拖拽天体到目标\n\n+ 滚动滚轮调整分兵条",
                "tooltip.traditional.title": "传统操作",
                "tooltip.traditional.content": "+ 左键单击点选天体\n\n+ 左键滑动框选天体\n\n+ 按住 Shift + 左键添加/移除天体\n\n+ 左键空白处取消选择\n\n+ 右键目标天体派出飞船\n\n+ 滚动滚轮调整分兵条",

                // === 高级设置 ===
                "adv.title":         "高级设置",
                "adv.blackBorder":   "开启黑边:",
                "adv.allowPause":    "允许暂停:",
                "adv.transSpeed":    "动画时长:",
                "adv.maxMargin":     "合作兵力文本并排数:",
                "adv.unlockAll":     "解锁全部关卡:",
                "adv.unlock":        "解锁",

                // === 难度 ===
                "diff.easy":         "简单",
                "diff.normal":       "普通",
                "diff.hard":         "困难",

                // === 游戏中 ===
                "game.population":   "飞船 : {0} / {1}",
                "game.yes":          "  是  ",
                "game.no":           "  否  ",
                "game.win":          "胜利",
                "game.lose":         "失败",

                // === 关卡选择 ===
                "level.select":      "选择关卡",
                "level.mapper":      "作者: {0}",

                // === 制作人员 ===
                "staff.original":    "原作",
                "staff.design":      "设计, 美术, 代码:",
                "staff.music":       "音乐:",
                "staff.playtesting": "测试:",
                "staff.modified":    "重置",
                "staff.code":        "代码:",
                "staff.thanks":      "特别感谢:",
                "staff.thirdsister": "三妹",

                // === 标题 ===
                "title.createdBy":   "NICO TUASON 创作",
                "title.modifiedBy":  "QoZnoS 重置"
            };
    }
}