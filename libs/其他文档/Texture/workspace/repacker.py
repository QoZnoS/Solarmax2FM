import os
import xml.etree.ElementTree as ET
from PIL import Image
import argparse
import math
import numpy as np
from collections import namedtuple

# 定义纹理信息结构
TextureInfo = namedtuple('TextureInfo', ['name', 'img', 'content_img', 'content_x', 'content_y', 
                                         'content_width', 'content_height', 'frame_x', 'frame_y', 
                                         'frame_width', 'frame_height'])

def is_power_of_two(n):
    """检查一个数是否是2的幂"""
    n = int(n)  # 确保是Python整数
    return (n & (n-1) == 0) and n != 0

def next_power_of_two(n):
    """返回大于等于n的最小的2的幂"""
    n = int(n)  # 确保是Python整数
    if n <= 1:
        return 1
    return 1 << (n - 1).bit_length()

def calculate_texture_bounds(img):
    """
    计算图像中非透明区域的边界
    
    Args:
        img (PIL.Image): PIL图像对象
        
    Returns:
        tuple: (x_min, y_min, x_max, y_max, content_width, content_height)
    """
    # 转换为numpy数组以便处理
    img_array = np.array(img)
    
    # 获取alpha通道（如果存在）
    if img_array.shape[2] == 4:
        alpha_channel = img_array[:, :, 3]
    else:
        # 如果没有alpha通道，假设所有像素都是不透明的
        alpha_channel = np.ones((img_array.shape[0], img_array.shape[1])) * 255
    
    # 找到非透明像素的边界
    rows = np.any(alpha_channel > 0, axis=1)
    cols = np.any(alpha_channel > 0, axis=0)
    
    if not np.any(rows) or not np.any(cols):
        # 如果图像完全透明，使用整个图像
        return 0, 0, img.width-1, img.height-1, img.width, img.height
    
    y_min, y_max = np.where(rows)[0][[0, -1]]
    x_min, x_max = np.where(cols)[0][[0, -1]]
    
    # 转换为Python整数
    x_min, y_min, x_max, y_max = int(x_min), int(y_min), int(x_max), int(y_max)
    
    content_width = x_max - x_min + 1
    content_height = y_max - y_min + 1
    
    return x_min, y_min, x_max, y_max, content_width, content_height

def analyze_textures(input_dir):
    """
    分析目录中的所有PNG纹理
    
    Args:
        input_dir (str): 输入目录路径
        
    Returns:
        list: 纹理信息列表
    """
    textures = []
    
    for filename in os.listdir(input_dir):
        if filename.endswith('.png'):
            name = os.path.splitext(filename)[0]
            img_path = os.path.join(input_dir, filename)
            
            try:
                img = Image.open(img_path).convert('RGBA')
                width, height = img.size
                
                # 计算纹理边界
                x_min, y_min, x_max, y_max, content_width, content_height = calculate_texture_bounds(img)
                
                # 裁剪出实际内容
                content_img = img.crop((x_min, y_min, x_max + 1, y_max + 1))
                
                # 计算frame参数
                # frame尺寸应该等于原图尺寸
                frame_width = width
                frame_height = height
                
                # 计算偏移量（负值，表示内容在frame中的位置）
                # 根据原始XML，frameX和frameY应该是负值
                frame_x = -x_min
                frame_y = -y_min
                
                textures.append(TextureInfo(name, img, content_img, x_min, y_min, 
                                           content_width, content_height, 
                                           frame_x, frame_y, frame_width, frame_height))
                print(f"Analyzed: {filename} (content: {content_width}x{content_height}, frame: {frame_width}x{frame_height}, offset: ({frame_x}, {frame_y}))")
                
            except Exception as e:
                print(f"Error analyzing {filename}: {e}")
                import traceback
                traceback.print_exc()
    
    return textures

