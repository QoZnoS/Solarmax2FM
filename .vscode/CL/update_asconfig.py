import json
import sys
import os
from pathlib import Path

def update_asconfig(is_windows, is_debug):
    """根据参数更新 asconfig.json 文件"""
    
    # 当前脚本所在目录
    script_dir = Path(__file__).parent
    
    # 原文件路径
    source_file = script_dir / "asconfig.json"
    
    # 目标文件路径（根目录）
    target_file = script_dir.parent.parent / "asconfig.json"
    
    try:
        # 读取原文件
        with open(source_file, 'r', encoding='utf-8') as f:
            data = json.load(f)
        
        # 参数1：是否为Windows
        if not is_windows:
            data["config"] = "airmobile"
            print(f"✓ 将 config 修改为: {data['config']}")
        else:
            print(f"✓ 保持 config 为: {data['config']}")
        
        # 参数2：是否为debug
        if is_debug:
            data["compilerOptions"]["advanced-telemetry"] = True
            print(f"✓ 将 advanced-telemetry 修改为: {data['compilerOptions']['advanced-telemetry']}")
        else:
            print(f"✓ 保持 advanced-telemetry 为: {data['compilerOptions']['advanced-telemetry']}")
        
        # 写入到根目录
        with open(target_file, 'w', encoding='utf-8') as f:
            json.dump(data, f, indent=4, ensure_ascii=False)
        
        print(f"✓ 已生成更新后的配置文件: {target_file}")
        
    except FileNotFoundError:
        print(f"✗ 错误: 找不到源文件 {source_file}")
        return False
    except json.JSONDecodeError as e:
        print(f"✗ 错误: JSON解析失败 - {e}")
        return False
    except Exception as e:
        print(f"✗ 错误: {e}")
        return False
    
    return True

def main():
    """主函数：解析命令行参数"""
    
    # 检查参数数量
    if len(sys.argv) != 3:
        print("使用方法: python update_asconfig.py <is_windows> <is_debug>")
        print("参数说明:")
        print("  参数1: is_windows - 'true' 表示Windows平台，否则为其他平台")
        print("  参数2: is_debug   - 'true' 表示调试模式，否则为发布模式")
        print("示例: python update_asconfig.py true false")
        return
    
    # 解析参数
    is_windows_str = sys.argv[1].lower()
    is_debug_str = sys.argv[2].lower()
    
    # 转换为布尔值
    is_windows = is_windows_str == "true"
    is_debug = is_debug_str == "true"
    
    print(f"开始更新 asconfig.json:")
    print(f"  是否为Windows平台: {is_windows}")
    print(f"  是否为调试模式: {is_debug}")
    print("-" * 40)
    
    # 执行更新
    if update_asconfig(is_windows, is_debug):
        print("-" * 40)
        print("✓ 更新完成!")
    else:
        print("-" * 40)
        print("✗ 更新失败!")

if __name__ == "__main__":
    main()