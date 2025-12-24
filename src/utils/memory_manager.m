function manager = memory_manager(max_memory_gb)
% MEMORY_MANAGER 内存管理工具
%
% 输入:
%   max_memory_gb - 最大允许使用的内存(GB), 默认2GB
%
% 输出:
%   manager - 包含内存管理函数的结构体
%
% 示例:
%   mgr = memory_manager(2);
%   chunk_size = mgr.calculate_chunk_size(50000000);

    if nargin < 1
        max_memory_gb = 2;
    end

    manager.max_memory_bytes = max_memory_gb * 1024^3;
    manager.max_memory_gb = max_memory_gb;

    % 获取当前内存使用情况
    manager.get_memory_usage = @get_memory_usage;

    % 计算安全的块大小
    manager.calculate_chunk_size = @(N) calculate_chunk_size(N, manager.max_memory_bytes);

    % 检查是否需要分块处理
    manager.needs_chunking = @(N) needs_chunking(N, manager.max_memory_bytes);

    % 打印内存信息
    fprintf('\n=== 内存管理器初始化 ===\n');
    fprintf('最大允许内存: %.2f GB\n', max_memory_gb);

    current = get_memory_usage();
    fprintf('当前MATLAB内存: %.2f MB\n', current / 1024^2);
    fprintf('========================\n\n');
end

function mem_bytes = get_memory_usage()
% 获取当前MATLAB进程内存使用
    if isunix
        [~, result] = system(['ps -p ' num2str(feature('getpid')) ' -o rss=']);
        mem_bytes = str2double(result) * 1024; % KB to bytes
    else
        % Windows - 使用MATLAB内置函数
        mem_info = memory;
        mem_bytes = mem_info.MemUsedMATLAB;
    end
end

function chunk_size = calculate_chunk_size(N, max_mem)
% 计算安全的数据块大小
    bytes_per_element = 8; % double类型
    total_bytes_needed = N * bytes_per_element * 2; % 估算需要2倍空间

    if total_bytes_needed > max_mem
        chunk_size = floor(max_mem / (bytes_per_element * 2));
        fprintf('警告: 数据量过大，建议分块处理。块大小: %d\n', chunk_size);
    else
        chunk_size = N;
    end
end

function needs = needs_chunking(N, max_mem)
% 判断是否需要分块
    bytes_per_element = 8;
    total_bytes_needed = N * bytes_per_element * 2;
    needs = total_bytes_needed > max_mem;
end