def pack_textures(textures):
    """
    打包纹理到图集，使用简单的按行装箱算法，保持纹理间距离
    
    Args:
        textures (list): 纹理信息列表
        
    Returns:
        tuple: (图集图像, 纹理位置信息列表)
    """
    # 按高度降序排序（高的优先）
    textures.sort(key=lambda t: t.content_height, reverse=True)
    
    gap = 4  # 纹理之间的间隙
    padding = 2  # 图集边缘的填充
    
    # 计算所有纹理的总面积
    total_area = 0
    max_width = 0
    for texture in textures:
        total_area += (texture.content_width + gap) * (texture.content_height + gap)
        max_width = max(max_width, texture.content_width)
    
    # 从合理的尺寸开始尝试
    # 先估算最小可能的宽度和高度
    min_width = max_width + padding * 2
    min_height = textures[0].content_height + padding * 2
    
    # 尝试不同的尺寸
    for atlas_size in [2048]:
        print(f"尝试图集尺寸: {atlas_size}x{atlas_size}")
        
        # 创建空白图集
        atlas = Image.new('RGBA', (atlas_size, atlas_size), (0, 0, 0, 0))
        placements = []
        
        # 初始化第一行
        current_x = padding
        current_y = padding
        current_row_height = 0
        
        # 尝试放置每个纹理
        for texture in textures:
            # 如果当前行放不下，换到新的一行
            if current_x + texture.content_width + gap > atlas_size - padding:
                current_x = padding
                current_y += current_row_height + gap
                current_row_height = 0
            
            # 检查是否超出图集高度
            if current_y + texture.content_height + gap > atlas_size - padding:
                # 当前尺寸太小，尝试下一个尺寸
                print(f"尺寸 {atlas_size} 太小，尝试下一个尺寸")
                break
            
            # 放置纹理
            atlas.paste(texture.content_img, (current_x, current_y))
            
            # 记录位置信息
            placements.append((texture.name, current_x, current_y, 
                              texture.content_width, texture.content_height,
                              texture.frame_x, texture.frame_y, 
                              texture.frame_width, texture.frame_height))
            
            # 更新当前位置
            current_x += texture.content_width + gap
            current_row_height = max(current_row_height, texture.content_height)
        else:
            # 所有纹理都成功放置
            print(f"成功将 {len(textures)} 个纹理打包到 {atlas_size}x{atlas_size} 图集")
            print(f"空间利用率: {total_area / (atlas_size * atlas_size) * 100:.2f}%")
            print(f"使用空间: {current_y + current_row_height}x{max_width if placements else 0}")
            return atlas, placements
        
        # 继续尝试下一个尺寸
    
    # 如果所有尺寸都失败，使用更灵活的算法
    print("标准算法失败，使用备用算法...")
    return pack_textures_backup(textures)

def pack_textures_backup(textures):
    """
    备用打包算法：使用多行策略
    
    Args:
        textures (list): 纹理信息列表
        
    Returns:
        tuple: (图集图像, 纹理位置信息列表)
    """
    # 按宽度降序排序
    textures.sort(key=lambda t: t.content_width, reverse=True)
    
    gap = 4
    padding = 2
    
    # 尝试不同的尺寸
    for atlas_size in [2048]:
        print(f"备用算法尝试尺寸: {atlas_size}x{atlas_size}")
        
        atlas = Image.new('RGBA', (atlas_size, atlas_size), (0, 0, 0, 0))
        placements = []
        
        # 初始化多行
        rows = []
        current_y = padding
        
        for texture in textures:
            placed = False
            
            # 尝试放入现有行
            for i, row in enumerate(rows):
                row_y, row_height, row_textures = row
                
                # 检查这一行是否有空间
                row_width = sum(t.content_width + gap for t in row_textures)
                if row_width + texture.content_width + gap <= atlas_size - padding:
                    # 可以放入这一行
                    x_pos = padding if not row_textures else (row_width + gap)
                    atlas.paste(texture.content_img, (x_pos, row_y))
                    
                    # 记录位置
                    placements.append((texture.name, x_pos, row_y, 
                                      texture.content_width, texture.content_height,
                                      texture.frame_x, texture.frame_y, 
                                      texture.frame_width, texture.frame_height))
                    
                    # 更新行信息
                    row_textures.append(texture)
                    rows[i] = (row_y, max(row_height, texture.content_height), row_textures)
                    placed = True
                    break
            
            # 如果不能放入现有行，创建新行
            if not placed:
                # 检查是否有空间创建新行
                new_row_y = padding
                if rows:
                    # 新行放在最后一行下面
                    last_row_y, last_row_height, _ = rows[-1]
                    new_row_y = last_row_y + last_row_height + gap
                
                if new_row_y + texture.content_height + gap <= atlas_size - padding:
                    # 创建新行
                    x_pos = padding
                    atlas.paste(texture.content_img, (x_pos, new_row_y))
                    
                    # 记录位置
                    placements.append((texture.name, x_pos, new_row_y, 
                                      texture.content_width, texture.content_height,
                                      texture.frame_x, texture.frame_y, 
                                      texture.frame_width, texture.frame_height))
                    
                    rows.append((new_row_y, texture.content_height, [texture]))
                    placed = True
            
            if not placed:
                # 当前尺寸放不下，尝试下一个尺寸
                print(f"备用算法尺寸 {atlas_size} 太小")
                break
        
        else:
            # 所有纹理都成功放置
            print(f"备用算法成功将 {len(textures)} 个纹理打包到 {atlas_size}x{atlas_size} 图集")
            return atlas, placements
    
    # 如果还是失败，使用最简算法
    print("所有算法失败，使用最简算法...")
    return pack_textures_simple(textures)

