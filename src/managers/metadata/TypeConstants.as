package managers.metadata {

    public class TypeConstants {

        /** 所有节点类型 (来自 Node.xml) */
        public static const NODE_TYPES:Array = ["barrier", "blackhole", "captureship", "cloneturret", "diffusion", "dilator", "habitat", "planet", "pulsecannon", "starbase", "supply", "tower", "warp"];

        /** 所有特殊事件类型 (来自 events 目录) */
        public static const SPECIAL_EVENT_TYPES:Array = ["BossAppear", "DarknessFalls", "FleetSliderGuide", "GameEnd", "MoveGuide", "WhiteholeFalls"];

        /** 所有胜利条件类型 (来自 victory 目录) */
        public static const VICTORY_CONDITION_TYPES:Array = ["AllOccupy", "None", "Normal", "Target", "Time"];

        /** 所有 AI 类型 (来自 ai 目录) */
        public static const AI_TYPES:Array = ["Adapted", "Balanced", "Basic", "Conservative", "Dark", "Final", "Hard", "Radical", "Simple", "Smart", "WhiteHole"];

        /** 所有 BGM 名称 (来自 audio 目录) */
        public static const BGM_NAMES:Array = ["Cooperation", "PVP", "SD0", "SD1", "SD2", "SD3", "SD4", "SD5", "SD6", "bgm01", "bgm02", "bgm04", "bgm05", "bgm06", "bgm07", "bgm_dark", "boss_appear", "boss_ready", "boss_reverse", "capture", "click", "click_down", "click_up", "diffused", "diffusing", "explosion01", "explosion02", "explosion03", "explosion04", "explosion05", "explosion06", "explosion07", "explosion08", "jumpCharge", "jumpEnd", "jumpStart", "laser", "warp", "warp_charge"];

        /** 所有攻击类型 (来自 attacks 目录) */
        public static const ATTACK_TYPES:Array = ["basic", "blackhole", "captureship", "cloneturret", "diffusion", "electromagnetic", "pulsecannon", "tower"];

        /** 所有难度后缀 (从 level.json 键名中提取) */
        public static const DIFFICULTY_SUFFIXES:Array = ["easy", "hard", "lecacy", "legacy", "normal"];

        /** level.json 中各键名及其可能的类型 (不计难度后缀) */
        public static const LEVEL_KEYS:Object = {
            "actionDelay": "number",
            "ai": "array,object",
            "attack": "object",
            "attackLast": "number",
            "attackRange": "number",
            "attackRate": "number",
            "barrierLinks": "array",
            "bgm": "string",
            "build": "object",
            "buildRate": "number",
            "buildTimer": "number",
            "capture": "object",
            "captureTeam": "number",
            "color": "string",
            "gameScale": "number",
            "group": "array",
            "hp": "number",
            "hpMult": "number",
            "isAIinvisible": "boolean",
            "isBarrier": "boolean",
            "isUntouchable": "boolean",
            "isWarp": "boolean",
            "name": "string",
            "node": "array,object",
            "nodeTag": "number",
            "orbitNode": "number",
            "orbitSpeed": "number",
            "playerTeam": "number",
            "popVal": "number",
            "ships": "number",
            "size": "number",
            "specialEvents": "array",
            "startDelay": "number",
            "startShips": "array,number",
            "statePool": "object",
            "targetTeam": "number",
            "team": "number",
            "trigger": "object",
            "type": "string",
            "victoryCondition": "object",
            "x": "number",
            "y": "number"
        };

    }
}