%% tb3_slam_plan.m  -  MATLAB에서 SLAM으로 지도 만들고 A*로 경로 계획 후 따라가기
% 필요: ROS Toolbox, Navigation Toolbox
% 순서: Gazebo를 새로 켠 직후(로봇이 출발점, /odom = 0,0)에 실행하는 것을 권장.
% 섹션(%%) 단위로 하나씩 실행하세요.
% 멈추기: Ctrl+C - 4번 섹션(주행) 중이라면 로봇도 자동으로 정지한다.

%% 0. 연결
DOMAIN_ID = 30;
ros2_matlab_setup(DOMAIN_ID);
node = ros2node("/matlab_slam", DOMAIN_ID);
scanSub = ros2subscriber(node, "/scan", "sensor_msgs/LaserScan", ...
    "Reliability", "besteffort", "Durability", "volatile", "Depth", 5);
odomSub = ros2subscriber(node, "/odom", "nav_msgs/Odometry");
[velPub, velMsg] = ros2publisher(node, "/cmd_vel", "geometry_msgs/Twist");
receive(scanSub, 10); receive(odomSub, 10);

%% 1. 스캔 모으기 (60초) - 이 동안 WSL에서 teleop_keyboard로 천천히 운전
% /scan 은 best effort 라 UDP 패킷이 더러 유실된다. 매번 가장 최근 스캔만 쓰므로
% 지도 품질에는 영향이 없다. 모으는 동안만 경고를 끄고 끝나면 되돌린다.
% (중간에 Ctrl+C 로 끊으면 꺼진 채 남는다. 그럴 땐 warning(scanWarn) 을 실행)
scanWarn = warning("off", "ros:mlros2:subscriber:QoSMessageLostDefaultWarning");

maxRange   = 3.5;                       % TurtleBot3 LDS 최대 거리 (m)
resolution = 20;                        % 지도 해상도 (칸/m)
slam = lidarSLAM(resolution, maxRange);
slam.LoopClosureThreshold    = 200;
slam.LoopClosureSearchRadius = 3;

r = rateControl(2);                     % 초당 2장
for k = 1:120
    scan = rosReadLidarScan(scanSub.LatestMessage);
    scan = removeInvalidData(scan, "RangeLimits", [0.12 maxRange]);
    addScan(slam, scan);
    if mod(k, 10) == 0
        fprintf("스캔 %d / 120\n", k);
    end
    waitfor(r);
end
warning(scanWarn);                      % 경고 설정 원래대로
figure; show(slam); title("lidarSLAM: 스캔과 궤적");

%% 2. 점유 격자 지도 만들기
[scans, poses] = scansAndPoses(slam);
map = buildMap(scans, poses, resolution, maxRange);
figure; show(map); title("MATLAB이 만든 지도");

%% 3. A* 경로 계획
planMap = copy(map);
inflate(planMap, 0.15);                 % 로봇 반지름만큼 벽을 두껍게

startXY = poses(end, 1:2);              % 지금 로봇 위치 (SLAM 기준)
goalXY  = [0.5 0.5];                    % 목표 (지도를 보고 빈 곳으로 바꾸기)

planner   = plannerAStarGrid(planMap);
pathGrid  = plan(planner, world2grid(planMap, startXY), world2grid(planMap, goalXY));
pathWorld = grid2world(planMap, pathGrid);

figure; show(planMap); hold on;
plot(pathWorld(:,1), pathWorld(:,2), "r-", "LineWidth", 2);
plot(goalXY(1), goalXY(2), "go", "MarkerSize", 10, "LineWidth", 2);
title("A* 경로");

%% 4. Pure Pursuit로 경로 따라가기 (/odom 사용)
waypoints = pathWorld(1:5:end, :);      % 점을 듬성듬성 줄이기
waypoints(end+1, :) = goalXY;
ctrl = controllerPurePursuit( ...
    "Waypoints", waypoints, ...
    "DesiredLinearVelocity", 0.12, ...
    "MaxAngularVelocity", 1.0, ...
    "LookaheadDistance", 0.3);

% 주행 루프는 tb3_followPath 안에서 돈다. 스크립트 본문에 두면 Ctrl+C 로 끊었을 때
% 정지 명령이 나가지 못해 로봇이 계속 간다. 자세한 이유는 tb3_followPath.m 주석 참고.
% 멈추기: Ctrl+C (로봇도 자동으로 정지)
tb3_followPath(odomSub, velPub, velMsg, ctrl, goalXY);