def pack_textures_simple(textures):
    """
    最简打包算法：一行一个纹理
    
    Args:
        textures (list): 纹理信息列表
        
    Returns:
        tuple: (图集图像, 纹理位置信息列表)
    """
    # 找到最大纹理尺寸
    max_width = max(t.content_width for t in textures)
    max_height = max(t.content_height for t in textures)
    
    gap = 4
    padding = 2
    
    # 计算所需的最小尺寸
    required_width = max_width + padding * 2
    required_height = sum(t.content_height + gap for t in textures) + padding * 2
    
    # 找到合适的2的幂次方尺寸
    atlas_size = 128
    while atlas_size < max(required_width, required_height):
        atlas_size *= 2
        if atlas_size > 2048:
            atlas_size = 2048
            break
    
    print(f"最简算法使用尺寸: {atlas_size}x{atlas_size}")
    
    atlas = Image.new('RGBA', (atlas_size, atlas_size), (0, 0, 0, 0))
    placements = []
    
    current_y = padding
    
    for texture in textures:
        # 居中放置
        x_pos = (atlas_size - texture.content_width) // 2
        
        # 放置纹理
        atlas.paste(texture.content_img, (x_pos, current_y))
        
        # 记录位置
        placements.append((texture.name, x_pos, current_y, 
                          texture.content_width, texture.content_height,
                          texture.frame_x, texture.frame_y, 
                          texture.frame_width, texture.frame_height))
        
        # 更新位置
        current_y += texture.content_height + gap
    
    print(f"最简算法打包完成，使用空间: {atlas_size}x{current_y}")
    return atlas, placements


def generate_xml(placements, atlas_size, output_path):
    """
    生成XML描述文件
    
    Args:
        placements (list): 纹理位置信息列表
        atlas_size (int): 图集大小
        output_path (str): XML输出路径
    """
    # 创建XML根元素
    root = ET.Element("TextureAtlas")
    root.set("imagePath", "assets.png")

    placements.sort(key=lambda t: t[0])
    
    # 添加每个子纹理元素
    for name, x, y, width, height, frame_x, frame_y, frame_width, frame_height in placements:
        sub_texture = ET.SubElement(root, "SubTexture")
        sub_texture.set("name", name)
        sub_texture.set("x", str(x))
        sub_texture.set("y", str(y))
        sub_texture.set("width", str(width))
        sub_texture.set("height", str(height))
        
        # 添加frame信息
        if(frame_x == frame_y == 0):
            continue
        sub_texture.set("frameX", str(frame_x))
        sub_texture.set("frameY", str(frame_y))
        sub_texture.set("frameWidth", str(frame_width))
        sub_texture.set("frameHeight", str(frame_height))
    
    # 写入XML文件
    tree = ET.ElementTree(root)
    tree.write(output_path, encoding="utf-8", xml_declaration=True)
    print(f"Generated XML: {output_path}")

def pack_texture_atlas(input_dir, output_dir):
    """
    打包纹理图集
    
    Args:
        input_dir (str): 输入目录
        output_dir (str): 输出目录
    """
    # 创建输出目录
    os.makedirs(output_dir, exist_ok=True)
    
    # 分析纹理
    print("Analyzing textures...")
    textures = analyze_textures(input_dir)
    if not textures:
        print("No textures found to pack")
        return
    
    # 打包纹理
    print("Packing textures...")
    atlas, placements = pack_textures(textures)
    
    # 保存图集
    atlas_path = os.path.join(output_dir, "assets.png")
    atlas.save(atlas_path)
    print(f"Saved atlas: {atlas_path}")
    
    # 生成XML
    xml_path = os.path.join(output_dir, "assets.xml")
    generate_xml(placements, atlas.size[0], xml_path)

def main():
    parser = argparse.ArgumentParser(description='纹理图集打包工具')
    parser.add_argument('input_dir', help='包含PNG文件的输入目录')
    parser.add_argument('output_dir', help='输出目录')
    
    args = parser.parse_args()
    
    try:
        pack_texture_atlas(args.input_dir, args.output_dir)
        print("打包完成！")
    except Exception as e:
        print(f"处理过程中发生错误: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    main()