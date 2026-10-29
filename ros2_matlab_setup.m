function profilePath = ros2_matlab_setup(domainId)
%ROS2_MATLAB_SETUP  MATLAB이 WSL의 ROS 2와 토픽으로 통신하도록 설정한다.
%
%   ros2_matlab_setup()      도메인 30 (기본)
%   ros2_matlab_setup(31)    다른 도메인
%
%   *** ros2node / ros2subscriber / ros2publisher 를 만들기 전에 호출해야 한다. ***
%   이미 ROS 2를 한 번이라도 쓴 MATLAB 세션에서는 효과가 없다. 그럴 땐 MATLAB을
%   완전히 종료했다가 다시 켜고 이 함수를 먼저 부를 것. (이 폴더에서 MATLAB을
%   시작하면 startup.m 이 알아서 불러 준다.)
%
%   하는 일은 환경변수 두 개를 세팅하는 것뿐이다.
%     ROS_DOMAIN_ID                   WSL과 같은 도메인 번호
%     FASTRTPS_DEFAULT_PROFILES_FILE  fastdds_matlab_wsl.xml 의 경로
%
%   WSL 쪽에서도 같은 환경변수를 줘야 짝이 맞는다. start_gazebo_for_matlab.sh 참고.
%
%   참고: Humble(WSL)과 Jazzy(MATLAB R2025b)는 ROS 2 배포판이 서로 다르다.
%   토픽 송수신은 확인된 대로 잘 되지만, 노드/토픽 "목록" 조회(ros2 topic list,
%   ros2 node list)는 배포판 간 메타데이터 형식이 달라 비어 보이거나 일부만 나온다.
%   목록이 비었다고 통신이 안 되는 것이 아니다. 연결 확인은 tb3_check_connection 으로.
%
%   See also MAKE_FASTDDS_PROFILE, TB3_CHECK_CONNECTION.

    if nargin < 1 || isempty(domainId)
        domainId = 30;
    end

    here = fileparts(mfilename('fullpath'));
    profilePath = fullfile(here, 'fastdds_matlab_wsl.xml');

    if ~isfile(profilePath) || ~iLooksLikeDomain(profilePath, domainId)
        profilePath = make_fastdds_profile(domainId, here);
    end

    % 이미 올바른 값이 들어 있었다면, ROS 2가 켜져 있어도 문제될 것이 없다.
    % 그 서버는 어차피 이 설정을 물고 시작했기 때문이다. 경고는 "설정이 바뀌는데
    % 반영될 수 없는" 경우에만 띄운다.
    alreadyCorrect = strcmp(getenv('ROS_DOMAIN_ID'), num2str(domainId)) && ...
                     strcmpi(getenv('FASTRTPS_DEFAULT_PROFILES_FILE'), profilePath);

    setenv('ROS_DOMAIN_ID', num2str(domainId));
    setenv('FASTRTPS_DEFAULT_PROFILES_FILE', profilePath);

    if ~alreadyCorrect && iRos2ServerAlreadyRunning()
        warning('ros2_matlab_setup:serverRunning', ...
            ['이 MATLAB 세션은 이미 ROS 2를 시작한 상태입니다(libmwros2server 실행 중).\n' ...
             '         환경변수 변경이 반영되지 않습니다. MATLAB을 완전히 종료한 뒤\n' ...
             '         다시 켜고 ros2_matlab_setup 을 먼저 실행하세요.']);
    else
        fprintf('ROS 2 설정 완료  |  도메인 %d  |  프로파일 %s\n', domainId, profilePath);
    end
end


function tf = iLooksLikeDomain(profilePath, domainId)
% 생성된 XML 주석에 박아 둔 "ROS_DOMAIN_ID: n" 표시를 읽어 도메인이 맞는지 본다.
    tf = false;
    try
        txt = fileread(profilePath);
    catch
        return;
    end
    tok = regexp(txt, 'ROS_DOMAIN_ID:\s*(\d+)', 'tokens', 'once');
    tf = ~isempty(tok) && str2double(tok{1}) == domainId;
end


function tf = iRos2ServerAlreadyRunning()
% MATLAB의 ROS 2 백엔드(libmwros2server)가 이미 떠 있으면 환경변수는 이미 고정된 뒤다.
% 이 MATLAB이 띄운 것만 센다. 다른 MATLAB 창이 띄운 서버까지 세면 멀쩡한 새 세션에서
% 엉뚱한 경고가 뜬다. libmwros2server는 자기를 띄운 MATLAB의 자식 프로세스다.
    tf = false;
    if ~ispc
        return;
    end
    try
        cmd = sprintf(['powershell -NoProfile -NonInteractive -Command ' ...
            '"@(Get-CimInstance Win32_Process -Filter ''ParentProcessId=%d'' | ' ...
            'Where-Object { $_.Name -eq ''libmwros2server.exe'' }).Count"'], feature('getpid'));
        [st, out] = system(cmd);
        tf = (st == 0) && (str2double(strtrim(out)) > 0);
    catch
        % 조회에 실패하면 경고를 띄우지 않는다. 판단 근거가 없으므로.
    end
end
