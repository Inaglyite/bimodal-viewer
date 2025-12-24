% ARM_OPTIMIZATION_DEMO - ARM架构优化演示
%
% 此脚本演示在ARM架构上的优化策略和性能对比

clear; clc;

% 添加路径
addpath('../src/interfaces');
addpath('../src/core');
addpath('../src/utils');

fprintf('=== ARM架构优化演示 ===\n\n');

%% 1. 架构检测
fprintf('步骤1: 检测系统架构\n');
[is_arm, arch_info] = architecture_detector();

%% 2. 内存管理
fprintf('\n步骤2: 初始化内存管理器\n');
mem_mgr = memory_manager(2);  % 限制最大2GB内存

%% 3. 性能测试 - 不同数据规模
fprintf('\n步骤3: 性能测试\n');
test_sizes = [1e6, 5e6, 1e7, 2e7];

results = struct();
for i = 1:length(test_sizes)
    N = test_sizes(i);

    fprintf('\n--- 测试规模: %s 数据点 ---\n', format_number(N));

    % 检查是否需要分块
    if mem_mgr.needs_chunking(N)
        fprintf('  警告: 数据量超过内存限制，建议使用分块处理\n');
    end

    % 测试数据生成
    timer1 = performance_timer(sprintf('生成%s数据', format_number(N)));
    data = bimodal_generator(N, 0, 10, 50, 13.8, 0.08);
    t_gen = timer1.stop();

    % 测试直方图计算
    timer2 = performance_timer(sprintf('计算%s直方图', format_number(N)));
    edges = linspace(-50, 150, 151);
    [counts, pdf] = fast_histogram(data, edges);
    t_hist = timer2.stop();

    % 记录结果
    results(i).N = N;
    results(i).t_gen = t_gen;
    results(i).t_hist = t_hist;
    results(i).t_total = t_gen + t_hist;

    % 清理内存
    clear data counts pdf;
end

%% 4. 性能对比图表
fprintf('\n步骤4: 生成性能报告\n');

figure('Name', 'ARM性能分析', 'Position', [100, 100, 1200, 400]);

% 子图1: 数据生成时间
subplot(1, 3, 1);
bar([results.t_gen]);
set(gca, 'XTickLabel', arrayfun(@format_number, [results.N], 'UniformOutput', false));
title('数据生成时间');
ylabel('时间 (秒)');
xlabel('数据量');
grid on;

% 子图2: 直方图计算时间
subplot(1, 3, 2);
bar([results.t_hist]);
set(gca, 'XTickLabel', arrayfun(@format_number, [results.N], 'UniformOutput', false));
title('直方图计算时间');
ylabel('时间 (秒)');
xlabel('数据量');
grid on;

% 子图3: 总时间
subplot(1, 3, 3);
bar([results.t_total]);
set(gca, 'XTickLabel', arrayfun(@format_number, [results.N], 'UniformOutput', false));
title('总处理时间');
ylabel('时间 (秒)');
xlabel('数据量');
grid on;

%% 5. 优化建议
fprintf('\n=== 优化建议 ===\n');

if is_arm
    fprintf('检测到ARM架构，建议:\n');
    fprintf('  1. 使用arm_optimized.json配置（减少数据量）\n');
    fprintf('  2. 如果内存有限，使用分块处理\n');
    fprintf('  3. 避免过多的bins（建议100-200）\n');
    fprintf('  4. 考虑使用无GUI模式以节省资源\n');
else
    fprintf('检测到x86架构，性能充足，可使用默认配置\n');
end

fprintf('\n=== 演示完成 ===\n');

%% 辅助函数
function str = format_number(num)
    if num >= 1e9
        str = sprintf('%.1fB', num / 1e9);
    elseif num >= 1e6
        str = sprintf('%.1fM', num / 1e6);
    elseif num >= 1e3
        str = sprintf('%.1fK', num / 1e3);
    else
        str = sprintf('%d', num);
    end
end

