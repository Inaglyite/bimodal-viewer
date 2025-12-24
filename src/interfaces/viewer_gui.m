function viewer_gui(data, params)
% VIEWER_GUI 双峰分布交互式GUI界面
%
% 输入:
%   data   - 已排序的数据向量
%   params - 参数结构体
%
% 示例:
%   viewer_gui(data, params);

    N = length(data);

    % 创建窗口
    fig = figure('Name', sprintf('双峰分布交互观测器 - %d 数据点', N), ...
                 'NumberTitle', 'off', ...
                 'Color', [0.95 0.95 0.95], ...
                 'Position', [200 100 1000 750], ...
                 'CloseRequestFcn', @close_callback);

    % 创建坐标轴
    ax = axes('Parent', fig, 'Position', [0.1 0.35 0.85 0.58]);

    % === BUG修复：动态范围显示 ===
    % 原代码使用固定xlim([absMin, absMax])，现改为跟随滑块

    % 创建控件
    % Bins滑块
    uicontrol('Style', 'text', 'Units', 'normalized', ...
              'Position', [0.1 0.22 0.1 0.03], ...
              'String', '柱数 (Bins):', ...
              'HorizontalAlignment', 'right', ...
              'BackgroundColor', [0.95 0.95 0.95]);
    sliderBins = uicontrol('Style', 'slider', ...
                           'Min', params.minBins, ...
                           'Max', params.maxBins, ...
                           'Value', params.bins, ...
                           'Units', 'normalized', ...
                           'Position', [0.22 0.22 0.65 0.03]);

    % 左边界滑块
    uicontrol('Style', 'text', 'Units', 'normalized', ...
              'Position', [0.1 0.15 0.1 0.03], ...
              'String', '左边界 (Min):', ...
              'HorizontalAlignment', 'right', ...
              'BackgroundColor', [0.95 0.95 0.95]);
    sliderMin = uicontrol('Style', 'slider', ...
                          'Min', params.absMin, ...
                          'Max', params.absMax - 10, ...
                          'Value', params.viewMin, ...
                          'Units', 'normalized', ...
                          'Position', [0.22 0.15 0.65 0.03]);

    % 右边界滑块
    uicontrol('Style', 'text', 'Units', 'normalized', ...
              'Position', [0.1 0.08 0.1 0.03], ...
              'String', '右边界 (Max):', ...
              'HorizontalAlignment', 'right', ...
              'BackgroundColor', [0.95 0.95 0.95]);
    sliderMax = uicontrol('Style', 'slider', ...
                          'Min', params.absMin + 10, ...
                          'Max', params.absMax, ...
                          'Value', params.viewMax, ...
                          'Units', 'normalized', ...
                          'Position', [0.22 0.08 0.65 0.03]);

    % 信息文本
    infoText = uicontrol('Style', 'text', 'Units', 'normalized', ...
                         'Position', [0.1 0.02 0.8 0.04], ...
                         'String', '', ...
                         'FontSize', 10, ...
                         'BackgroundColor', [0.95 0.95 0.95]);

    % 重置按钮
    uicontrol('Style', 'pushbutton', 'String', '重置范围', ...
              'Units', 'normalized', ...
              'Position', [0.88 0.15 0.08 0.05], ...
              'Callback', @reset_callback);

    % 导出按钮
    uicontrol('Style', 'pushbutton', 'String', '导出数据', ...
              'Units', 'normalized', ...
              'Position', [0.88 0.08 0.08 0.05], ...
              'Callback', @export_callback);

    % 存储数据到figure的UserData
    gui_data = struct();
    gui_data.data = data;
    gui_data.params = params;
    gui_data.N = N;
    gui_data.last_counts = [];
    gui_data.last_edges = [];
    gui_data.last_pdf = [];
    set(fig, 'UserData', gui_data);

    % 主循环
    while ishandle(fig)
        bins = round(sliderBins.Value);
        vMin = sliderMin.Value;
        vMax = sliderMax.Value;

        % 边界检查
        if vMax <= vMin
            vMax = vMin + 1;
            sliderMax.Value = vMax;
        end

        % 更新信息
        infoText.String = sprintf('Bins: %d | 显示范围: [%.1f, %.1f] | 数据范围: [%.1f, %.1f]', ...
                                  bins, vMin, vMax, params.absMin, params.absMax);

        % 计算直方图
        edges = linspace(vMin, vMax, bins + 1);
        [counts, pdf] = fast_histogram(data, edges);

        % 保存结果
        gui_data.last_counts = counts;
        gui_data.last_edges = edges;
        gui_data.last_pdf = pdf;
        set(fig, 'UserData', gui_data);

        % 绘图
        cla(ax);
        hold(ax, 'on');
        bar(ax, edges(1:end-1), pdf, 1, 'FaceColor', [0.2 0.5 0.8], 'EdgeColor', 'none');

        grid(ax, 'on');
        % === BUG修复：动态xlim，跟随滑块范围而不是固定absMin/absMax ===
        xlim(ax, [vMin, vMax]);
        ylim(ax, [0, max(pdf) * 1.2 + 0.001]);
        xlabel(ax, '数值区间');
        ylabel(ax, '概率密度');
        title(ax, sprintf('双峰分布实时观测 (N = %s)', format_number(N)));

        drawnow;
    end

    % 嵌套函数：重置回调
    function reset_callback(~, ~)
        sliderMin.Value = params.viewMin;
        sliderMax.Value = params.viewMax;
        sliderBins.Value = params.bins;
    end

    % 嵌套函数：导出回调
    function export_callback(~, ~)
        gui_data = get(fig, 'UserData');
        if ~isempty(gui_data.last_counts)
            % 导出到工作区
            assignin('base', 'bimodal_counts', gui_data.last_counts);
            assignin('base', 'bimodal_edges', gui_data.last_edges);
            assignin('base', 'bimodal_pdf', gui_data.last_pdf);
            msgbox('数据已导出到工作区：bimodal_counts, bimodal_edges, bimodal_pdf', '导出成功');
        end
    end

    % 嵌套函数：关闭回调
    function close_callback(src, ~)
        delete(src);
    end
end

function str = format_number(num)
% 格式化大数字显示
    if num >= 1e9
        str = sprintf('%.2fB', num / 1e9);
    elseif num >= 1e6
        str = sprintf('%.2fM', num / 1e6);
    elseif num >= 1e3
        str = sprintf('%.2fK', num / 1e3);
    else
        str = sprintf('%d', num);
    end
end

