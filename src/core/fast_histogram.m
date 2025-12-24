function [counts, pdf] = fast_histogram(data, edges)
% FAST_HISTOGRAM 使用二分查找快速计算直方图
%
% 输入:
%   data  - 已排序的数据向量
%   edges - 直方图边界数组 (长度为bins+1)
%
% 输出:
%   counts - 每个区间的计数
%   pdf    - 概率密度
%
% 示例:
%   edges = linspace(-50, 150, 151);
%   [counts, pdf] = fast_histogram(sorted_data, edges);

    N = length(data);
    bins = length(edges) - 1;
    counts = zeros(bins, 1);

    % 对每个区间进行二分查找统计
    for i = 1:bins
        % 查找第一个 >= edges(i) 的索引
        idxL = binary_search_lower(data, edges(i), N);

        % 查找第一个 >= edges(i+1) 的索引
        idxR = binary_search_lower(data, edges(i+1), N);

        counts(i) = idxR - idxL;
    end

    % 计算概率密度
    if nargout > 1
        binWidth = (edges(end) - edges(1)) / bins;
        pdf = counts / (N * binWidth);
    end
end

function idx = binary_search_lower(data, val, N)
% 二分查找: 返回第一个 >= val 的索引
    low = 1;
    high = N + 1;

    while low < high
        mid = floor((low + high) / 2);
        if mid <= N && data(mid) < val
            low = mid + 1;
        else
            high = mid;
        end
    end

    idx = low;
end

