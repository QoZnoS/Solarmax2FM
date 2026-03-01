import os
import json
import xml.etree.ElementTree as ET
from pathlib import Path
from typing import Dict, Set, Any, List, Tuple

# 配置路径
PROJECT_ROOT = Path(".")  # 假设脚本在项目根目录执行
LEVEL_JSON_PATH = PROJECT_ROOT / "libs" / "metadata" / "level.json"
NODE_XML_PATH = PROJECT_ROOT / "libs" / "metadata" / "Node.xml"
AI_DIR = PROJECT_ROOT / "src" / "core" / "ai"
EVENTS_DIR = PROJECT_ROOT / "src" / "core" / "game" / "events"
VICTORY_DIR = PROJECT_ROOT / "src" / "core" / "game" / "victory"
ATTACKS_DIR = PROJECT_ROOT / "src" / "core" / "node" / "attacks"
AUDIO_DIR = PROJECT_ROOT / "libs" / "audio"

OUTPUT_AS_PATH = PROJECT_ROOT / "src" / "managers" / "metadata" / "TypeConstants.as"

# 需要排除的基类/接口文件名（不含扩展名）
EXCLUDED_AI = {"IEnemyAI"}
EXCLUDED_EVENTS = {"ISpecialEvent"}
EXCLUDED_VICTORY = {"IVictoryType"}
EXCLUDED_ATTACKS = {"IAttackStrategy"}

def load_level_json() -> List[Dict]:
    """加载 level.json 并返回 level 数组"""
    with open(LEVEL_JSON_PATH, "r", encoding="utf-8") as f:
        datas = json.load(f).get("data", [])
    # 原代码有误，修正为提取所有 level 对象
    levels = []
    for data in datas:
        levels.extend(data.get("level", []))
    return levels

def extract_node_types() -> List[str]:
    """从 Node.xml 提取所有节点类型 (name 属性)"""
    tree = ET.parse(NODE_XML_PATH)
    root = tree.getroot()
    types = []
    for node_elem in root.findall("node"):
        name = node_elem.get("name")
        if name:
            types.append(name)
    return sorted(types)

def extract_file_types(directory: Path, suffix: str, exclude_set: Set[str]) -> List[str]:
    """
    从指定目录提取所有 .as 文件，去掉后缀并排除指定集合。
    suffix 如 "SE.as", "Victory.as", "AI.as", "Attack.as"
    返回类型名列表（去掉后缀后的部分）
    """
    types = []
    if not directory.exists():
        print(f"警告：目录不存在 {directory}")
        return types
    for f in directory.glob("*.as"):
        stem = f.stem  # 不带扩展名的文件名
        # 排除接口（以 I 开头）和基类
        if stem.startswith("I") or stem in exclude_set:
            continue
        if f.name.endswith(suffix):
            type_name = stem[:-len(suffix)+3] if suffix else stem  # 去掉后缀
            types.append(type_name)
    return sorted(types)

def extract_bgm_names() -> List[str]:
    """从音频目录提取所有 mp3 文件名（不含扩展名）"""
    names = []
    if not AUDIO_DIR.exists():
        print(f"警告：音频目录不存在 {AUDIO_DIR}")
        return names
    for f in AUDIO_DIR.glob("*.mp3"):
        names.append(f.stem)
    return sorted(names)

def collect_level_keys(levels: List[Dict]) -> Tuple[Dict[str, Set[str]], List[str]]:
    """
    遍历所有关卡，收集所有基本键名及其可能的值类型，以及所有出现的难度后缀。
    返回 (key_types, difficulty_suffixes)
    """
    key_types = {}
    difficulty_suffixes = set()

    def record_type(key: str, value: Any):
        nonlocal difficulty_suffixes
        # 处理难度后缀
        if '/' in key:
            base_key, suffix = key.split('/', 1)  # 只分割一次
            difficulty_suffixes.add(suffix)
        else:
            base_key = key

        if base_key not in key_types:
            key_types[base_key] = set()

        # 确定值类型
        if value is None:
            typ = "null"
        elif isinstance(value, bool):
            typ = "boolean"
        elif isinstance(value, (int, float)):
            typ = "number"
        elif isinstance(value, str):
            typ = "string"
        elif isinstance(value, list):
            typ = "array"
        elif isinstance(value, dict):
            typ = "object"
        else:
            typ = "unknown"
        key_types[base_key].add(typ)

    def process_object(obj: Dict):
        for k, v in obj.items():
            record_type(k, v)
            if isinstance(v, dict):
                process_object(v)
            elif isinstance(v, list):
                for item in v:
                    if isinstance(item, dict):
                        process_object(item)

    for level in levels:
        process_object(level)

    return key_types, sorted(difficulty_suffixes)

