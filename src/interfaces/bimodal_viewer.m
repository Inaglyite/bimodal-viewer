function varargout = bimodal_viewer(varargin)
% BIMODAL_VIEWER 双峰分布交互观测器 - 主API接口
%
% 用法1: 使用预生成数据
%   bimodal_viewer(data)
%   bimodal_viewer(data, 'bins', 150, 'range', [-50, 150])
%
% 用法2: 生成新数据
%   bimodal_viewer('N', 50000000, 'mu1', 0, 'sigma1', 10, ...
%                  'mu2', 50, 'sigma2', 13.8, 'w1', 0.08)
%
% 用法3: 使用配置文件
%   bimodal_viewer('config', 'configs/default.json')
%
% 参数:
%   data   - 输入数据（如果提供，则不生成新数据）
%   N      - 数据量（默认: 50000000）
%   mu1    - 左峰均值（默认: 0）
%   sigma1 - 左峰标准差（默认: 10）
%   mu2    - 右峰均值（默认: 50）
%   sigma2 - 右峰标准差（默认: 13.8）
%   w1     - 左峰权重（默认: 0.08）
%   bins   - 初始柱数（默认: 150）
%   range  - 显示范围 [min, max]（默认: 自动检测）
%   output - 输出模式: 'gui', 'data', 'stats' (默认: 'gui')
%   config - 配置文件路径
%
% 输出:
%   根据output参数:
%   'gui'   - 无输出，显示交互界面
%   'data'  - [counts, edges, pdf]
%   'stats' - params结构体

    % 添加路径
    add_bimodal_paths();

    % 解析输入参数
    [data, params] = parse_inputs(varargin{:});

    % 如果没有提供数据，生成新数据
    if isempty(data)
        timer = performance_timer('数据生成');
        data = bimodal_generator(params.N, params.mu1, params.sigma1, ...
                                  params.mu2, params.sigma2, params.w1);
        timer.stop();
    end

    % 数据分析
    timer = performance_timer('数据分析');
    dist_params = distribution_core(data, 'method', 'quantile');
    timer.stop();

    % 合并参数
    params = merge_params(params, dist_params);

    % 根据输出模式执行
    switch params.output
        case 'gui'
            % 启动GUI界面
            viewer_gui(data, params);

        case 'data'
            % 返回数据
            edges = linspace(params.viewMin, params.viewMax, params.bins + 1);
            [counts, pdf] = fast_histogram(data, edges);
            varargout{1} = counts;
            varargout{2} = edges;
            varargout{3} = pdf;

        case 'stats'
            % 返回统计信息
            varargout{1} = params;

        otherwise
            error('未知输出模式: %s', params.output);
    end
end

function add_bimodal_paths()
% 添加所有必需的路径
    file_path = mfilename('fullpath');
    [base_dir, ~, ~] = fileparts(file_path);

    % 添加core, utils子目录
    addpath(fullfile(base_dir, '..', 'core'));
    addpath(fullfile(base_dir, '..', 'utils'));
end

function [data, params] = parse_inputs(varargin)
% 解析输入参数
    data = [];

    % 默认参数
    params = struct();
    params.N = 50000000;
    params.mu1 = 0;
    params.sigma1 = 10;
    params.mu2 = 50;
    params.sigma2 = 13.8;
    params.w1 = 0.08;
    params.bins = 150;
    params.minBins = 10;
    params.maxBins = 1000;
    params.output = 'gui';
    params.auto_range = true;

    % 如果第一个参数是数值向量，视为数据
    if nargin >= 1 && isnumeric(varargin{1}) && isvector(varargin{1})
        data = sort(varargin{1}(:)); % 确保是列向量且已排序
        varargin = varargin(2:end);
    end

    % 解析名值对参数
    i = 1;
    while i <= length(varargin)
        if ischar(varargin{i})
            param_name = varargin{i};

            if strcmp(param_name, 'config')
                % 从配置文件加载
                config_file = varargin{i+1};
                params = load_config(config_file, params);
                i = i + 2;
            elseif i < length(varargin)
                param_value = varargin{i+1};

                % 特殊处理range参数
                if strcmp(param_name, 'range')
                    params.viewMin = param_value(1);
                    params.viewMax = param_value(2);
                    params.auto_range = false;
                else
                    params.(param_name) = param_value;
                end
                i = i + 2;
            else
                error('参数 %s 缺少值', param_name);
            end
        else
            error('期望参数名称为字符串');
        end
    end
end

function merged = merge_params(params, dist_params)
% 合并参数，自动范围检测
    merged = params;

    if params.auto_range
        merged.absMin = dist_params.absMin;
        merged.absMax = dist_params.absMax;
        merged.viewMin = dist_params.absMin;
        merged.viewMax = dist_params.absMax;
    elseif ~isfield(params, 'viewMin')
        merged.absMin = dist_params.absMin;
        merged.absMax = dist_params.absMax;
        merged.viewMin = dist_params.absMin;
        merged.viewMax = dist_params.absMax;
    else
        % 使用用户指定的范围，但记录数据范围
        if ~isfield(merged, 'absMin')
            merged.absMin = params.viewMin;
            merged.absMax = params.viewMax;
        end
    end
end

