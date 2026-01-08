import sys
import numpy as np
from PyQt5.QtWidgets import (QApplication, QMainWindow, QWidget, QVBoxLayout,  QHBoxLayout, QLabel, QSlider, QSpinBox, QGroupBox)
from PyQt5.QtCore import Qt
from PyQt5.QtGui import QFont
import pyqtgraph as pg
from superqt import QRangeSlider
from data_model import DataModel

# pyqtgraph全局配置
pg.setConfigOption('background', 'k')
pg.setConfigOption('foreground', 'w')
pg.setConfigOptions(antialias=True)                     # 启用抗锯齿

class InteractiveHistogramApp(QMainWindow):
    def __init__(self):
        super().__init__()
        self.model = DataModel(N=5e7)                   # 初始化N=5e7
        self.model.generate_data()                      # 生成双峰正态分布数据
        self.init_ui()                              
        self.update_plot()

    def init_ui(self):
        self.setWindowTitle("超大规模交互直方图（排序数据 + 二分查找计数）")
        self.resize(1200, 950)

        base_font = QFont("Microsoft YaHei", 16)
        self.setFont(base_font)

        central_widget = QWidget()                              # 中心挂件：底板
        self.setCentralWidget(central_widget)                   # 显示至窗口
        main_layout = QVBoxLayout(central_widget)               # 垂直布局管理器

        # 控制面板
        controls_group = QGroupBox(f"原始 {int(self.model.N):,} 条 | 已排序")
        controls_group.setStyleSheet("QGroupBox { font-size: 24px; font-weight: bold; padding-top: 25px; }")
        controls_layout = QVBoxLayout()                         # 垂直布局创建
        controls_layout.setSpacing(20)                          # 设置间距
        controls_group.setLayout(controls_layout)               # 安装布局

            # 1. 分组数（柱数）控制行
        bins_layout = QHBoxLayout()                             # 水平布局管理器
        label_style = "font-size: 24px; font-weight: bold;"

        lbl_min = QLabel("最小分组:")
        lbl_min.setStyleSheet(label_style)
        bins_layout.addWidget(lbl_min)                          # 添加至当前布局
        
        self.spin_min_bins = QSpinBox()                         # 输入框（带箭头）启用
        self.spin_min_bins.setRange(1, 5000)
        self.spin_min_bins.setValue(10)
        self.spin_min_bins.setMinimumHeight(40)
        self.spin_min_bins.setFixedWidth(100)
        self.spin_min_bins.setStyleSheet("font-size: 22px;")
        self.spin_min_bins.valueChanged.connect(self.update_bins_limits)
        bins_layout.addWidget(self.spin_min_bins)

        lbl_slider = QLabel("←分组滑块→")
        lbl_slider.setStyleSheet(label_style)
        bins_layout.addWidget(lbl_slider)
        
        self.slider_bins = QSlider(Qt.Horizontal)
        self.slider_bins.setRange(10, 1000)
        self.slider_bins.setValue(100)  
        self.slider_bins.setMinimumHeight(20)
        self.slider_bins.valueChanged.connect(self.update_plot)
        bins_layout.addWidget(self.slider_bins)

        self.lbl_bins_val = QLabel("当前组数：100")
        self.lbl_bins_val.setFixedWidth(180) 
        self.lbl_bins_val.setStyleSheet(label_style)
        self.lbl_bins_val.setAlignment(Qt.AlignVCenter)
        bins_layout.addWidget(self.lbl_bins_val)

        lbl_max = QLabel("最大分组:")
        lbl_max.setStyleSheet(label_style)
        bins_layout.addWidget(lbl_max)
        
        self.spin_max_bins = QSpinBox()
        self.spin_max_bins.setRange(10, 10000)
        self.spin_max_bins.setValue(1000)
        self.spin_max_bins.setMinimumHeight(40)
        self.spin_max_bins.setFixedWidth(100)
        self.spin_max_bins.setStyleSheet("font-size: 22px;")
        self.spin_max_bins.valueChanged.connect(self.update_bins_limits)
        bins_layout.addWidget(self.spin_max_bins)
        
        controls_layout.addLayout(bins_layout)

            # 2. 范围滑块控制行
        range_layout = QHBoxLayout()
        lbl_range = QLabel("显示范围:")
        lbl_range.setStyleSheet(label_style)
        range_layout.addWidget(lbl_range)

        self.slider_range = QRangeSlider(Qt.Horizontal)
        self.slider_range.setRange(-150, 150)
        self.slider_range.setValue((-50, 150))
        self.slider_range.setMinimumHeight(20)
        self.slider_range.setFixedWidth(550)
        self.slider_range.valueChanged.connect(self.update_plot)
        range_layout.addWidget(self.slider_range)

        self.lbl_range_val = QLabel("[-50, 150]")
        self.lbl_range_val.setFixedWidth(200) # 增加宽度
        self.lbl_range_val.setAlignment(Qt.AlignCenter)
        self.lbl_range_val.setStyleSheet(label_style)
        range_layout.addWidget(self.lbl_range_val)

        # 关键点：添加弹簧支撑实现左对齐
        range_layout.addStretch()

        controls_layout.addLayout(range_layout)

        main_layout.addWidget(controls_group, stretch=1)

        # 可视化区域
        self.plot_widget = pg.PlotWidget(title="Large Scale Interactive Histogram")
        # 调大坐标轴标签字体
        label_font = {'color': '#EEE', 'size': '18pt'}
        self.plot_widget.setLabel('left', "概率密度", **label_font)
        self.plot_widget.setLabel('bottom', "数值区间", **label_font)
        self.plot_widget.showGrid(x=True, y=True, alpha=0.3)
        self.plot_widget.setXRange(-50, 150)

        self.bar_item = pg.BarGraphItem(x=[], height=[], width=1, brush=(51, 127, 204), pen=None)
        self.plot_widget.addItem(self.bar_item)

        main_layout.addWidget(self.plot_widget, stretch=8)

    def update_bins_limits(self):
        min_b = self.spin_min_bins.value()
        max_b = self.spin_max_bins.value()

        if min_b >= max_b:
            max_b = min_b + 1
            self.spin_max_bins.blockSignals(True)
            self.spin_max_bins.setValue(max_b)
            self.spin_max_bins.blockSignals(False)

        self.slider_bins.setRange(min_b, max_b)

    def update_plot(self):
        # 更新标签文字
        bins = self.slider_bins.value()
        self.lbl_bins_val.setText(f"当前组数：{bins}")

        v_min, v_max = self.slider_range.value()
        self.lbl_range_val.setText(f"[{v_min}, {v_max}]")

        if v_max <= v_min:
            return

        centers, pdf, bin_width = self.model.compute_histogram(v_min, v_max, bins)

        if centers is not None and len(centers) > 0:
            self.bar_item.setOpts(x=centers, height=pdf, width=bin_width)
            max_pdf = np.max(pdf) if len(pdf) > 0 else 0.05
            self.plot_widget.setYRange(0, max_pdf * 1.2 + 1e-6)
            self.plot_widget.setXRange(v_min, v_max)

if __name__ == "__main__":
    app = QApplication(sys.argv)
    window = InteractiveHistogramApp()
    window.show()
    sys.exit(app.exec_())