function [is_arm, arch_info] = architecture_detector()
% ARCHITECTURE_DETECTOR 检测CPU架构
%
% 输出:
%   is_arm    - 布尔值，true表示ARM架构
%   arch_info - 结构体包含架构详细信息
%
% 示例:
%   [is_arm, info] = architecture_detector();
%   if is_arm
%       disp('运行在ARM架构上');
%   end

    arch_info = struct();
    is_arm = false;

    % 获取计算机架构信息
    if ispc
        % Windows系统
        [~, result] = system('echo %PROCESSOR_ARCHITECTURE%');
        arch_info.os = 'Windows';
        arch_info.raw = strtrim(result);

        if contains(lower(result), 'arm')
            is_arm = true;
            arch_info.arch = 'ARM64';
        else
            arch_info.arch = 'x86_64';
        end

    elseif isunix
        % Linux/Mac系统
        [~, result] = system('uname -m');
        arch_info.raw = strtrim(result);

        if ismac
            arch_info.os = 'macOS';
        else
            arch_info.os = 'Linux';
        end

        % 检测ARM架构
        if contains(lower(result), {'arm', 'aarch64'})
            is_arm = true;
            arch_info.arch = 'ARM64';
        else
            arch_info.arch = 'x86_64';
        end
    else
        arch_info.os = 'Unknown';
        arch_info.arch = 'Unknown';
    end

    % 获取MATLAB版本信息
    arch_info.matlab_version = version;
    arch_info.matlab_arch = computer('arch');

    % 内存信息
    if isunix && ~ismac
        [~, mem_result] = system('free -h | grep Mem | awk ''{print $2}''');
        arch_info.total_memory = strtrim(mem_result);
    end

    % 打印检测结果
    fprintf('\n=== 架构检测结果 ===\n');
    fprintf('操作系统: %s\n', arch_info.os);
    fprintf('CPU架构: %s\n', arch_info.arch);
    fprintf('是否ARM: %s\n', mat2str(is_arm));
    fprintf('MATLAB架构: %s\n', arch_info.matlab_arch);
    if isfield(arch_info, 'total_memory')
        fprintf('系统内存: %s\n', arch_info.total_memory);
    end
    fprintf('===================\n\n');
end

