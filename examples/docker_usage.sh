#!/bin/bash
# docker_usage.sh - Docker多架构构建和使用示例

set -e

echo "=== 双峰分布观测器 Docker 使用指南 ==="
echo ""

# 检测当前架构
ARCH=$(uname -m)
echo "当前架构: $ARCH"

if [[ "$ARCH" == "aarch64" || "$ARCH" == "arm64" ]]; then
    echo "检测到ARM架构"
    PLATFORM="linux/arm64"
else
    echo "检测到x86架构"
    PLATFORM="linux/amd64"
fi

echo ""
echo "=== 选项 ==="
echo "1. 构建单架构镜像"
echo "2. 构建多架构镜像（需要buildx）"
echo "3. 运行测试"
echo "4. 运行基础示例"
echo "5. 运行ARM优化示例"
echo "6. 进入容器Shell"
echo ""

read -p "请选择 (1-6): " choice

case $choice in
    1)
        echo "构建单架构镜像..."
        docker build --platform=$PLATFORM -t bimodal-viewer:latest .
        echo "✓ 构建完成"
        ;;

    2)
        echo "构建多架构镜像（需要Docker Buildx）..."

        # 创建builder（如果不存在）
        if ! docker buildx ls | grep -q multiarch; then
            echo "创建multiarch builder..."
            docker buildx create --name multiarch --use
            docker buildx inspect --bootstrap
        else
            docker buildx use multiarch
        fi

        # 构建多架构镜像
        docker buildx build \
            --platform linux/amd64,linux/arm64 \
            -t bimodal-viewer:latest \
            --push \
            .

        echo "✓ 多架构构建完成"
        ;;

    3)
        echo "运行单元测试..."
        docker run --rm bimodal-viewer:latest test
        ;;

    4)
        echo "运行基础示例..."
        docker run --rm bimodal-viewer:latest demo
        ;;

    5)
        echo "运行ARM优化示例..."
        docker run --rm bimodal-viewer:latest arm-demo
        ;;

    6)
        echo "进入容器Shell..."
        docker run --rm -it bimodal-viewer:latest shell
        ;;

    *)
        echo "无效选项"
        exit 1
        ;;
esac

echo ""
echo "=== 其他有用命令 ==="
echo ""
echo "# 查看镜像信息"
echo "docker images bimodal-viewer"
echo ""
echo "# 检查镜像架构"
echo "docker inspect bimodal-viewer:latest | grep Architecture"
echo ""
echo "# 挂载本地数据目录"
echo "docker run -v \$(pwd)/data:/data bimodal-viewer:latest demo"
echo ""
echo "# 导出结果"
echo "docker run -v \$(pwd)/output:/output bimodal-viewer:latest demo"
echo ""

