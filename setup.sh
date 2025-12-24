#!/bin/bash
# setup.sh - 一键设置和测试脚本

set -e

echo "=========================================="
echo "  双峰分布观测器 - 安装与测试"
echo "=========================================="
echo ""

# 获取脚本所在目录
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# 检测架构
ARCH=$(uname -m)
echo "✓ 检测到架构: $ARCH"

if [[ "$ARCH" == "aarch64" || "$ARCH" == "arm64" ]]; then
    echo "  → ARM架构，建议使用优化配置"
    DEFAULT_CONFIG="configs/arm_optimized.json"
else
    echo "  → x86架构，使用默认配置"
    DEFAULT_CONFIG="configs/default.json"
fi

# 检查MATLAB
echo ""
echo "检查MATLAB环境..."
if command -v matlab &> /dev/null; then
    echo "✓ MATLAB已安装"
    MATLAB_VER=$(matlab -batch "disp(version)" 2>/dev/null || echo "未知")
    echo "  版本: $MATLAB_VER"
else
    echo "✗ 未检测到MATLAB"
    echo "  请确保MATLAB已安装并添加到PATH"
    exit 1
fi

# 检查Python（可选）
echo ""
echo "检查Python环境（可选）..."
if command -v python3 &> /dev/null; then
    echo "✓ Python3已安装"
    PYTHON_VER=$(python3 --version)
    echo "  版本: $PYTHON_VER"

    # 检查MATLAB Engine
    if python3 -c "import matlab.engine" 2>/dev/null; then
        echo "✓ MATLAB Engine API已安装"
    else
        echo "⊘ MATLAB Engine API未安装"
        echo "  安装方法: cd \$MATLABROOT/extern/engines/python && python setup.py install"
    fi
else
    echo "⊘ Python3未安装（不影响MATLAB使用）"
fi

# 检查Docker（可选）
echo ""
echo "检查Docker环境（可选）..."
if command -v docker &> /dev/null; then
    echo "✓ Docker已安装"
    DOCKER_VER=$(docker --version)
    echo "  版本: $DOCKER_VER"
else
    echo "⊘ Docker未安装（不影响MATLAB使用）"
fi

# 创建测试目录
echo ""
echo "设置目录结构..."
mkdir -p output data
echo "✓ 目录结构已就绪"

# 运行测试选项
echo ""
echo "=========================================="
echo "  选择操作:"
echo "=========================================="
echo "1. 运行单元测试"
echo "2. 运行基础示例"
echo "3. 运行ARM优化演示"
echo "4. 测试Python API"
echo "5. 构建Docker镜像"
echo "6. 跳过测试"
echo ""
read -p "请选择 (1-6) [默认: 1]: " choice
choice=${choice:-1}

case $choice in
    1)
        echo ""
        echo "运行单元测试..."
        matlab -nodisplay -nosplash -r "cd('$SCRIPT_DIR/tests'); test_bimodal_viewer; exit"
        ;;

    2)
        echo ""
        echo "运行基础示例..."
        matlab -nodisplay -nosplash -r "cd('$SCRIPT_DIR/examples'); basic_usage; exit"
        ;;

    3)
        echo ""
        echo "运行ARM优化演示..."
        matlab -nodisplay -nosplash -r "cd('$SCRIPT_DIR/examples'); arm_optimization_demo; exit"
        ;;

    4)
        echo ""
        echo "测试Python API..."
        cd examples
        python3 api_client.py
        cd ..
        ;;

    5)
        echo ""
        echo "构建Docker镜像..."
        docker build -t bimodal-viewer:latest .
        echo "✓ 镜像构建完成"
        echo ""
        echo "运行容器测试:"
        docker run --rm bimodal-viewer:latest test
        ;;

    6)
        echo ""
        echo "跳过测试"
        ;;

    *)
        echo "无效选项"
        exit 1
        ;;
esac

# 完成
echo ""
echo "=========================================="
echo "  安装完成！"
echo "=========================================="
echo ""
echo "快速开始:"
echo ""
echo "  1. MATLAB使用:"
echo "     cd $SCRIPT_DIR"
echo "     matlab"
echo "     >> addpath('src/interfaces', 'src/core', 'src/utils')"
echo "     >> bimodal_viewer()"
echo ""
echo "  2. 使用配置文件:"
echo "     >> bimodal_viewer('config', '$DEFAULT_CONFIG')"
echo ""
echo "  3. 查看示例:"
echo "     >> cd examples"
echo "     >> basic_usage"
echo ""
echo "  4. 查看文档:"
echo "     README.md"
echo ""
echo "=========================================="

