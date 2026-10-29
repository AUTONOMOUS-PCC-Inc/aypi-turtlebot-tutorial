function tb3_followPath(odomSub, velPub, velMsg, ctrl, goalXY)
%TB3_FOLLOWPATH  경로를 따라가다 목표에 닿으면 선다.
%   tb3_followPath(odomSub, velPub, velMsg, ctrl, goalXY)
%     odomSub  /odom 구독자
%     velPub   /cmd_vel 퍼블리셔,   velMsg  그 메시지
%     ctrl     controllerPurePursuit 객체 ( [v,w] = ctrl(pose) 꼴이면 무엇이든 됨 )
%     goalXY   목표 지점 [x y] (m)
%
%   멈추기: Ctrl+C — 로봇도 자동으로 정지한다.
%
%   왜 이 루프만 따로 함수로 빼냈는가.
%   tb3_slam_plan.m 은 섹션 단위로 실행하는 스크립트다. 스크립트 본문에서
%   Ctrl+C 를 누르면 실행만 멈출 뿐, 변수들은 기본 작업공간에 그대로 남는다.
%   그래서 onCleanup 이 소멸될 계기가 없고, 정지 명령이 나가지 않아 로봇이
%   마지막 속도 그대로 계속 간다.
%   함수 안이라면 Ctrl+C 때 함수 작업공간이 해제되면서 onCleanup 이 돈다.
%   이때 퍼블리셔와 노드는 부른 쪽(기본 작업공간)이 계속 들고 있으므로,
%   정지 명령을 보내는 순간에도 유효하다.
%
%   See also TB3_SLAM_PLAN, TB3_STOPROBOT.

    cleanup = onCleanup(@() tb3_stopRobot(velPub, velMsg));  % Ctrl+C 때도 정지

    r = rateControl(10);                % 10 Hz
    while true
        od  = odomSub.LatestMessage;
        q   = od.pose.pose.orientation;
        eul = quat2eul([q.w q.x q.y q.z]);
        pose = [od.pose.pose.position.x, od.pose.pose.position.y, eul(1)];

        if norm(pose(1:2) - goalXY) < 0.15  % 목표 15 cm 안이면 도착
            break;
        end

        [v, w] = ctrl(pose);
        velMsg.linear.x = v; velMsg.angular.z = w;
        send(velPub, velMsg);
        waitfor(r);
    end

    disp("목표 도착!");
    % 정지 명령은 onCleanup 이 보낸다. 정상 도착이든 Ctrl+C 든 똑같이 거친다.
end
