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
    打包纹理到图集，使用改进的装箱算法，添加1px间隙
    
    Args:
        textures (list): 纹理信息列表
        
    Returns:
        tuple: (图集图像, 纹理位置信息列表)
    """
    # 按内容面积排序，先放置大的纹理
    textures.sort(key=lambda t: max(t.content_width, t.content_height), reverse=True)
    
    # 计算所需的总面积（考虑1px间隙）
    gap = 4  # 纹理之间的间隙
    total_area = sum((t.content_width + gap) * (t.content_height + gap) for t in textures)
    
    # 估算初始图集大小（2的幂，不超过2048）
    initial_size = min(next_power_of_two(int(math.sqrt(total_area) * 1.1)), 2048)
    atlas_size = initial_size
    
    # 尝试不同的图集大小，直到找到合适的
    while atlas_size <= 2048:  # 限制最大尺寸为2048
        try:
            # 创建空白图集
            atlas = Image.new('RGBA', (atlas_size, atlas_size), (0, 0, 0, 0))
            placements = []
            
            # 使用改进的装箱算法 - 按行放置，添加1px间隙
            current_x = 2
            current_y = 2
            row_height = 2
            
            for texture in textures:
                # 检查是否需要换行（考虑间隙）
                if current_x + texture.content_width + gap > atlas_size:
                    current_x = 2
                    current_y += row_height + gap
                    row_height = 2
                
                # 检查是否需要增加图集高度（考虑间隙）
                if current_y + texture.content_height + gap > atlas_size:
                    raise ValueError("Atlas too small")
                
                # 将实际内容放置到图集上
                atlas.paste(texture.content_img, (current_x, current_y))
                
                # 记录纹理在图集中的位置
                placements.append((texture.name, current_x, current_y, 
                                  texture.content_width, texture.content_height,
                                  texture.frame_x, texture.frame_y, 
                                  texture.frame_width, texture.frame_height))
                
                # 更新当前位置和行高（考虑间隙）
                current_x += texture.content_width + gap
                row_height = max(row_height, texture.content_height)
            
            # 所有纹理都已放置
            print(f"Packed {len(textures)} textures into {atlas_size}x{atlas_size} atlas")
            print(f"Space utilization: {total_area / (atlas_size * atlas_size) * 100:.2f}%")
            return atlas, placements
            
        except ValueError:
            # 增大图集大小（2的幂）
            atlas_size *= 2
            if atlas_size > 2048:  # 设置最大限制为2048
                raise ValueError("Textures too large to pack into 2048x2048 atlas")
    
    raise ValueError("Textures too large to pack into 2048x2048 atlas")

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