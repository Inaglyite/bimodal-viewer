#!/usr/bin/env python3
"""
API Client Example - 从Python调用MATLAB双峰分布观测器

需要安装: pip install matlab.engine (MATLAB Engine API for Python)
"""

import sys
import json
import numpy as np

try:
    import matlab.engine
    HAS_MATLAB = True
except ImportError:
    HAS_MATLAB = False
    print("警告: 未安装matlab.engine，某些功能不可用")
    print("安装方法: cd {matlabroot}/extern/engines/python && python setup.py install")


class BimodalViewerAPI:
    """双峰分布观测器Python API包装器"""

    def __init__(self, matlab_path='../src/interfaces'):
        """
        初始化API

        Args:
            matlab_path: MATLAB代码路径
        """
        if not HAS_MATLAB:
            raise RuntimeError("需要安装MATLAB Engine API for Python")

        print("启动MATLAB引擎...")
        self.eng = matlab.engine.start_matlab()

        # 添加路径
        self.eng.addpath(matlab_path, nargout=0)
        self.eng.addpath(matlab_path + '/../core', nargout=0)
        self.eng.addpath(matlab_path + '/../utils', nargout=0)
        print("MATLAB引擎已启动")

    def generate_data(self, N=1000000, mu1=0, sigma1=10, mu2=50, sigma2=13.8, w1=0.08):
        """
        生成双峰分布数据

        Args:
            N: 数据量
            mu1, sigma1: 左峰参数
            mu2, sigma2: 右峰参数
            w1: 左峰权重

        Returns:
            numpy数组
        """
        print(f"生成{N}个双峰数据点...")
        data = self.eng.bimodal_generator(float(N), float(mu1), float(sigma1),
                                          float(mu2), float(sigma2), float(w1))
        return np.array(data).flatten()

    def compute_histogram(self, data, bins=150, range_min=None, range_max=None):
        """
        计算直方图

        Args:
            data: 输入数据
            bins: 柱数
            range_min, range_max: 显示范围

        Returns:
            (counts, edges, pdf)元组
        """
        # 转换numpy数组为MATLAB数组
        matlab_data = matlab.double(data.tolist())

        if range_min is None:
            range_min = float(np.min(data))
        if range_max is None:
            range_max = float(np.max(data))

        print(f"计算直方图 (bins={bins}, range=[{range_min:.1f}, {range_max:.1f}])...")

        # 调用MATLAB函数
        counts, edges, pdf = self.eng.bimodal_viewer(
            matlab_data,
            'output', 'data',
            'bins', float(bins),
            'range', matlab.double([range_min, range_max]),
            nargout=3
        )

        # 转换回numpy数组
        return (np.array(counts).flatten(),
                np.array(edges).flatten(),
                np.array(pdf).flatten())

    def get_stats(self, data):
        """
        获取数据统计信息

        Args:
            data: 输入数据

        Returns:
            统计信息字典
        """
        matlab_data = matlab.double(data.tolist())
        params = self.eng.bimodal_viewer(matlab_data, 'output', 'stats', nargout=1)

        # 转换MATLAB结构体为Python字典
        stats = {
            'mean': float(params['mean']),
            'std': float(params['std']),
            'dataMin': float(params['dataMin']),
            'dataMax': float(params['dataMax']),
            'absMin': float(params['absMin']),
            'absMax': float(params['absMax']),
            'N': int(params['N'])
        }
        return stats

    def show_gui(self, data=None, **kwargs):
        """
        显示交互式GUI

        Args:
            data: 输入数据（可选）
            **kwargs: 其他参数（N, mu1, sigma1, mu2, sigma2, w1, bins等）
        """
        print("启动GUI...")

        if data is not None:
            matlab_data = matlab.double(data.tolist())
            self.eng.bimodal_viewer(matlab_data, 'output', 'gui', nargout=0)
        else:
            # 构建参数
            args = ['output', 'gui']
            for key, value in kwargs.items():
                args.append(key)
                if isinstance(value, list):
                    args.append(matlab.double(value))
                else:
                    args.append(float(value))

            self.eng.bimodal_viewer(*args, nargout=0)

    def close(self):
        """关闭MATLAB引擎"""
        print("关闭MATLAB引擎...")
        self.eng.quit()


def main():
    """示例主函数"""

    if not HAS_MATLAB:
        print("此示例需要MATLAB Engine API for Python")
        return

    # 创建API实例
    api = BimodalViewerAPI()

    try:
        # 示例1: 生成数据并计算直方图
        print("\n=== 示例1: 生成数据并计算直方图 ===")
        data = api.generate_data(N=1000000)
        counts, edges, pdf = api.compute_histogram(data, bins=100)
        print(f"直方图计算完成: {len(counts)} bins")

        # 示例2: 获取统计信息
        print("\n=== 示例2: 获取统计信息 ===")
        stats = api.get_stats(data)
        print(json.dumps(stats, indent=2))

        # 示例3: 使用matplotlib绘图
        try:
            import matplotlib.pyplot as plt

            print("\n=== 示例3: 使用matplotlib绘图 ===")
            plt.figure(figsize=(10, 6))
            plt.bar(edges[:-1], pdf, width=(edges[1]-edges[0]),
                   color='steelblue', edgecolor='none')
            plt.xlabel('Value')
            plt.ylabel('Probability Density')
            plt.title('Bimodal Distribution (Python API)')
            plt.grid(True, alpha=0.3)
            plt.savefig('bimodal_python.png', dpi=150, bbox_inches='tight')
            print("图像已保存: bimodal_python.png")

        except ImportError:
            print("matplotlib未安装，跳过绘图示例")

        # 示例4: 显示GUI（可选，取消注释以运行）
        # print("\n=== 示例4: 显示GUI ===")
        # api.show_gui(data, bins=150)

    finally:
        api.close()

    print("\n=== Python API示例完成 ===")


if __name__ == '__main__':
    main()

