% BASIC_USAGE - 双峰分布观测器基本使用示例
%
% 此脚本演示如何使用bimodal_viewer的各种功能

clear; clc;

% 添加路径
addpath('../src/interfaces');
addpath('../src/core');
addpath('../src/utils');

fprintf('=== 双峰分布观测器使用示例 ===\n\n');

%% 示例1: 使用默认参数启动GUI
fprintf('示例1: 使用默认参数\n');
fprintf('  执行: bimodal_viewer()\n');
% bimodal_viewer();  % 取消注释以运行

%% 示例2: 自定义参数
fprintf('\n示例2: 自定义参数\n');
fprintf('  生成1000万数据点，使用200个bins\n');
% bimodal_viewer('N', 10000000, 'bins', 200);  % 取消注释以运行

%% 示例3: 使用自己的数据
fprintf('\n示例3: 使用预生成数据\n');
N = 1000000;
fprintf('  生成%d个数据点...\n', N);
data = [randn(N*0.1, 1)*10; randn(N*0.9, 1)*13.8 + 50];
fprintf('  启动观测器...\n');
% bimodal_viewer(data, 'bins', 150);  % 取消注释以运行

%% 示例4: 只获取数据不显示GUI
fprintf('\n示例4: 数据输出模式\n');
fprintf('  生成数据并计算直方图...\n');
[counts, edges, pdf] = bimodal_viewer('N', 1000000, ...
                                       'output', 'data', ...
                                       'bins', 100);
fprintf('  返回值: counts(%d), edges(%d), pdf(%d)\n', ...
        length(counts), length(edges), length(pdf));

% 简单绘图
figure('Name', '数据输出示例');
bar(edges(1:end-1), pdf, 1);
title('示例4: 通过API获取的直方图数据');
xlabel('数值');
ylabel('概率密度');
grid on;

%% 示例5: 获取统计信息
fprintf('\n示例5: 统计信息模式\n');
params = bimodal_viewer('N', 1000000, 'output', 'stats');
fprintf('  数据统计:\n');
fprintf('    均值: %.2f\n', params.mean);
fprintf('    标准差: %.2f\n', params.std);
fprintf('    建议范围: [%.2f, %.2f]\n', params.absMin, params.absMax);

%% 示例6: 使用配置文件
fprintf('\n示例6: 从配置文件加载\n');
fprintf('  加载 configs/default.json\n');
% bimodal_viewer('config', '../configs/default.json');  % 取消注释以运行

%% 示例7: 指定显示范围
fprintf('\n示例7: 手动指定显示范围\n');
fprintf('  范围: [-30, 80]\n');
% bimodal_viewer('N', 5000000, 'range', [-30, 80]);  % 取消注释以运行

%% 示例8: ARM架构检测
fprintf('\n示例8: 检测运行架构\n');
[is_arm, arch_info] = architecture_detector();

if is_arm
    fprintf('  检测到ARM架构，使用优化配置\n');
    % bimodal_viewer('config', '../configs/arm_optimized.json');
else
    fprintf('  检测到x86架构，使用默认配置\n');
    % bimodal_viewer('config', '../configs/default.json');
end

fprintf('\n=== 示例完成 ===\n');
fprintf('提示: 取消注释各示例中的函数调用以实际运行\n');

