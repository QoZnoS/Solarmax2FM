import json

file_path = "./libs/其他文档/level.json"
output_path = "./libs/其他文档/level_mod.json"

def add_bgm_to_levels(data):
    for item in data:
        levels = item.get('level', [])
        for index, level in enumerate(levels):
            if index < 8:  # 索引0到7（前8个关卡）
                level['bgm'] = 'bgm02'
            elif index < 22:  # 索引8到21（接下来的14个关卡）
                level['bgm'] = 'bgm04'
            elif index < 31:  # 索引22到30（接下来的9个关卡）
                level['bgm'] = 'bgm05'
            else:  # 索引31及以后的关卡
                level['bgm'] = 'bgm06'

def shift_colors(data):
    """
    将每个level数组中的color属性向前移动一位
    """
    for item in data:
        if 'level' in item:
            levels = item['level']
            
            # 如果level数组为空或只有一个元素，则跳过
            if len(levels) <= 1:
                continue
                
            # 保存第一个元素的color值
            first_color = levels[0]['color']
            
            # 向前移动color值
            for i in range(len(levels) - 1):
                levels[i]['color'] = levels[i + 1]['color']
            
            # 最后一项保持不变（实际上已经移动完成）
            # 原逻辑是最后一项不动，所以不需要额外操作
    
    return data

def process_json_file(input_file, output_file):
    """
    处理JSON文件：读取、修改color值、保存
    """
    try:
        # 读取JSON文件
        with open(input_file, 'r', encoding='utf-8') as f:
            content = json.load(f)
        
        # 检查数据结构
        if 'data' in content:
            # 处理data数组
            content['data'] = shift_colors(content['data'])
            
            # 保存修改后的JSON
            with open(output_file, 'w', encoding='utf-8') as f:
                json.dump(content, f, indent=4, ensure_ascii=False)
            
            print(f"处理完成！结果已保存到: {output_file}")
        else:
            print("JSON文件中未找到 'data' 字段")
            
    except Exception as e:
        print(f"处理文件时出错: {e}")

def main():
    # 读取JSON文件
    with open(file_path, 'r', encoding='utf-8') as file:
        data = json.load(file)
    
    # 处理数据
    if 'data' in data:
        add_bgm_to_levels(data['data'])
    
    # 写回文件
    with open(output_path, 'w', encoding='utf-8') as file:
        json.dump(data, file, indent=4, ensure_ascii=False)
    
    print("处理完成，结果已保存到 level_modified.json")

if __name__ == '__main__':
    process_json_file(file_path, output_path)