% TEST_BIMODAL_VIEWER - 单元测试脚本
%
% 测试所有模块功能

clear; clc;

% 添加路径
addpath('../src/interfaces');
addpath('../src/core');
addpath('../src/utils');

fprintf('=== 双峰分布观测器单元测试 ===\n\n');

test_count = 0;
pass_count = 0;

%% 测试1: 数据生成器
fprintf('测试1: bimodal_generator\n');
test_count = test_count + 1;
try
    data = bimodal_generator(10000, 0, 10, 50, 13.8, 0.08);
    assert(length(data) == 10000, '数据量不正确');
    assert(issorted(data), '数据未排序');
    fprintf('  ✓ 通过\n\n');
    pass_count = pass_count + 1;
catch ME
    fprintf('  ✗ 失败: %s\n\n', ME.message);
end

%% 测试2: 快速直方图
fprintf('测试2: fast_histogram\n');
test_count = test_count + 1;
try
    data = sort(randn(10000, 1) * 10);
    edges = linspace(-50, 50, 51);
    [counts, pdf] = fast_histogram(data, edges);

    assert(length(counts) == 50, 'Counts长度不正确');
    assert(length(pdf) == 50, 'PDF长度不正确');
    assert(sum(counts) == 10000, '计数总和不正确');
    assert(abs(sum(pdf) * (edges(2) - edges(1)) - 1) < 0.01, 'PDF积分不为1');

    fprintf('  ✓ 通过\n\n');
    pass_count = pass_count + 1;
catch ME
    fprintf('  ✗ 失败: %s\n\n', ME.message);
end

%% 测试3: 分布分析
fprintf('测试3: distribution_core\n');
test_count = test_count + 1;
try
    data = [randn(1000, 1) * 10; randn(9000, 1) * 13.8 + 50];
    params = distribution_core(data, 'method', 'quantile');

    assert(isfield(params, 'mean'), '缺少mean字段');
    assert(isfield(params, 'std'), '缺少std字段');
    assert(isfield(params, 'absMin'), '缺少absMin字段');
    assert(isfield(params, 'absMax'), '缺少absMax字段');

    fprintf('  ✓ 通过\n\n');
    pass_count = pass_count + 1;
catch ME
    fprintf('  ✗ 失败: %s\n\n', ME.message);
end

%% 测试4: 架构检测
fprintf('测试4: architecture_detector\n');
test_count = test_count + 1;
try
    [is_arm, arch_info] = architecture_detector();

    assert(islogical(is_arm), 'is_arm应为布尔值');
    assert(isstruct(arch_info), 'arch_info应为结构体');
    assert(isfield(arch_info, 'os'), '缺少os字段');
    assert(isfield(arch_info, 'arch'), '缺少arch字段');

    fprintf('  ✓ 通过\n\n');
    pass_count = pass_count + 1;
catch ME
    fprintf('  ✗ 失败: %s\n\n', ME.message);
end

%% 测试5: 内存管理
fprintf('测试5: memory_manager\n');
test_count = test_count + 1;
try
    mgr = memory_manager(2);

    assert(isstruct(mgr), 'mgr应为结构体');
    assert(mgr.max_memory_gb == 2, '内存限制设置错误');

    chunk_size = mgr.calculate_chunk_size(10000);
    assert(chunk_size > 0, 'chunk_size应为正数');

    fprintf('  ✓ 通过\n\n');
    pass_count = pass_count + 1;
catch ME
    fprintf('  ✗ 失败: %s\n\n', ME.message);
end

%% 测试6: 性能计时
fprintf('测试6: performance_timer\n');
test_count = test_count + 1;
try
    timer = performance_timer('测试');
    pause(0.1);
    elapsed = timer.stop();

    assert(elapsed >= 0.1, '计时不准确');

    fprintf('  ✓ 通过\n\n');
    pass_count = pass_count + 1;
catch ME
    fprintf('  ✗ 失败: %s\n\n', ME.message);
end

%% 测试7: API接口 - 数据输出模式
fprintf('测试7: bimodal_viewer API (data模式)\n');
test_count = test_count + 1;
try
    [counts, edges, pdf] = bimodal_viewer('N', 10000, ...
                                           'output', 'data', ...
                                           'bins', 50);

    assert(length(counts) == 50, 'Counts长度不正确');
    assert(length(edges) == 51, 'Edges长度不正确');
    assert(length(pdf) == 50, 'PDF长度不正确');

    fprintf('  ✓ 通过\n\n');
    pass_count = pass_count + 1;
catch ME
    fprintf('  ✗ 失败: %s\n\n', ME.message);
end

%% 测试8: API接口 - 统计模式
fprintf('测试8: bimodal_viewer API (stats模式)\n');
test_count = test_count + 1;
try
    params = bimodal_viewer('N', 10000, 'output', 'stats');

    assert(isstruct(params), 'params应为结构体');
    assert(params.N == 10000, '数据量不正确');

    fprintf('  ✓ 通过\n\n');
    pass_count = pass_count + 1;
catch ME
    fprintf('  ✗ 失败: %s\n\n', ME.message);
end

%% 测试9: 配置文件加载
fprintf('测试9: load_config\n');
test_count = test_count + 1;
try
    config_file = '../configs/default.json';
    if exist(config_file, 'file')
        params = load_config(config_file, struct());
        assert(isstruct(params), 'params应为结构体');
        fprintf('  ✓ 通过\n\n');
        pass_count = pass_count + 1;
    else
        fprintf('  ⊘ 跳过（配置文件不存在）\n\n');
    end
catch ME
    fprintf('  ✗ 失败: %s\n\n', ME.message);
end

%% 测试10: 边界检查
fprintf('测试10: 边界条件测试\n');
test_count = test_count + 1;
try
    % 测试小数据集
    small_data = randn(100, 1);
    params = bimodal_viewer(small_data, 'output', 'stats');
    assert(params.N == 100, '小数据集处理失败');

    % 测试单峰（w1=0）
    data_single = bimodal_generator(1000, 0, 10, 50, 13.8, 0);
    assert(length(data_single) == 1000, '单峰数据生成失败');

    fprintf('  ✓ 通过\n\n');
    pass_count = pass_count + 1;
catch ME
    fprintf('  ✗ 失败: %s\n\n', ME.message);
end

%% 测试总结
fprintf('=== 测试总结 ===\n');
fprintf('总测试数: %d\n', test_count);
fprintf('通过: %d\n', pass_count);
fprintf('失败: %d\n', test_count - pass_count);
fprintf('通过率: %.1f%%\n', pass_count / test_count * 100);

if pass_count == test_count
    fprintf('\n✓ 所有测试通过！\n');
else
    fprintf('\n✗ 部分测试失败，请检查\n');
end

