function [v, w] = avoidController(ranges)
%AVOIDCONTROLLER  라이다 거리값으로 전진/회전 속도를 정한다.
%   TurtleBot3 LDS: 360개 값, 0번 = 정면, 반시계 방향으로 1도씩.
%   MATLAB 스크립트(tb3_avoid.m)와 Simulink의 MATLAB Function 블록에서
%   똑같이 쓸 수 있도록 단순한 문법만 사용했다.

    r = ranges(:);
    n = numel(r);
    if n < 360
        v = 0; w = 0;                   % 배열 크기 설정이 360보다 작으면 정지
        return;
    end
    r = r(1:360);
    r(r < 0.12 | isinf(r) | isnan(r)) = 3.5;   % 측정 안 된 값은 최대 거리로

    front = min([r(1:30); r(331:360)]); % 정면 ±30도
    left  = min(r(31:90));              % 왼쪽 30~90도
    right = min(r(271:330));            % 오른쪽 30~90도

    if front < 0.5                      % 앞 0.5 m 안에 장애물
        v = 0.0;
        if left > right
            w = 0.8;                    % 왼쪽이 더 비었으면 왼쪽으로
        else
            w = -0.8;
        end
    else
        v = 0.15;
        w = 0.0;
    end
end
