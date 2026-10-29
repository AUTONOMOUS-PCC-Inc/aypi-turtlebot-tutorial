function tb3_sl_stopHook(action)
%TB3_SL_STOPHOOK  Simulink 모델이 멈출 때 로봇을 세운다.
%   tb3_sl_stopHook('init')  모델의 InitFcn 에서 부른다
%   tb3_sl_stopHook('stop')  모델의 StopFcn 에서 부른다
%
%   왜 필요한가. Simulink 모델을 Stop 하면 Publish 블록이 그냥 멈출 뿐이고,
%   로봇은 마지막으로 받은 속도를 그대로 유지한다. MATLAB 스크립트에서
%   onCleanup 이 하던 역할을 Simulink 에서는 모델 콜백이 대신해야 한다.
%
%   퍼블리셔를 persistent 로 들고 있는 이유는 두 가지다. 첫째, StopFcn 이
%   도는 시점에 새로 만들면 DDS 탐색에 수 초가 걸려 정지 명령이 늦는다.
%   둘째, 두 번째 실행부터는 탐색 없이 바로 쓸 수 있다.
%   'init' 에서 미리 만들어 두면 사용자가 Stop 을 누를 즈음엔 이미 연결돼 있다.
%
%   See also TB3_AVOID_SL_BUILD, TB3_STOPROBOT.

    persistent node pub msg

    if nargin < 1
        action = 'stop';
    end

    DOMAIN_ID = 30;

    needNew = isempty(node);
    if ~needNew
        try
            needNew = ~isvalid(node) || ~isvalid(pub);
        catch
            needNew = true;
        end
    end
    if needNew
        ros2_matlab_setup(DOMAIN_ID);
        node = ros2node('/matlab_sl_stop', DOMAIN_ID);
        [pub, msg] = ros2publisher(node, '/cmd_vel', 'geometry_msgs/Twist');
    end

    if strcmp(action, 'init')
        return;                         % 연결만 미리 만들어 둔다
    end

    % 정지. 탐색이 아직 덜 됐을 수 있으므로 잠깐 간격을 두고 몇 번 보낸다.
    msg.linear.x = 0; msg.angular.z = 0;
    ok = false;
    for k = 1:5
        try
            send(pub, msg);
            ok = true;
        catch
        end
        pause(0.15);
    end

    if ok
        disp("로봇 정지 (Simulink StopFcn)");
    else
        fprintf(2, "정지 명령을 보내지 못했습니다.\n");
        fprintf(2, "WSL 터미널에서 직접 세우세요:\n");
        fprintf(2, "  ros2 topic pub --once /cmd_vel geometry_msgs/msg/Twist ""{linear: {x: 0.0}, angular: {z: 0.0}}""\n");
    end
end
