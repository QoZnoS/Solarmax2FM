#!/usr/bin/env python3
import subprocess
from datetime import datetime
import re

# 1. 生成新的版本标签
build_date = datetime.now().strftime("%Y%m%d")
git_hash = subprocess.check_output(['git', 'rev-parse', '--short', 'HEAD']).decode('utf-8').strip()
new_version_label = f"{build_date}+{git_hash}"

# 2. 文件路径
app_descriptor_path = "./libs/其他文档/Main-app.xml"
output_path = "./src/Main-app.xml"

try:
    # 3. 以二进制模式读取文件，避免编码问题
    with open(app_descriptor_path, 'rb') as file:
        content_bytes = file.read()
    
    # 4. 尝试解码为UTF-8，如果失败则尝试其他编码
    try:
        content = content_bytes.decode('utf-8')
    except UnicodeDecodeError:
        # 尝试其他常见编码
        try:
            content = content_bytes.decode('latin-1')
        except UnicodeDecodeError:
            content = content_bytes.decode('utf-8', errors='ignore')
            print("⚠️  Had to use error-tolerant UTF-8 decoding")
    
    # 5. 使用更精确的正则表达式匹配 versionLabel 标签
    # 匹配完整的 <versionLabel>...</versionLabel> 标签
    pattern = r'(<versionLabel>)[^<]*(</versionLabel>)'
    
    # 查找所有匹配项
    matches = list(re.finditer(pattern, content))
    
    if not matches:
        print("❌ Could not find <versionLabel> tag in the XML file.")
        exit(1)
    
    # 替换第一个匹配项（通常只有一个）
    match = matches[0]
    start, end = match.span()
    before = content[:start]
    after = content[end:]
    
    # 构建新的内容
    new_content = before + f"<versionLabel>{new_version_label}</versionLabel>" + after
    
    # 6. 将更新后的内容写入输出文件（使用二进制模式）
    with open(output_path, 'wb') as file:
        file.write(new_content.encode('utf-8'))
    
    print(f"✅ Successfully updated versionLabel to '{new_version_label}'")
    print(f"✅ File '{output_path}' has been safely updated.")

except FileNotFoundError:
    print(f"❌ File not found: {app_descriptor_path}")
    exit(1)
except Exception as e:
    print(f"❌ An unexpected error occurred: {e}")
    import traceback
    traceback.print_exc()
    exit(1)