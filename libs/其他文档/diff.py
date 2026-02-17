#!/usr/bin/env python3
"""
compare_game_data.py

比较两个由游戏导出的数据文件，支持：
- 纯文本 JSON (.json)
- 压缩的 JSON (.dat，由上述 ActionScript 生成)

生成差异报告，包含帧号、实体类型、ID 以及详细差异。

用法:
    python compare_game_data.py <file1> <file2> <output.txt>
"""

import json
import sys
import math
import zlib

EPSILON = 1e-5           # 浮点数比较容差

def load_file(filename):
    """
    自动检测文件类型并加载数据。
    先尝试作为纯文本 JSON 解析，若失败则尝试解压（原始 DEFLATE）后解析。
    """
    with open(filename, 'rb') as f:
        raw = f.read()

    # 尝试直接作为 UTF-8 文本解析（未压缩的情况）
    try:
        return json.loads(raw.decode('utf-8'))
    except UnicodeDecodeError:
        pass
    except json.JSONDecodeError:
        pass

    # 尝试解压（原始 DEFLATE 流，无头部）
    try:
        decompressed = zlib.decompress(raw, wbits=-15)
        return json.loads(decompressed.decode('utf-8'))
    except Exception:
        pass

    raise ValueError(f"无法识别文件格式或解压失败: {filename}")

def deep_diff(obj1, obj2, path=""):
    """递归比较两个对象，返回差异列表。每个差异为 (path, value1, value2) 或 (path, 描述)"""
    differences = []

    if type(obj1) != type(obj2):
        differences.append((path, f"类型不匹配: {type(obj1)} vs {type(obj2)}"))
        return differences

    if isinstance(obj1, (int, float, bool, str)) or obj1 is None:
        if isinstance(obj1, float) and isinstance(obj2, float):
            if not math.isclose(obj1, obj2, rel_tol=EPSILON, abs_tol=EPSILON):
                differences.append((path, obj1, obj2))
        elif obj1 != obj2:
            differences.append((path, obj1, obj2))
        return differences

    if isinstance(obj1, list):
        len1, len2 = len(obj1), len(obj2)
        if len1 != len2:
            differences.append((f"{path}.length", len1, len2))
        for i in range(min(len1, len2)):
            differences.extend(deep_diff(obj1[i], obj2[i], f"{path}[{i}]"))
        return differences

    if isinstance(obj1, dict):
        keys1 = set(obj1.keys())
        keys2 = set(obj2.keys())
        only1 = keys1 - keys2
        only2 = keys2 - keys1
        if only1:
            differences.append((path, f"第一个文件多出的键: {sorted(only1)}"))
        if only2:
            differences.append((path, f"第二个文件多出的键: {sorted(only2)}"))
        common = keys1 & keys2
        for key in sorted(common):
            new_path = f"{path}.{key}" if path else key
            differences.extend(deep_diff(obj1[key], obj2[key], new_path))
        return differences

    differences.append((path, f"不支持的类型: {type(obj1)}"))
    return differences

def build_node_map(frame):
    """根据 tag 建立节点映射"""
    return {node['tag']: node for node in frame.get('nodes', [])}

def build_ship_map(frame):
    """根据 rng.seed 建立飞船映射，若缺失则返回 None"""
    return {ship['tag']: ship for ship in frame.get('ships', [])}

def compare_frames(frame1, frame2, frame_idx):
    """比较两个帧，返回该帧的差异列表"""
    diffs = []

    # 节点比较
    nodes1 = build_node_map(frame1)
    nodes2 = build_node_map(frame2)
    tags1, tags2 = set(nodes1.keys()), set(nodes2.keys())

    for tag in sorted(tags1 - tags2):
        diffs.append((frame_idx, 'node', tag, "第二个文件缺失"))
    for tag in sorted(tags2 - tags1):
        diffs.append((frame_idx, 'node', tag, "第一个文件缺失"))

    for tag in sorted(tags1 & tags2):
        for diff in deep_diff(nodes1[tag], nodes2[tag]):
            if len(diff) == 2:
                path, desc = diff
                diffs.append((frame_idx, 'node', tag, f"{path}: {desc}"))
            else:
                path, v1, v2 = diff
                diffs.append((frame_idx, 'node', tag, f"{path}: {v1} vs {v2}"))

    # 飞船比较
    ship_map1 = build_ship_map(frame1)
    ship_map2 = build_ship_map(frame2)

    if ship_map1 is None or ship_map2 is None:
        # 回退到索引比较
        ships1 = frame1.get('ships', [])
        ships2 = frame2.get('ships', [])
        len1, len2 = len(ships1), len(ships2)
        if len1 != len2:
            diffs.append((frame_idx, 'ship', '总数', f"{len1} vs {len2}"))
        for i in range(min(len1, len2)):
            for diff in deep_diff(ships1[i], ships2[i]):
                if len(diff) == 2:
                    path, desc = diff
                    diffs.append((frame_idx, 'ship', f"[{i}]", f"{path}: {desc}"))
                else:
                    path, v1, v2 = diff
                    diffs.append((frame_idx, 'ship', f"[{i}]", f"{path}: {v1} vs {v2}"))
    else:
        seeds1, seeds2 = set(ship_map1.keys()), set(ship_map2.keys())
        for seed in sorted(seeds1 - seeds2):
            diffs.append((frame_idx, 'ship', seed, "第二个文件缺失"))
        for seed in sorted(seeds2 - seeds1):
            diffs.append((frame_idx, 'ship', seed, "第一个文件缺失"))
        for seed in sorted(seeds1 & seeds2):
            for diff in deep_diff(ship_map1[seed], ship_map2[seed]):
                if len(diff) == 2:
                    path, desc = diff
                    diffs.append((frame_idx, 'ship', seed, f"{path}: {desc}"))
                else:
                    path, v1, v2 = diff
                    diffs.append((frame_idx, 'ship', seed, f"{path}: {v1} vs {v2}"))

    return diffs

