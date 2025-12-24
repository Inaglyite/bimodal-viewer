function data = bimodal_generator(N, mu1, sigma1, mu2, sigma2, w1)
% BIMODAL_GENERATOR 生成双峰高斯分布数据
%
% 输入:
%   N      - 数据总量
%   mu1    - 左峰均值
%   sigma1 - 左峰标准差
%   mu2    - 右峰均值
%   sigma2 - 右峰标准差
%   w1     - 左峰权重 (右峰权重自动为 1-w1)
%
% 输出:
%   data   - 排序后的数据向量 (便于快速二分查找)
%
% 示例:
%   data = bimodal_generator(50000000, 0, 10, 50, 13.8, 0.08);

    % 参数验证
    if nargin < 6
        error('需要6个输入参数');
    end

    if w1 < 0 || w1 > 1
        error('权重w1必须在[0,1]范围内');
    end

    if N <= 0
        error('数据量N必须为正数');
    end

    % 计算每个峰的数据量
    N1 = round(N * w1);
    N2 = N - N1;

    fprintf('生成双峰数据: N=%d (峰1: %d, 峰2: %d)\n', N, N1, N2);

    % 生成两个高斯分布
    data1 = randn(N1, 1) * sigma1 + mu1;
    data2 = randn(N2, 1) * sigma2 + mu2;

    % 合并并排序 (为快速二分查找做准备)
    fprintf('排序数据...\n');
    data = sort([data1; data2]);

    fprintf('数据生成完成！\n');
end

