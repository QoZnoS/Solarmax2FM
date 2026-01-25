import os
import xml.etree.ElementTree as ET
from PIL import Image
import argparse
import numpy as np

def add_marker_pixels(image, frame_width, frame_height, content_x, content_y, content_width, content_height):
    """
    在图像的规定内容区域添加几乎透明的标记像素
    以帮助repacker正确识别原始内容边界
    
    Args:
        image (PIL.Image): 输入图像
        frame_width (int): XML中规定的frame宽度
        frame_height (int): XML中规定的frame高度
        content_x (int): 内容在frame中的X偏移
        content_y (int): 内容在frame中的Y偏移
        content_width (int): 内容宽度
        content_height (int): 内容高度
        
    Returns:
        PIL.Image: 添加标记后的图像
    """
    # 转换为numpy数组以便处理
    img_array = np.array(image)
    
    # 创建标记像素（几乎透明的黑色像素）
    marker_pixel = [0, 0, 0, 1]  # RGBA: 黑色，alpha=1/255
    
    # 计算内容区域的边界坐标
    left = content_x
    top = content_y
    right = content_x + content_width - 1
    bottom = content_y + content_height - 1
    
    # 确保坐标在图像范围内
    left = max(0, min(left, frame_width - 1))
    top = max(0, min(top, frame_height - 1))
    right = max(0, min(right, frame_width - 1))
    bottom = max(0, min(bottom, frame_height - 1))
    
    # 在内容区域的左上角和右下角添加标记像素
    if left < frame_width and top < frame_height:
        img_array[top, left] = marker_pixel
    
    if right >= 0 and bottom >= 0 and right < frame_width and bottom < frame_height:
        img_array[bottom, right] = marker_pixel
    
    # 转换回PIL图像
    marked_image = Image.fromarray(img_array)
    
    return marked_image

def process_texture_atlas(xml_path, output_dir):
    """
    处理纹理图集，分离所有子纹理为单独的PNG文件
    
    Args:
        xml_path (str): XML文件路径
        output_dir (str): 输出目录
    """
    # 解析XML文件
    tree = ET.parse(xml_path)
    root = tree.getroot()
    
    # 获取图集图片路径
    image_path = root.get('imagePath')
    base_dir = os.path.dirname(xml_path)
    atlas_image_path = os.path.join(base_dir, image_path)
    
    # 打开图集图片
    atlas_image = Image.open(atlas_image_path).convert('RGBA')
    
    # 创建输出目录
    os.makedirs(output_dir, exist_ok=True)
    
    # 处理每个子纹理
    for sub_texture in root.findall('SubTexture'):
        name = sub_texture.get('name')
        x = int(sub_texture.get('x'))
        y = int(sub_texture.get('y'))
        width = int(sub_texture.get('width'))
        height = int(sub_texture.get('height'))
        
        # 获取frame参数（如果存在）
        frame_x = int(sub_texture.get('frameX', 0))
        frame_y = int(sub_texture.get('frameY', 0))
        frame_width = int(sub_texture.get('frameWidth', width))
        frame_height = int(sub_texture.get('frameHeight', height))
        
        # 从图集中提取子纹理
        texture = atlas_image.crop((x, y, x + width, y + height))
        
        # 创建frame尺寸的图像
        if frame_width != width or frame_height != height or frame_x != 0 or frame_y != 0:
            # 创建透明背景的图像
            framed_image = Image.new('RGBA', (frame_width, frame_height), (0, 0, 0, 0))
            
            # 计算放置位置（考虑frame偏移）
            pos_x = -frame_x
            pos_y = -frame_y
            
            # 将纹理放置到正确位置
            framed_image.paste(texture, (pos_x, pos_y))
            
            # 添加标记像素以帮助repacker正确识别内容边界
            # 使用XML中规定的frame尺寸和内容位置
            # framed_image = add_marker_pixels(
            #     framed_image, 
            #     frame_width, 
            #     frame_height,
            #     pos_x, 
            #     pos_y, 
            #     width, 
            #     height
            # )
            
            # 保存图像
            output_path = os.path.join(output_dir, f"{name}.png")
            framed_image.save(output_path)
            print(f"Saved: {output_path} (with frame: {frame_width}x{frame_height})")
        else:
            # 没有frame参数，直接保存
            # 添加标记像素以帮助repacker正确识别内容边界
            # 在这种情况下，内容就是整个图像
            # texture = add_marker_pixels(
            #     texture,
            #     width,
            #     height,
            #     0,
            #     0,
            #     width,
            #     height
            # )
            
            output_path = os.path.join(output_dir, f"{name}.png")
            texture.save(output_path)
            print(f"Saved: {output_path}")

def main():
    parser = argparse.ArgumentParser(description='分离纹理图集为单独的PNG文件')
    parser.add_argument('xml_file', help='TexturePacker生成的XML文件路径')
    parser.add_argument('output_dir', help='输出目录')
    
    args = parser.parse_args()
    
    try:
        process_texture_atlas(args.xml_file, args.output_dir)
        print("处理完成！")
    except Exception as e:
        print(f"处理过程中发生错误: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    main()