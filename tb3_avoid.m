function tb3_avoid()
%TB3_AVOID  라이다로 장애물을 피하며 돌아다니기 (MATLAB)
%   전제: tb3_check_connection 이 통과하는 상태.
%   실행: 명령 창에 tb3_avoid   /  멈추기: Ctrl+C (로봇도 자동으로 정지)
%
%   종료 조건은 따로 없다. Ctrl+C 로 끊을 때까지 계속 돈다. "한 바퀴"를 셀 수
%   없는 이유는 /odom 을 쓰지 않고 /scan 만 보기 때문이다. 지금 어디인지,
%   출발점이 어디였는지를 알지 못한다.
%
%   See also AVOIDCONTROLLER, TB3_STOPROBOT, TB3_CHECK_CONNECTION.

    DOMAIN_ID = 30;
    ros2_matlab_setup(DOMAIN_ID);

    [scanSub, velPub, velMsg] = iConnection(DOMAIN_ID);
    cleanup = onCleanup(@() tb3_stopRobot(velPub, velMsg));  % Ctrl+C 때도 정지

    % /scan 은 best effort 라 UDP 패킷이 더러 유실된다. 매번 가장 최근 스캔만
    % 쓰므로 회피 동작에는 지장이 없다. 경고만 끄고 끝날 때 원래대로 되돌린다.
    warnState = warning("off", "ros:mlros2:subscriber:QoSMessageLostDefaultWarning");
    restoreWarn = onCleanup(@() warning(warnState));

    receive(scanSub, 10);               % 첫 메시지 기다리기
    r = rateControl(10);                % 10 Hz
    while true
        scan = scanSub.LatestMessage;
        [v, w] = avoidController(double(scan.ranges));
        velMsg.linear.x  = v;
        velMsg.angular.z = w;
        send(velPub, velMsg);
        waitfor(r);
    end
end


function [scanSub, velPub, velMsg] = iConnection(domainId)
%ICONNECTION  노드와 통신 객체를 persistent 로 들고 있는다.
%
%   왜 persistent 인가. Ctrl+C 로 함수가 끝나면 MATLAB은 함수 워크스페이스의
%   변수들을 지우는데, 그 순서가 정해져 있지 않다. 노드가 퍼블리셔보다 먼저
%   지워지면 onCleanup 이 정지 명령을 보내려는 순간 퍼블리셔는 이미 무효다.
%       오류: 유효하지 않거나 삭제된 객체입니다 (ros2publisher/send)
%   이러면 정지 명령이 나가지 못해 로봇이 마지막 속도 그대로 계속 간다.
%
%   persistent 는 함수가 끝나도 살아남으므로 정지 명령이 정상적으로 나간다.
%   덤으로 두 번째 실행부터는 DDS 탐색을 다시 하지 않아 바로 시작된다.

    persistent pNode pScan pVel pMsg pDomain

    needNew = isempty(pNode) || ~isequal(pDomain, domainId);
    if ~needNew
        try
            needNew = ~isvalid(pNode) || ~isvalid(pVel) || ~isvalid(pScan);
        catch
            needNew = true;             % 상태를 못 읽으면 새로 만든다
        end
    end

    if needNew
        pNode = ros2node("/matlab_avoid", domainId);
        pScan = ros2subscriber(pNode, "/scan", "sensor_msgs/LaserScan", ...
            "Reliability", "besteffort", "Durability", "volatile", "Depth", 5);
        [pVel, pMsg] = ros2publisher(pNode, "/cmd_vel", "geometry_msgs/Twist");
        pDomain = domainId;
    end

    scanSub = pScan;
    velPub  = pVel;
    velMsg  = pMsg;
end
