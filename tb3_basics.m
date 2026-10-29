%% tb3_basics.m  -  MATLAB로 Gazebo TurtleBot3에 ROS 2 연결하기
% 전제 1: WSL에서 Gazebo가 떠 있다. 동봉한 스크립트로 띄운다.
%           cd /mnt/c/<받은-경로>/aypi-turtlebot-tutorial && bash start_gazebo_for_matlab.sh
% 전제 2: 이 MATLAB 세션이 ROS 2를 쓰기 전에 ros2_matlab_setup 을 실행했다.
%         이 폴더에서 MATLAB을 시작했다면 startup.m 이 이미 해 두었다.
% 섹션(%%) 단위로 Ctrl+Enter 로 하나씩 실행하세요.

%% 0. 설정
DOMAIN_ID = 30;                         % WSL의 ROS_DOMAIN_ID와 같은 번호
ros2_matlab_setup(DOMAIN_ID);

%% 1. 연결 확인  ->  /scan /odom /cmd_vel 이 실제로 오가는지 본다
% 주의: ros2 topic list 는 여기서 쓰지 않는다. MATLAB R2025b는 Jazzy, WSL은
% Humble이라 배포판이 달라서 목록 조회는 비어 보이는 것이 정상이다.
% 목록이 아니라 메시지가 실제로 오는지로 확인해야 한다.
tb3_check_connection(DOMAIN_ID);

%% 2. 노드와 구독자/발행자 만들기
node = ros2node("/matlab_tb3", DOMAIN_ID);

% /scan 은 best effort 로 발행되므로 구독도 best effort 로 맞춘다
scanSub = ros2subscriber(node, "/scan", "sensor_msgs/LaserScan", ...
    "Reliability", "besteffort", "Durability", "volatile", "Depth", 5);
odomSub = ros2subscriber(node, "/odom", "nav_msgs/Odometry");
[velPub, velMsg] = ros2publisher(node, "/cmd_vel", "geometry_msgs/Twist");

%% 3. 라이다 한 장 받아서 그리기
scanMsg = receive(scanSub, 10);         % 최대 10초 기다림
figure; rosPlot(scanMsg); title("TurtleBot3 라이다 (/scan)");

%% 4. 현재 위치 읽기
odomMsg = receive(odomSub, 10);
p = odomMsg.pose.pose.position;
q = odomMsg.pose.pose.orientation;
eul = quat2eul([q.w q.x q.y q.z]);      % [yaw pitch roll]
fprintf("x = %.2f m, y = %.2f m, yaw = %.1f deg\n", p.x, p.y, rad2deg(eul(1)));

%% 5. 2초 동안 앞으로 가기 -> 정지
velMsg.linear.x  = 0.1;                 % m/s
velMsg.angular.z = 0.0;                 % rad/s
send(velPub, velMsg);
pause(2);
velMsg.linear.x = 0;
send(velPub, velMsg);

%% 6. 정리 (다른 스크립트로 넘어가기 전에)
clear scanSub odomSub velPub velMsg node
