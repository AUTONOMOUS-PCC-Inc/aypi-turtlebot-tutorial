% startup.m
%   이 폴더를 현재 폴더로 두고 MATLAB을 시작하면 자동으로 실행된다.
%   WSL의 ROS 2와 토픽 통신을 하기 위한 환경변수를 ROS 2가 켜지기 전에 미리 잡아 준다.
%   이 타이밍이 중요하다. ros2node 등을 한 번이라도 만든 뒤에는 바꿔도 소용이 없다.

ros2_matlab_setup(30);