def main():
    if len(sys.argv) != 4:
        print("用法: python compare_game_data.py <file1> <file2> <output.txt>")
        sys.exit(1)

    file1, file2, out_file = sys.argv[1], sys.argv[2], sys.argv[3]

    try:
        data1 = load_file(file1)
        data2 = load_file(file2)
    except Exception as e:
        print(f"加载文件失败: {e}")
        sys.exit(1)

    if not isinstance(data1, list) or not isinstance(data2, list):
        print("错误: 文件内容不是数组格式")
        sys.exit(1)

    all_diffs = []

    # 帧数差异
    if len(data1) != len(data2):
        all_diffs.append(("全局", "帧数", f"{len(data1)} vs {len(data2)}"))

    min_frames = min(len(data1), len(data2))
    for i in range(min_frames):
        all_diffs.extend(compare_frames(data1[i], data2[i], i))

    # 多出的帧
    if len(data1) > len(data2):
        for i in range(len(data2), len(data1)):
            all_diffs.append((i, "frame", f"帧 {i}", "仅存在于第一个文件"))
    elif len(data2) > len(data1):
        for i in range(len(data1), len(data2)):
            all_diffs.append((i, "frame", f"帧 {i}", "仅存在于第二个文件"))

    # 写入报告
    with open(out_file, 'w', encoding='utf-8') as f:
        if not all_diffs:
            f.write("两个文件完全相同。\n")
            return

        f.write("差异报告\n")
        f.write("=" * 70 + "\n")
        for diff in all_diffs:
            if diff[0] == "全局":
                f.write(f"全局 | {diff[1]}: {diff[2]}\n")
            else:
                frame, etype, eid, detail = diff
                f.write(f"帧 {frame:4d} | {etype:4s} | ID {str(eid):12s} | {detail}\n")

    print(f"差异报告已写入: {out_file}")


def xorshift128_next(state):
    t = state[3]
    s = state[0]
    state[3] = state[2]
    state[2] = state[1]
    state[1] = s
    t ^= (t << 11) & 0xFFFFFFFF
    t ^= (t >> 8) & 0xFFFFFFFF
    state[0] = (t ^ s ^ (s >> 19)) & 0xFFFFFFFF
    return state[0]

def init_state(seed):
    a = 1812433253
    state = [0]*4
    seed = seed & 0xFFFFFFFF
    for i in range(4):
        seed = (a * (seed ^ (seed >> 30)) + (i+1)) & 0xFFFFFFFF
        state[i] = seed
    return state

# 目标种子列表（从题目中提取的100个数值）
# targets = [
#     1644288678, 912003266, 1273883966, 1952376920, 205642243, 248277410,
#     328458149, 313064918, 2133582747, 1000613185, 1535866205, 1195054661,
#     1494756845, 718792313, 737918876, 2143611064, 200062531, 1699759148,
#     197987326, 88539133, 1814181935, 1865889026, 1708354920, 938381684,
#     199463231, 796443265, 1746073926, 502491524, 361518891, 884658205,
#     348831967, 2006745807, 62374160, 1629039223, 59822313, 404803737,
#     1959979711, 100192696, 912003266, 1776394546, 1952376920, 1040413931,
#     248277410, 549048234, 313064918, 470789908, 1000613185, 2021881238,
#     1195054661, 1560474177, 718792313, 1277731540, 2143611064, 759092042,
#     1699759148, 1316109502, 88539133, 78143435, 1865889026, 228549512,
#     938381684, 702563826, 796443265, 511199268, 502491524, 82977324,
#     884658205, 1045240565, 2006745807, 1214938075, 1629039223, 1804542874,
#     404803737, 33132421, 100192696, 1463134205, 1776394546, 1285208675,
#     1040413931, 1578881945, 549048234, 1817442936, 470789908, 1772335680,
#     2021881238, 259216565, 1560474177, 1886702041, 1277731540, 2080865685,
#     759092042, 655683457, 1316109502, 148625788, 78143435, 2026052194,
#     228549512, 1727752895, 702563826, 420735238
# ]

# state = init_state(912003266)
# step = 0
# found = {}
# while len(found) < len(targets):
#     val = xorshift128_next(state)
#     step += 1
#     # if step % 100 == 0:
#     #     print (step)
#     if val in targets:
#         if val not in found:
#             found[val] = []
#         found[val].append(step)
#     # 为防止无限循环，可设置最大步数，但100个数通常很快出现
# # 输出结果
# for val in targets:
#     print(f"{val}: {found.get(val, 'not found')}")


if __name__ == "__main__":
    main()