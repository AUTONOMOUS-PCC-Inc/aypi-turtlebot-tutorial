function tb3_stopRobot(velPub, velMsg)
%TB3_STOPROBOT  로봇에 0 속도를 보내 세운다.
%   tb3_stopRobot(velPub, velMsg)
%
%   tb3_avoid 와 tb3_followPath 의 onCleanup 에서 부른다. 한 곳에 모아 둔 이유는
%   정지 로직이 두 군데로 갈라지면 한쪽만 고치는 일이 생기기 때문이다.
%
%   정지에 실패해도 예외를 더 던지지 않는다. onCleanup 안에서 예외가 나면
%   정리 과정 전체가 어그러지므로, 대신 직접 세우는 방법을 화면에 안내한다.
%
%   See also TB3_AVOID, TB3_FOLLOWPATH.

    try
        velMsg.linear.x = 0; velMsg.angular.z = 0;
        send(velPub, velMsg);
        pause(0.1);
        send(velPub, velMsg);       % /cmd_vel 도 한 번쯤은 유실될 수 있다
        disp("로봇 정지");
    catch err
        fprintf(2, "정지 명령을 보내지 못했습니다: %s\n", err.message);
        fprintf(2, "WSL 터미널에서 직접 세우세요:\n");
        fprintf(2, "  ros2 topic pub --once /cmd_vel geometry_msgs/msg/Twist ""{linear: {x: 0.0}, angular: {z: 0.0}}""\n");
    end
end
