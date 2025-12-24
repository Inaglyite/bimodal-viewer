from api_client import BimodalViewerAPI

# 创建API实例
api = BimodalViewerAPI()

# 生成数据
data = api.generate_data(N=1000000)

# 计算直方图
counts, edges, pdf = api.compute_histogram(data, bins=150)

# 获取统计信息
stats = api.get_stats(data)

# 显示GUI
api.show_gui(data)

api.close()