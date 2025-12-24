function params = distribution_core(data, varargin)
% DISTRIBUTION_CORE 数据分布分析核心函数
%
% 输入:
%   data     - 输入数据向量
%   'method' - 范围检测方法: 'auto', 'minmax', 'quantile' (默认: 'quantile')
%   'outlier_percentile' - 异常值分位数 (默认: [0.001, 0.999])
%
% 输出:
%   params   - 结构体包含:
%              .dataMin - 数据最小值
%              .dataMax - 数据最大值
%              .absMin  - 建议显示最小值
%              .absMax  - 建议显示最大值
%              .mean    - 数据均值
%              .std     - 数据标准差
%
% 示例:
%   params = distribution_core(data, 'method', 'quantile');

    % 解析输入参数
    p = inputParser;
    addParameter(p, 'method', 'quantile', @ischar);
    addParameter(p, 'outlier_percentile', [0.001, 0.999], @isnumeric);
    parse(p, varargin{:});

    method = p.Results.method;
    outlier_pct = p.Results.outlier_percentile;

    % 基本统计
    params.dataMin = min(data);
    params.dataMax = max(data);
    params.mean = mean(data);
    params.std = std(data);
    params.N = length(data);

    % 根据方法确定显示范围
    switch method
        case 'minmax'
            % 直接使用最小最大值
            params.absMin = params.dataMin;
            params.absMax = params.dataMax;

        case 'quantile'
            % 使用分位数排除异常值
            params.absMin = quantile(data, outlier_pct(1));
            params.absMax = quantile(data, outlier_pct(2));

        case 'auto'
            % 自动检测：使用3-sigma原则
            params.absMin = params.mean - 3 * params.std;
            params.absMax = params.mean + 3 * params.std;

        otherwise
            error('未知方法: %s', method);
    end

    % 添加一些边距使显示更美观
    range = params.absMax - params.absMin;
    params.absMin = params.absMin - 0.05 * range;
    params.absMax = params.absMax + 0.05 * range;

    % 打印摘要信息
    fprintf('\n=== 数据分布摘要 ===\n');
    fprintf('数据量: %d\n', params.N);
    fprintf('范围: [%.2f, %.2f]\n', params.dataMin, params.dataMax);
    fprintf('均值: %.2f, 标准差: %.2f\n', params.mean, params.std);
    fprintf('建议显示范围: [%.2f, %.2f]\n', params.absMin, params.absMax);
    fprintf('====================\n\n');
end

