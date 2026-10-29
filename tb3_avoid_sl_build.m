function mdlPath = tb3_avoid_sl_build()
%TB3_AVOID_SL_BUILD  장애물 회피 Simulink 모델(tb3_avoid_sl.slx)을 만든다.
%
%   한 번 실행하면 .slx 가 만들어진다. 그 뒤로는 모델을 열어서 쓰면 된다.
%   모델을 망가뜨렸을 때 되살릴 수 있도록 생성 과정을 코드로 남겨 둔다.
%
%   모델 구조
%
%     [Subscribe /scan] --+--> [Bus Selector: ranges] --+
%                                                        |
%                                   [Blank Message Twist]+--> [MATLAB Function]
%                                                                 |    |   |
%                                                               msg    v   w
%                                                                 |    +---+--> [Scope]
%                                                                 v
%                                                        [Publish /cmd_vel]
%
%   Twist 메시지 조립을 Bus Assignment 대신 MATLAB Function 안에서 한다.
%   Bus Assignment 는 'linear.x' 같은 경로 문자열을 쓰는데, 입력 버스가
%   전파되기 전에는 Simulink 가 경로를 'x' 로 잘못 재매핑해 컴파일이 깨진다.
%   함수 안에서 필드를 직접 대입하면 그런 순서 의존이 없다.
%
%   See also TB3_AVOID, AVOIDCONTROLLER, TB3_SL_STOPHOOK.

    DOMAIN_ID = 30;
    mdl = 'tb3_avoid_sl';
    here = fileparts(mfilename('fullpath'));
    mdlPath = fullfile(here, [mdl '.slx']);

    ros2_matlab_setup(DOMAIN_ID);

    if bdIsLoaded(mdl), close_system(mdl, 0); end
    if isfile(mdlPath), delete(mdlPath); end

    new_system(mdl);
    load_system(mdl);

    % ── 블록 ────────────────────────────────────────────────
    add_block('ros2lib/Subscribe', [mdl '/Scan'], 'Position', [50 86 170 154]);
    set_param([mdl '/Scan'], ...
        'topicSource', 'Specify your own', ...
        'topic', '/scan', ...
        'messageType', 'sensor_msgs/LaserScan', ...
        'sampleTime', '0.1', ...
        'QOSHistory', 'Keep last', 'QOSDepth', '5', ...
        'QOSReliability', 'Best effort', ...   % Gazebo 가 best effort 로 쏜다
        'QOSDurability', 'Volatile');

    add_block('simulink/Signal Routing/Bus Selector', [mdl '/Ranges'], ...
        'Position', [225 105 230 145]);

    add_block('ros2lib/Blank Message', [mdl '/Blank Twist'], ...
        'Position', [50 212 170 248]);
    % entityType 이 실제로 출력 버스를 정하는 파라미터다. 기본값이
    % geometry_msgs/Point 라서, messageType 만 바꾸면 블록은 그대로 Point(x,y,z)를
    % 내보내고 "버스 구조가 다르다"는 오류가 난다. 둘 다 지정한다.
    set_param([mdl '/Blank Twist'], ...
        'entityType',  'geometry_msgs/Twist', ...
        'messageType', 'geometry_msgs/Twist');

    add_block('simulink/User-Defined Functions/MATLAB Function', [mdl '/Avoid'], ...
        'Position', [300 110 430 230]);

    add_block('ros2lib/Publish', [mdl '/Cmd Vel'], 'Position', [530 122 650 158]);
    set_param([mdl '/Cmd Vel'], ...
        'topicSource', 'Specify your own', ...
        'topic', '/cmd_vel', ...
        'messageType', 'geometry_msgs/Twist', ...
        'QOSHistory', 'Keep last', 'QOSDepth', '10', ...
        'QOSReliability', 'Reliable', 'QOSDurability', 'Volatile');

    add_block('simulink/Signal Routing/Mux', [mdl '/Mux'], ...
        'Position', [500 236 505 284], 'Inputs', '2');
    add_block('simulink/Sinks/Scope', [mdl '/v and w'], ...
        'Position', [560 242 600 278]);

    % ── 라이다 360개가 들어오도록 가변 배열 최대 길이 지정 ──
    % 기본값은 360보다 작다. 그대로 두면 avoidController 가 곧바로 정지를 반환한다.
    util  = ros.slros2.internal.bus.Util;
    store = ros.slros.internal.bus.VarlenArraySizeStore(mdl, 'BusUtilityObject', util);
    info  = ros.slros.internal.bus.VarLenArrayInfo('sensor_msgs/LaserScan', mdl, ...
        'BusUtilityObject', util);
    info.setMaxLength(info.PropertyNames, repmat(360, 1, numel(info.PropertyNames)));
    store.setUserSpecifiedArrayInfo('sensor_msgs/LaserScan', info);
    store.updateModel();

    types = ros.slros2.internal.bus.Util.getBlockLevelMessageTypesInModel(mdl);
    for i = 1:numel(types)
        ros.slros2.internal.bus.Util.createBusIfNeeded(types{i}, mdl);
    end

    % ── 블록 설정 ───────────────────────────────────────────
    set_param([mdl '/Ranges'], 'OutputSignals', 'ranges');

    rt = sfroot;
    chart = rt.find('-isa', 'Stateflow.EMChart', 'Path', [mdl '/Avoid']);
    chart.Script = iAvoidScript();

    % 버스를 주고받는 포트는 타입을 명시해야 한다. 명시하지 않으면 Simulink 가
    % blank 를 스칼라 double 로 보고 "출력의 크기/유형을 확인할 수 없습니다" 로 멈춘다.
    twistBus = 'Bus: SL_Bus_geometry_msgs_Twist';
    data = chart.find('-isa', 'Stateflow.Data');
    for k = 1:numel(data)
        switch data(k).Name
            case {'blank', 'msg'}
                data(k).DataType = twistBus;
        end
    end

    % ── 연결 ────────────────────────────────────────────────
    add_line(mdl, 'Scan/2',        'Ranges/1',  'autorouting', 'on');
    add_line(mdl, 'Ranges/1',      'Avoid/1',   'autorouting', 'on');
    add_line(mdl, 'Blank Twist/1', 'Avoid/2',   'autorouting', 'on');
    add_line(mdl, 'Avoid/1',       'Cmd Vel/1', 'autorouting', 'on');
    add_line(mdl, 'Avoid/2',       'Mux/1',     'autorouting', 'on');
    add_line(mdl, 'Avoid/3',       'Mux/2',     'autorouting', 'on');
    add_line(mdl, 'Mux/1',         'v and w/1', 'autorouting', 'on');

    % ── 모델 설정 ───────────────────────────────────────────
    set_param(mdl, ...
        'SolverType', 'Fixed-step', ...
        'Solver', 'FixedStepDiscrete', ...
        'FixedStep', '0.1', ...          % 10 Hz, tb3_avoid 의 rateControl 과 같다
        'StopTime', 'inf', ...           % 멈추기: Stop 버튼
        'EnablePacing', 'on', ...        % 실제 시간에 맞춰 돈다
        'PacingRate', '1');

    % Stop 을 눌러도 로봇이 서도록 하는 콜백. 이유는 tb3_sl_stopHook 주석 참고.
    set_param(mdl, 'InitFcn', 'tb3_sl_stopHook(''init'');');
    set_param(mdl, 'StopFcn', 'tb3_sl_stopHook(''stop'');');

    set_param(mdl, 'SimulationCommand', 'update');   % 버스 전파 확인
    save_system(mdl, mdlPath);
    close_system(mdl, 0);

    fprintf('모델 생성 완료: %s\n', mdlPath);
    if nargout == 0
        clear mdlPath;
    end
end


function s = iAvoidScript()
% MATLAB Function 블록 안에 들어갈 코드.
% 제어 로직은 avoidController 를 그대로 부른다. 스크립트판 tb3_avoid 와
% 완전히 같은 제어기이고, 여기서는 메시지 조립만 추가로 한다.
    lines = {
    'function [msg, v, w] = Avoid(ranges, blank)'
    '%#codegen'
    '    % /scan 의 ranges 는 single 이고 avoidController 는 double 을 받는다.'
    '    % tb3_avoid.m 에서 double(scan.ranges) 로 넘기는 것과 같다.'
    '    [v, w] = avoidController(double(ranges));'
    ''
    '    msg = blank;              % 빈 Twist 를 받아 값만 채운다'
    '    msg.linear.x  = v;'
    '    msg.angular.z = w;'
    'end'
    };
    s = strjoin(lines, newline);
end
