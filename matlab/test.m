clc;
clear;
close all;

N = 50000000; % 数据总量

%左峰
mu1 = 0; 
sigma1 = 10;

%右峰
mu2 = 50; 
sigma2 = 13.8;

%权重
w1 = 0.08;
w2 = 0.92;

%直方图初始设置
minBins = 10;
maxBins = 1000;
initBins = 150;

%观测区间初始设置 (对应要求：数据分布在 [-50, 150])
absMin = -50;
absMax = 150;
viewMin = -50;
viewMax = 150;

%双峰数据
fprintf('Generating %d points of bimodal Gaussian data...\n', N);
N1 = round(N * w1);
N2 = N - N1;

data1 = randn(N1,1)*sigma1 + mu1;
data2 = randn(N2,1)*sigma2 + mu2;
data = [data1; data2];

% 排序以便进行快速二分查找统计
disp('Sorting data for fast binning...');
data = sort(data);

%创建窗口
fig = figure( ...
    'Name','双峰分布交互观测器 (范围: -50 到 150)', ...
    'NumberTitle','off', ...
    'Color', [0.95 0.95 0.95], ...
    'Position', [200 100 1000 750]);

ax = axes('Parent',fig,'Position',[0.1 0.35 0.85 0.58]);

%Bins滑块
uicontrol('Style','text','Units','normalized','Position',[0.1 0.22 0.1 0.03],...
    'String','柱数 (Bins):','HorizontalAlignment','right','BackgroundColor',[0.95 0.95 0.95]);
sliderBins = uicontrol('Style','slider','Min',minBins,'Max',maxBins,'Value',initBins,...
    'Units','normalized','Position',[0.22 0.22 0.65 0.03]);

%左边界滑块 (Min Range)
uicontrol('Style','text','Units','normalized','Position',[0.1 0.15 0.1 0.03],...
    'String','左边界 (Min):','HorizontalAlignment','right','BackgroundColor',[0.95 0.95 0.95]);
sliderMin = uicontrol('Style','slider','Min',absMin,'Max',absMax-10,'Value',viewMin,...
    'Units','normalized','Position',[0.22 0.15 0.65 0.03]);

%右边界滑块 (Max Range)
uicontrol('Style','text','Units','normalized','Position',[0.1 0.08 0.1 0.03],...
    'String','右边界 (Max):','HorizontalAlignment','right','BackgroundColor',[0.95 0.95 0.95]);
sliderMax = uicontrol('Style','slider','Min',absMin+10,'Max',absMax,'Value',viewMax,...
    'Units','normalized','Position',[0.22 0.08 0.65 0.03]);

% --- 信息文本显示 ---
infoText = uicontrol('Style','text','Units','normalized','Position',[0.2 0.02 0.6 0.04],...
    'String','','FontSize',10,'BackgroundColor',[0.95 0.95 0.95]);

%主循环
while ishandle(fig)
    bins = round(sliderBins.Value);
    vMin = sliderMin.Value;
    vMax = sliderMax.Value;
    
    if vMax <= vMin
        vMax = vMin + 0.1;
    end
    
    infoText.String = sprintf('Bins: %d | Range: [%.1f, %.1f]', bins, vMin, vMax);
    
    %定义Bin边界
    edges = linspace(vMin, vMax, bins+1);
    counts = zeros(bins,1);
    
    %二分计数
    % 只统计当前观测区间内的数据
    for i = 1:bins
        % 统计落在 [edges(i), edges(i+1)) 之间的数据点数
        
        % 查找第一个 >= edges(i) 的索引
        low = 1; high = N + 1;
        val = edges(i);
        while low < high
            mid = floor((low + high)/2);
            if mid <= N && data(mid) < val
                low = mid + 1;
            else
                high = mid;
            end
        end
        idxL = low;
        
        %查找第一个 >= edges(i+1) 的索引
        low = 1; high = N + 1;
        val = edges(i+1);
        while low < high
            mid = floor((low + high)/2);
            if mid <= N && data(mid) < val
                low = mid + 1;
            else
                high = mid;
            end
        end
        idxR = low;
        
        counts(i) = idxR - idxL;
    end
    
    %计算概率密度
    binWidth = (vMax - vMin) / bins;
    pdf = counts / (N * binWidth);
    
    cla(ax);
    hold(ax, 'on');
    bar(ax, edges(1:end-1), pdf, 1, 'FaceColor',[0.2 0.5 0.8], 'EdgeColor','none');
    
    grid(ax,'on');
    xlim(ax, [absMin, absMax]); % 固定坐标系范围
    ylim(ax, [0, max(pdf)*1.2 + 0.001]);
    xlabel(ax,'数值区间');
    ylabel(ax,'概率密度');
    title(ax,['超大规模数据分布实时观测 (N = ', num2str(N, '%.0e'), ')']);
    
    drawnow;
end