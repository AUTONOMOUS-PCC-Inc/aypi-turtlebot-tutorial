<div align="center">

<img src="https://raw.githubusercontent.com/AUTONOMOUS-PCC-Inc/aypi-turtlebot-tutorial/main/images/turtlebot-banner.svg" alt="바이브코딩 캠프 2회차 — Windows의 MATLAB에서 WSL 안의 ROS 2 TurtleBot3를 제어한다. 라이다가 들어오고 속도 명령이 나간다" width="100%">

### 라이다로 앞을 보고, 스스로 피해 다니는 로봇을 만든다.

AUTONOMOUS PCC 바이브코딩 캠프 **2회차(MATLAB · TurtleBot3)** 실습 저장소입니다.<br>
Windows의 MATLAB에서 WSL 안의 ROS 2 TurtleBot3(Gazebo)를 제어합니다. **스크립트로 한 번, Simulink로 한 번.**

![Day](https://img.shields.io/badge/과정-2회차%20하루-0B1B33?style=for-the-badge)
![OS](https://img.shields.io/badge/환경-Windows%20+%20WSL2-1E6FD9?style=for-the-badge)
![MATLAB](https://img.shields.io/badge/MATLAB-R2025b-1E6FD9?style=for-the-badge)
![ROS](https://img.shields.io/badge/ROS%202-Humble-16A34A?style=for-the-badge)
![Lab](https://img.shields.io/badge/실습-4개-EAB308?style=for-the-badge)

[**시작하기**](#시작하기) · [**실습 순서**](#실습-순서) · [**파일 지도**](#파일-지도) · [**자주 막히는 곳**](#자주-막히는-곳) · [**새 PC에 세팅**](#새-pc에-처음-세팅한다면) · [**만든 사람들**](#만든-사람들)

</div>

---

## 시작하기

> [!IMPORTANT]
> **설치는 수업 전에 미리 끝내 두어야 합니다.** WSL2 · ROS 2 Humble · TurtleBot3 패키지는
> 내려받을 것이 많습니다. 새 PC라면 [아래](#새-pc에-처음-세팅한다면)의 설치 슬라이드를 먼저 보세요.
> 이 README는 "지금 뭘 해야 하지" 싶을 때 보는 지도입니다.

받는 것부터 하면 이렇습니다. **경로는 짧게** — `문서\GitHub` 처럼 얕은 곳에 두세요.

```bat
git clone https://github.com/AUTONOMOUS-PCC-Inc/aypi-turtlebot-tutorial.git
cd aypi-turtlebot-tutorial
```

모든 코드는 **저장소 맨 위 폴더**에 있습니다. 하위 폴더로 들어갈 일이 없습니다.

### 1 — WSL 터미널에서 Gazebo를 띄운다

```bash
cd /mnt/c/<받은-경로>/aypi-turtlebot-tutorial
bash start_gazebo_for_matlab.sh
```

`<받은-경로>` 는 방금 clone한 자리입니다. `문서\GitHub` 에 받았다면
`/mnt/c/Users/<사용자이름>/Documents/GitHub/aypi-turtlebot-tutorial` 입니다.

`Successfully spawned entity [burger]` 가 보이고 Gazebo 창에 로봇이 나타나면 성공입니다.

> [!WARNING]
> **이 터미널은 닫지 마세요.** 닫으면 시뮬레이터가 함께 꺼집니다.

### 2 — MATLAB을 저장소 폴더에서 시작한다

**`aypi-turtlebot-tutorial` 폴더를 현재 폴더로 두고 MATLAB을 시작하세요.**
그 폴더의 `startup.m` 이 자동으로 통신 설정을 잡아 줍니다.

```matlab
tb3_check_connection
```

세 줄이 모두 `[OK]` 로 나오면 준비 완료입니다.

```
  [OK]   WSL -> MATLAB  /scan      거리값 360개, frame=base_scan
  [OK]   WSL -> MATLAB  /odom      x=-2.00 m, y=-0.50 m
  [OK]   MATLAB -> WSL  /cmd_vel   발행 성공
```

---

## 딱 하나만 기억하세요

> [!IMPORTANT]
> **MATLAB을 켠 뒤 설정을 바꿨다면, `clear` 가 아니라 MATLAB을 완전히 껐다 켜야 합니다.**

MATLAB은 `ros2node` 를 처음 만들 때 ROS 2 백엔드를 띄우는데, **그 순간의 환경변수가 그대로 굳습니다.**
그래서 나중에 설정을 바꿔도 반영되지 않습니다. 토픽이 안 보이면 열에 아홉은 이것입니다.

---

## 실습 순서

| 순서 | 파일 | 하는 일 | 결과물 |
|:--:|---|---|---|
| 1 | `tb3_basics.m` | 연결 → 라이다 읽기 → 위치 읽기 → 전진 | 라이다 그림, 2초 전진 |
| 2 | `tb3_avoid.m` + `avoidController.m` | 라이다로 장애물 피하며 돌아다니기 | 끊을 때까지 도는 로봇 |
| 3 | `tb3_slam_plan.m` + `tb3_followPath.m` | SLAM 지도 작성 → A\* 경로 계획 → 경로 추종 | 내가 만든 지도 위의 경로 |
| 4 | `tb3_avoid_sl.slx` | 2번과 같은 제어기를 Simulink로 | Scope에 찍히는 v, w |

2번이 이 실습의 중심입니다. **제어 로직은 전부 `avoidController.m` 한 파일에 있고**, 4번 Simulink
모델도 그 파일을 그대로 부릅니다. 즉 **숫자 하나를 고치면 두 실습이 같이 바뀝니다.**

### 1. tb3_basics.m

섹션(`%%`) 단위로 `Ctrl+Enter` 를 눌러 하나씩 실행하세요. 한 번에 다 돌리지 않습니다.
라이다 그림이 뜨고, 로봇이 2초 전진하면 성공입니다.

### 2. tb3_avoid.m

명령 창에 `tb3_avoid` 라고 칩니다. **멈추기: `Ctrl+C`** — 로봇도 같이 섭니다.

종료 조건은 없습니다. 끊을 때까지 계속 돕니다. 한 바퀴를 셀 수 없는 이유는 `/odom` 을 쓰지 않고
`/scan` 만 보기 때문입니다. **지금 어디인지 모릅니다.**

제어 로직은 전부 `avoidController.m` 에 있습니다. 앞이 막혔으면 더 빈 쪽으로 돌고, 아니면 전진합니다.

> [!TIP]
> **숫자를 바꿔 보세요** — 0.5 m 판단 거리, 0.15 m/s 전진 속도, 0.8 rad/s 회전 속도.
> 로봇이 겁쟁이가 되거나 벽에 박습니다. 그게 이 실습의 재미입니다.

### 3. tb3_slam_plan.m

역시 섹션 단위로 실행합니다. 1번 섹션(스캔 60초 수집) 동안에는 **WSL에서 `teleop_keyboard` 로
직접 운전**해서 방 안을 돌아다녀야 지도가 만들어집니다.

```bash
ros2 run turtlebot3_teleop teleop_keyboard
```

4번 섹션(주행)은 `tb3_followPath.m` 이 맡습니다. 여기서도 `Ctrl+C` 로 끊으면 로봇이 섭니다.

### 4. tb3_avoid_sl.slx (Simulink)

2번과 **똑같은 제어기**(`avoidController.m`)를 MATLAB Function 블록에서 그대로 부릅니다.

```
[Subscribe /scan] → [Bus Selector: ranges] →┐
                                             ├→ [MATLAB Function] →┬→ [Publish /cmd_vel]
                    [Blank Message Twist] →──┘    avoidController   └→ [Scope: v, w]
```

Scope로 속도 명령을 실시간으로 볼 수 있는 것이 스크립트판과의 차이입니다.
10 Hz 고정 스텝에 시뮬레이션 페이싱을 켜 두어 실제 시간에 맞춰 돕니다.

> [!CAUTION]
> **이 모델은 컴파일과 버스 연결까지만 확인했고, 실제 로봇 주행 검증은 하지 못했습니다.**
> 수업에 쓰기 전에 한 번 돌려서 확인해 보세요. 문제가 있으면 `tb3_avoid_sl_build` 를 실행해
> 모델을 다시 만들 수 있습니다.

---

## 파일 지도

저장소 맨 위에 파일이 평평하게 놓여 있습니다. 역할은 두 묶음으로 나뉩니다.

### 실습 코드 — 수업에서 여는 파일

| 파일 | 역할 |
|---|---|
| `tb3_basics.m` | 실습 1 — 연결과 기본 송수신 |
| `tb3_avoid.m` | 실습 2 — 장애물 회피 실행 |
| `avoidController.m` | **회피 제어 로직** (스크립트와 Simulink가 공유) |
| `tb3_slam_plan.m` | 실습 3 — SLAM + 경로 계획 |
| `tb3_followPath.m` | 경로 추종 주행 루프 |
| `tb3_stopRobot.m` | 로봇 정지. 위 코드들이 공유 |
| `tb3_avoid_sl.slx` | 실습 4 — Simulink 모델 |
| `tb3_avoid_sl_build.m` | 위 모델을 다시 만드는 스크립트 |
| `tb3_sl_stopHook.m` | Simulink 정지 처리 (모델 콜백) |

### 통신 설정 — 건드리지 않아도 됩니다

| 파일 | 역할 |
|---|---|
| `startup.m` | 이 폴더에서 MATLAB을 켜면 자동 실행 |
| `ros2_matlab_setup.m` | 환경변수를 잡는다 |
| `make_fastdds_profile.m` | 통신 설정 XML 생성기 |
| `tb3_check_connection.m` | 연결 확인 |
| `start_gazebo_for_matlab.sh` | WSL에서 Gazebo 띄우기 |

> [!NOTE]
> `fastdds_matlab_wsl.xml` 은 처음 실행할 때 **자동으로 만들어집니다.** 없다고 당황하지 마세요.
> 파일 맨 위 주석에 왜 필요한지가 적혀 있습니다.

---

## 자주 막히는 곳

위에서부터 차례로 짚어 보세요.

| 증상 | 원인과 해결 |
|---|---|
| 토픽이 하나도 안 보인다 | MATLAB을 켠 뒤 설정이 바뀌었습니다. **MATLAB 완전 종료 후 재시작**. 열에 아홉은 이것입니다 |
| `ros2 topic list` 가 비어 있다 | **정상입니다.** 이유는 [아래](#왜-ros2-topic-list-가-비어-있나요)에 있습니다. `tb3_check_connection` 으로 확인하세요 |
| Gazebo에 로봇이 안 보인다 | 이전 Gazebo가 아직 떠 있습니다. 터미널을 닫고 스크립트로 다시 띄우세요 |
| 재시작해도 안 된다 | 네트워크(Wi-Fi)를 옮겼습니까. MATLAB 종료 → `wsl --shutdown` → Gazebo 재시작 |
| `Ctrl+C` 후에도 로봇이 간다 | WSL에서 아래 명령으로 직접 정지시키세요 |
| `Connection to process ... was lost` | 구독자를 중간에 `clear` 했습니다. [아래](#코드를-쓸-때-주의할-점-하나) 참고 |

```bash
ros2 topic pub --once /cmd_vel geometry_msgs/msg/Twist "{linear: {x: 0.0}, angular: {z: 0.0}}"
```

### 왜 `ros2 topic list` 가 비어 있나요

MATLAB에 내장된 ROS 2는 **Jazzy**이고 WSL은 **Humble**입니다. 배포판이 다르면 노드·토픽 **목록**을
주고받는 형식이 달라서 조회가 안 됩니다. 하지만 **메시지 송수신은 정상입니다.**

목록이 아니라 **실제 메시지가 오는지**로 판단하세요. 그래서 `tb3_check_connection` 이 있습니다.

### 코드를 쓸 때 주의할 점 하나

**구독자(subscriber)를 중간에 `clear` 하지 마세요.** 메시지가 붙어 있는 구독자를 지우거나,
함수 안에서 만들어 함수가 끝나며 사라지게 두면 MATLAB의 ROS 2 백엔드가 죽습니다.

```
Connection to process ... was lost
```

구독자는 작업이 끝날 때까지 변수로 살려 두고, 정리할 때 노드까지 한꺼번에 지우세요.

그래도 안 되면 **에러 메시지 전체를 복사해서** 강사에게 보여 주세요. 마지막 줄만 보면 원인을 못 찾는 경우가 많습니다.

---

## 새 PC에 처음 세팅한다면

`matlab-wsl-ros2-setup-guide.pptx` 를 보세요. WSL2 설치부터 연결 확인까지 16장으로 정리되어 있습니다.

| 필요한 것 | 버전 |
|---|---|
| Windows | 11 22H2 이상 |
| WSL2 | Ubuntu 22.04 |
| WSL 안 | ROS 2 Humble + TurtleBot3 패키지 |
| MATLAB | R2025b + ROS Toolbox |
| 실습 3에 추가 | Navigation Toolbox |
| 실습 4에 추가 | Simulink |

---

## 만든 사람들

| 작성 |
| :-----: |
| Aaron Yoon |

<!--
작성: Aaron Yoon
-->

모든 코드는 실제 시뮬레이터로 동작을 확인했습니다. 확인하지 못한 부분은
[실습 4](#4-tb3_avoid_slslx-simulink)에 따로 적어 두었습니다.

1회차 실습 저장소는 [`aypi-car-tutorial`](https://github.com/AUTONOMOUS-PCC-Inc/aypi-car-tutorial),
3회차는 [`aypi-metaverse-tutorial`](https://github.com/AUTONOMOUS-PCC-Inc/aypi-metaverse-tutorial),
4회차는 [`aypi-agent-tutorial`](https://github.com/AUTONOMOUS-PCC-Inc/aypi-agent-tutorial) 입니다.

## 라이선스

MIT &copy; AUTONOMOUS PCC, Inc.

전문은 [`LICENSE`](LICENSE)에 있습니다.

---

<div align="center">
<sub><strong>AUTONOMOUS PCC, Inc.</strong> · (주)오토노머스피씨씨 — 바이브코딩 캠프 2회차 실습</sub><br>
<sub><a href="https://github.com/AUTONOMOUS-PCC-Inc">github.com/AUTONOMOUS-PCC-Inc</a></sub>
</div>
