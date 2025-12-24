function params = load_config(config_file, default_params)
% LOAD_CONFIG 从配置文件加载参数
%
% 输入:
%   config_file    - 配置文件路径 (支持JSON)
%   default_params - 默认参数结构体
%
% 输出:
%   params - 合并后的参数结构体
%
% 示例:
%   params = load_config('configs/default.json', default_params);

    if nargin < 2
        default_params = struct();
    end

    % 检查文件是否存在
    if ~exist(config_file, 'file')
        error('配置文件不存在: %s', config_file);
    end

    % 根据扩展名判断文件类型
    [~, ~, ext] = fileparts(config_file);

    switch lower(ext)
        case '.json'
            params = load_json_config(config_file, default_params);
        case {'.yaml', '.yml'}
            params = load_yaml_config(config_file, default_params);
        case '.mat'
            params = load_mat_config(config_file, default_params);
        otherwise
            error('不支持的配置文件格式: %s', ext);
    end

    fprintf('配置已加载: %s\n', config_file);
end

function params = load_json_config(json_file, default_params)
% 加载JSON配置文件
    try
        % MATLAB R2016b+支持jsondecode
        fid = fopen(json_file, 'r');
        raw = fread(fid, inf, 'uint8=>char')';
        fclose(fid);

        config = jsondecode(raw);

        % 合并配置
        params = default_params;
        fields = fieldnames(config);
        for i = 1:length(fields)
            params.(fields{i}) = config.(fields{i});
        end
    catch ME
        error('JSON解析失败: %s', ME.message);
    end
end

function params = load_yaml_config(yaml_file, default_params)
% 加载YAML配置文件 (需要YAML工具箱或手动解析)
    warning('YAML支持需要额外工具箱，使用默认参数');
    params = default_params;
end

function params = load_mat_config(mat_file, default_params)
% 加载MAT配置文件
    loaded = load(mat_file);
    if isfield(loaded, 'params')
        config = loaded.params;
    else
        % 使用第一个变量
        vars = fieldnames(loaded);
        config = loaded.(vars{1});
    end

    % 合并配置
    params = default_params;
    fields = fieldnames(config);
    for i = 1:length(fields)
        params.(fields{i}) = config.(fields{i});
    end
end

