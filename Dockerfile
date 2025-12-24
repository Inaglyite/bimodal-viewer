# Dockerfile - 多架构支持的MATLAB运行环境
# 支持 x86_64 和 ARM64 (aarch64)

ARG TARGETARCH
FROM mathworks/matlab-runtime:r2021a AS base

# 设置工作目录
WORKDIR /app

# 复制项目文件
COPY src/ /app/src/
COPY configs/ /app/configs/
COPY examples/ /app/examples/

# 设置环境变量
ENV MATLAB_PATH=/app/src/interfaces
ENV LD_LIBRARY_PATH=/usr/local/MATLAB/MATLAB_Runtime/v910/runtime/glnxa64:/usr/local/MATLAB/MATLAB_Runtime/v910/bin/glnxa64:/usr/local/MATLAB/MATLAB_Runtime/v910/sys/os/glnxa64:${LD_LIBRARY_PATH}

# 根据架构选择优化配置
RUN if [ "$TARGETARCH" = "arm64" ]; then \
        echo "Configuring for ARM64..."; \
        ln -sf /app/configs/arm_optimized.json /app/configs/active.json; \
    else \
        echo "Configuring for x86_64..."; \
        ln -sf /app/configs/default.json /app/configs/active.json; \
    fi

# 创建启动脚本
RUN echo '#!/bin/bash\n\
if [ -z "$1" ]; then\n\
  echo "Usage: docker run bimodal-viewer <command>"\n\
  echo "Commands:"\n\
  echo "  test        - Run unit tests"\n\
  echo "  demo        - Run basic demo"\n\
  echo "  arm-demo    - Run ARM optimization demo"\n\
  echo "  shell       - Open bash shell"\n\
  exit 1\n\
fi\n\
\n\
case "$1" in\n\
  test)\n\
    matlab -nodisplay -nosplash -r "cd tests; test_bimodal_viewer; exit"\n\
    ;;\n\
  demo)\n\
    matlab -nodisplay -nosplash -r "cd examples; basic_usage; exit"\n\
    ;;\n\
  arm-demo)\n\
    matlab -nodisplay -nosplash -r "cd examples; arm_optimization_demo; exit"\n\
    ;;\n\
  shell)\n\
    /bin/bash\n\
    ;;\n\
  *)\n\
    echo "Unknown command: $1"\n\
    exit 1\n\
    ;;\n\
esac\n\
' > /app/entrypoint.sh && chmod +x /app/entrypoint.sh

ENTRYPOINT ["/app/entrypoint.sh"]
CMD ["demo"]

# 元数据
LABEL maintainer="bimodal-viewer"
LABEL description="Bimodal Distribution Viewer - Multi-arch support (x86_64/ARM64)"
LABEL version="1.0"

