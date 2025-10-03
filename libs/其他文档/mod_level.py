import json

file_path = "./libs/其他文档/level.json"
output_path = "./libs/其他文档/level_mod.json"

def process_start_ships(data):
    """
    处理JSON数据中的startShips字段
    如果startShips中只有与team值为索引的项不为0，则将整个startShips替换为该值
    """
    
    def process_node(node, team_data_length):
        # 检查节点是否有startShips字段
        if 'startShips' not in node:
            return
            
        start_ships = node['startShips']
        
        # 如果不是列表类型，跳过
        if not isinstance(start_ships, list):
            return
            
        # 获取team值，如果不存在则视为0
        team_index = node.get('team', 0)
        
        # 确保team_index在有效范围内
        if team_index < 0 or team_index >= len(start_ships):
            return
            
        # 检查是否只有team索引对应的值不为0
        only_team_non_zero = True
        for i, value in enumerate(start_ships):
            if i != team_index and value != 0:
                only_team_non_zero = False
                break
        
        # 如果只有team索引对应的值不为0，则替换整个startShips
        if only_team_non_zero and start_ships[team_index] != 0:
            node['startShips'] = start_ships[team_index]
    
    # 处理主数据
    if 'data' in data:
        for item in data['data']:
            if 'level' in item:
                for level in item['level']:
                    if 'node' in level:
                        for node in level['node']:
                            # 获取team数组长度用于验证
                            team_length = len(item.get('team', []))
                            process_node(node, team_length)
    
    return data

def main():
    # 读取JSON文件
    with open(file_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    # 处理数据
    processed_data = process_start_ships(data)
    
    # 写回文件
    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(processed_data, f, indent=4, ensure_ascii=False)
    
    print("处理完成！结果已保存到 level_processed.json")

if __name__ == "__main__":
    main()