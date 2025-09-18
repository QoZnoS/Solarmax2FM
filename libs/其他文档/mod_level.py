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
    main()