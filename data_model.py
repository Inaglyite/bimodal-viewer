import numpy as np
import polars as pl


class DataModel:
    def __init__(self, N=50_000_000):
        self.N = int(N)
        self.data = None
        self.sorted_array = None

    def generate_data(self):
        # 双峰正态分布
        print(f"Loading {self.N}...")

        # 参数定义
        mu1, sigma1, w1 = 0,  8,    0.06
        mu2, sigma2, w2 = 50, 13.8, 0.94

        N1 = int(self.N * w1)                                       # 将N按w1和w2拆分成N1和N2
        N2 = self.N - N1

        data1 = np.random.randn(N1) * sigma1 + mu1                  # 正态分布
        data2 = np.random.randn(N2) * sigma2 + mu2

        combined_data = np.concatenate([data1, data2])              # 合并data1 & data2
        combined_data.sort()                                        # 排序

        # 数据流：Numpy -> Polars DataFrame -> Numpy  Polars：零拷贝，保留信息更多                  
        self.df = pl.DataFrame({"value": combined_data})            # 存入Polars DataFrame 

        self.sorted_array = self.df["value"].to_numpy()             # 获取numpy视图用于计算（指向原数据内存地址）
        print("Finished.")
    
    # 二分查找
    def compute_histogram(self, v_min, v_max, bins):
        if self.sorted_array is None:
            return None, None
        if v_max <= v_min:                                          # 无效范围
            return np.array([]), np.array([])
        
        edges = np.linspace(v_min, v_max, bins + 1)                 # 生成边界
        indices = np.searchsorted(self.sorted_array, edges)         # 二分查找
        counts = np.diff(indices)                                   # 统计频数

        # 计算概率密度 (PDF)
        bin_width = (v_max - v_min) / bins
        pdf = counts / (self.N * bin_width)

        centers = (edges[:-1] + edges[1:]) / 2                      # 计算每个柱子的中心位置用于绘图

        return centers, pdf, bin_width