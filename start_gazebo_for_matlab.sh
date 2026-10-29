#!/usr/bin/env bash
# start_gazebo_for_matlab.sh
#   TurtleBot3 Gazebo를 MATLAB 연동에 맞는 환경으로 띄운다.
#
#   WSL(Ubuntu 22.04)에서:
#     cd /mnt/c/<받은-경로>/aypi-turtlebot-tutorial
#     bash start_gazebo_for_matlab.sh
#
#   하는 일은 두 가지뿐이다.
#     1) 이미 떠 있는 Gazebo를 먼저 내린다
#     2) ROS_DOMAIN_ID 와 TURTLEBOT3_MODEL 을 맞춰 띄운다
#
#   *** WSL 쪽에는 Fast DDS 프로파일(FASTRTPS_DEFAULT_PROFILES_FILE)을 걸지 않는다. ***
#   한 번 걸어 봤다가 호되게 당했다. 프로파일은 공유메모리를 끄고 탐색을
#   127.0.0.1 유니캐스트 고정 피어로 바꾸는데, 그러면 Gazebo 자신의 내부
#   서비스 호출까지 깨진다. 구체적으로 spawn_entity 가 /spawn_entity 서비스에
#   붙지 못해 월드는 뜨는데 로봇이 생성되지 않는다.
#       [ERROR] Service /spawn_entity unavailable. Was Gazebo started with GazeboRosFactory?
#   ros2 service list 에는 /spawn_entity 가 멀쩡히 보이는데도 그렇다.
#   프로파일은 MATLAB 쪽에만 건다. ros2_matlab_setup 이 알아서 한다.

set -e

# 이미 떠 있는 Gazebo를 내린다. 그대로 두면 새 gzserver가 Gazebo 마스터
# 포트(11345)를 잡지 못해 ROS 팩토리 플러그인이 열리지 않고, 역시 로봇이
# 생성되지 않는다. 증상이 위와 똑같아서 헷갈리기 쉽다.
if pgrep -x gzserver > /dev/null || pgrep -x gzclient > /dev/null; then
    echo "이미 실행 중인 Gazebo를 종료합니다..."
    pkill -f turtlebot3_world.launch.py || true
    sleep 2
    pkill -9 -x gzserver || true
    pkill -9 -x gzclient || true
    pkill -9 -f robot_state_publisher || true
    sleep 2
fi

export TURTLEBOT3_MODEL=burger
export ROS_DOMAIN_ID=30
export ROS_LOCALHOST_ONLY=0

source /opt/ros/humble/setup.bash
export GAZEBO_MODEL_PATH="$GAZEBO_MODEL_PATH:/opt/ros/humble/share/turtlebot3_gazebo/models"

echo "ROS_DOMAIN_ID    = $ROS_DOMAIN_ID"
echo "TURTLEBOT3_MODEL = $TURTLEBOT3_MODEL"
echo "Fast DDS 프로파일 = (걸지 않음 - MATLAB 쪽에서만 쓴다)"
echo

exec ros2 launch turtlebot3_gazebo turtlebot3_world.launch.py
