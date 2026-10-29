function ok = tb3_check_connection(domainId)
%TB3_CHECK_CONNECTION  MATLAB <-> WSL ROS 2 토픽 통신이 되는지 끝까지 확인한다.
%
%   tb3_check_connection          도메인 30
%   ok = tb3_check_connection(31) 결과를 true/false 로 받기
%
%   확인 순서
%     1) WSL -> MATLAB : /scan 을 실제로 한 장 받는가
%     2) WSL -> MATLAB : /odom 을 실제로 한 장 받는가
%     3) MATLAB -> WSL : /cmd_vel 을 보낼 수 있는가 (0 속도라 로봇은 안 움직인다)
%
%   먼저 WSL에서 Gazebo가 떠 있어야 한다.
%     export ROS_DOMAIN_ID=30
%     ros2 launch turtlebot3_gazebo turtlebot3_world.launch.py
%
%   토픽 "목록"은 일부러 확인하지 않는다. MATLAB R2025b는 Jazzy, WSL은 Humble이라
%   배포판이 달라서 ros2 topic list / ros2 node list 는 비어 보이거나 일부만 나오는
%   것이 정상이다. 목록이 아니라 실제 메시지가 오가는지로 판단해야 한다.
%
%   See also ROS2_MATLAB_SETUP, TB3_BASICS.

    if nargin < 1 || isempty(domainId)
        domainId = 30;
    end

    ros2_matlab_setup(domainId);

    fprintf('\n--- 연결 확인 (도메인 %d) ---\n', domainId);

    node = ros2node('/matlab_check', domainId);

    % 구독자를 먼저 다 만들어 두고 끝까지 살려 둔다.
    % 구독이 붙어 있는 상태에서 구독자를 중간에 없애면 MATLAB의 ROS 2 백엔드
    % (libmwros2server)가 죽는 경우가 있다. 배포판이 다른 탓으로 보인다.
    % 그래서 함수 안에서 만들고 버리는 식으로 쓰지 않는다.
    scanSub = ros2subscriber(node, '/scan', 'sensor_msgs/LaserScan', ...
        'Reliability', 'besteffort', 'Durability', 'volatile', 'Depth', 5);
    odomSub = ros2subscriber(node, '/odom', 'nav_msgs/Odometry', ...
        'Reliability', 'reliable', 'Durability', 'volatile', 'Depth', 5);

    results = false(1, 3);

    results(1) = iReport('/scan', scanSub, 15, ...
        @(m) sprintf('거리값 %d개, frame=%s', numel(m.ranges), m.header.frame_id));

    results(2) = iReport('/odom', odomSub, 15, ...
        @(m) sprintf('x=%.2f m, y=%.2f m', m.pose.pose.position.x, m.pose.pose.position.y));

    try
        [velPub, velMsg] = ros2publisher(node, '/cmd_vel', 'geometry_msgs/Twist');
        velMsg.linear.x = 0; velMsg.angular.z = 0;
        send(velPub, velMsg);
        fprintf('  [OK]   MATLAB -> WSL  %-10s 발행 성공 (0 속도, 로봇은 가만히 있음)\n', '/cmd_vel');
        results(3) = true;
    catch err
        fprintf('  [실패] MATLAB -> WSL  %-10s %s\n', '/cmd_vel', err.message);
    end

    ok = all(results);
    fprintf('---\n');
    if ok
        fprintf('통신 정상입니다. tb3_basics 로 넘어가세요.\n\n');
    else
        fprintf(['통신이 안 됩니다. 아래를 순서대로 확인하세요.\n' ...
                 '  1. WSL에서 Gazebo가 떠 있고 ROS_DOMAIN_ID가 %d 인가\n' ...
                 '  2. 이 MATLAB이 ROS 2를 쓰기 "전에" ros2_matlab_setup 을 실행했는가\n' ...
                 '     아니라면 MATLAB을 완전히 껐다 켜고 다시 시도하세요\n' ...
                 '  3. %s 에 hostAddressLoopback=true 가 있는가\n' ...
                 '  자세한 내용은 README.md 참고.\n\n'], ...
                 domainId, fullfile(getenv('USERPROFILE'), '.wslconfig'));
    end

    if nargout == 0
        clear ok;
    end
end


function ok = iReport(topic, sub, timeoutSec, describe)
    ok = false;
    try
        msg = receive(sub, timeoutSec);
        fprintf('  [OK]   WSL -> MATLAB  %-10s %s\n', topic, describe(msg));
        ok = true;
    catch err
        fprintf('  [실패] WSL -> MATLAB  %-10s %s\n', topic, err.message);
    end
end