def generate_as_file(
    node_types: List[str],
    event_types: List[str],
    victory_types: List[str],
    ai_types: List[str],
    bgm_names: List[str],
    attack_types: List[str],
    level_keys: Dict[str, Set[str]],
    difficulty_suffixes: List[str]   # 新增参数
):
    """生成 AS3 常量类"""
    lines = []
    lines.append("package managers.metadata {")
    lines.append("")
    lines.append("    public class TypeConstants {")
    lines.append("")

    # 节点类型
    lines.append("        /** 所有节点类型 (来自 Node.xml) */")
    lines.append(f"        public static const NODE_TYPES:Array = {json.dumps(node_types, indent=None)};")
    lines.append("")

    # 特殊事件类型
    lines.append("        /** 所有特殊事件类型 (来自 events 目录) */")
    lines.append(f"        public static const SPECIAL_EVENT_TYPES:Array = {json.dumps(event_types, indent=None)};")
    lines.append("")

    # 胜利条件类型
    lines.append("        /** 所有胜利条件类型 (来自 victory 目录) */")
    lines.append(f"        public static const VICTORY_CONDITION_TYPES:Array = {json.dumps(victory_types, indent=None)};")
    lines.append("")

    # AI 类型
    lines.append("        /** 所有 AI 类型 (来自 ai 目录) */")
    lines.append(f"        public static const AI_TYPES:Array = {json.dumps(ai_types, indent=None)};")
    lines.append("")

    # BGM 名称
    lines.append("        /** 所有 BGM 名称 (来自 audio 目录) */")
    lines.append(f"        public static const BGM_NAMES:Array = {json.dumps(bgm_names, indent=None)};")
    lines.append("")

    # 攻击类型
    lines.append("        /** 所有攻击类型 (来自 attacks 目录) */")
    # 将攻击类型转为小写，因为游戏中使用小写
    attack_types_lower = [t.lower() for t in attack_types]
    lines.append(f"        public static const ATTACK_TYPES:Array = {json.dumps(attack_types_lower, indent=None)};")
    lines.append("")

    # 难度后缀（新增）
    lines.append("        /** 所有难度后缀 (从 level.json 键名中提取) */")
    lines.append(f"        public static const DIFFICULTY_SUFFIXES:Array = {json.dumps(difficulty_suffixes, indent=None)};")
    lines.append("")

    # level.json 键名及其类型
    lines.append("        /** level.json 中各键名及其可能的类型 (不计难度后缀) */")
    lines.append("        public static const LEVEL_KEYS:Object = {")
    for i, (key, types) in enumerate(sorted(level_keys.items())):
        type_str = ",".join(sorted(types))
        comma = "," if i < len(level_keys)-1 else ""
        lines.append(f'            "{key}": "{type_str}"{comma}')
    lines.append("        };")
    lines.append("")

    lines.append("    }")
    lines.append("}")

    # 写入文件
    OUTPUT_AS_PATH.parent.mkdir(parents=True, exist_ok=True)
    with open(OUTPUT_AS_PATH, "w", encoding="utf-8") as f:
        f.write("\n".join(lines))
    print(f"已生成 {OUTPUT_AS_PATH}")

def main():
    print("开始分析项目...")

    # 1. 读取 level.json
    levels = load_level_json()
    print(f"加载 {len(levels)} 个关卡")

    # 2. 提取节点类型
    node_types = extract_node_types()
    print(f"节点类型: {len(node_types)} 个")

    # 3. 提取特殊事件类型
    event_types = extract_file_types(EVENTS_DIR, "SE.as", EXCLUDED_EVENTS)
    print(f"特殊事件类型: {len(event_types)} 个")

    # 4. 提取胜利条件类型
    victory_types = extract_file_types(VICTORY_DIR, "Victory.as", EXCLUDED_VICTORY)
    print(f"胜利条件类型: {len(victory_types)} 个")

    # 5. 提取 AI 类型
    ai_types = extract_file_types(AI_DIR, "AI.as", EXCLUDED_AI)
    print(f"AI 类型: {len(ai_types)} 个")

    # 6. 提取 BGM 名称
    bgm_names = extract_bgm_names()
    print(f"BGM 名称: {len(bgm_names)} 个")

    # 7. 提取攻击类型
    attack_types = extract_file_types(ATTACKS_DIR, "Attack.as", EXCLUDED_ATTACKS)
    print(f"攻击类型: {len(attack_types)} 个")

    # 8. 收集 level.json 键名及类型，并提取难度后缀
    level_keys, difficulty_suffixes = collect_level_keys(levels)
    print(f"level.json 键名: {len(level_keys)} 个")
    print(f"难度后缀: {len(difficulty_suffixes)} 个")

    # 9. 生成 AS3 文件
    generate_as_file(
        node_types, event_types, victory_types, ai_types,
        bgm_names, attack_types, level_keys, difficulty_suffixes
    )

if __name__ == "__main__":
    main()