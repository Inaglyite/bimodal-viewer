function timer = performance_timer(name)
% PERFORMANCE_TIMER 性能监控工具
%
% 输入:
%   name - 计时器名称
%
% 输出:
%   timer - 包含计时函数的结构体
%
% 示例:
%   t = performance_timer('数据生成');
%   % ... 执行代码 ...
%   t.stop();

    if nargin < 1
        name = 'Timer';
    end

    timer.name = name;
    timer.start_time = tic;
    timer.is_stopped = false;

    % 停止计时并显示结果
    timer.stop = @() stop_timer(timer);

    % 获取经过的时间（不停止计时）
    timer.elapsed = @() toc(timer.start_time);

    fprintf('[%s] 开始计时...\n', name);
end

function elapsed = stop_timer(timer)
% 停止计时并打印结果
    if ~timer.is_stopped
        elapsed = toc(timer.start_time);

        if elapsed < 1
            fprintf('[%s] 完成，耗时: %.0f ms\n', timer.name, elapsed * 1000);
        elseif elapsed < 60
            fprintf('[%s] 完成，耗时: %.2f 秒\n', timer.name, elapsed);
        else
            minutes = floor(elapsed / 60);
            seconds = elapsed - minutes * 60;
            fprintf('[%s] 完成，耗时: %d 分 %.2f 秒\n', timer.name, minutes, seconds);
        end

        timer.is_stopped = true;
    else
        elapsed = toc(timer.start_time);
        fprintf('[%s] 计时器已停止\n', timer.name);
    end
end

