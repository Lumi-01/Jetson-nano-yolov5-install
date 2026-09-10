# Jetson Nano YOLOv5 설치 가이드

이 저장소는 **오리지널 NVIDIA Jetson Nano**, **JetPack 4.6.x**, **Ubuntu 18.04**, **Python 3.6** 환경을 기준으로 합니다. 최신 Jetson이나 일반 Ubuntu PC용 설치 프로그램이 아닙니다.

## 실행 전 확인

- 중요한 파일과 직접 수정한 OpenCV 소스를 백업합니다.
- OpenCV 빌드 전에 스왑을 최소 8GB 준비합니다.
- 안정적인 전원 공급 장치를 사용하고 OpenCV 빌드에 몇 시간이 걸릴 수 있음을 고려합니다.
- 스크립트를 `root`로 직접 실행하지 않습니다. 필요한 작업에서만 `sudo`를 호출합니다.

각 설치 스크립트는 하드웨어와 기존 설치 경로를 먼저 확인한 뒤, 실제 작업 직전에 `sudo -v`로 비밀번호를 **한 번만** 요청합니다. 긴 빌드 중에는 백그라운드에서 인증 유효시간만 갱신하며 스크립트가 끝나면 갱신 프로세스도 종료합니다. 비밀번호를 파일이나 명령행에 저장하지 않습니다.

## 설치

### 권장: 전체 통합 설치

다음 스크립트 하나로 임시 스왑 구성, OpenCV, OpenBLAS 설정, YOLOv5 설치 및 import 검증을 순서대로 실행할 수 있습니다.

```bash
wget https://raw.githubusercontent.com/Lumi-01/Jetson-nano-yolov5-install/main/install-all.sh
chmod +x install-all.sh
./install-all.sh
```

진행 상태와 로그는 `~/.local/state/jetson-nano-yolov5-install/`에 저장됩니다. 성공한 단계는 재실행할 때 건너뜁니다. 완료된 단계까지 다시 빌드하려는 경우에만 `--force`를 사용합니다.

기존 총 스왑이 8GB 미만이면 부족한 용량만큼 `/var/tmp`에 고유한 임시 스왑파일을 추가합니다. 기존 스왑 장치나 파일은 수정하지 않으며, 정상 종료 또는 처리 가능한 오류 시 임시 스왑만 해제·삭제하여 원래 구성으로 복구합니다. 임시 스왑을 만든 뒤에도 저장공간을 최소 1GB 남기며, 공간 부족이나 생성 실패 시 안전하게 중단됩니다.

메모리 사용량 때문에 `swapoff`가 불가능하면 활성 스왑파일을 억지로 삭제하지 않고 로그에 수동 복구 명령을 표시합니다. 임시 스왑을 만들 수 없어도 위험을 감수하고 계속하려면 `./install-all.sh --allow-low-swap`을 사용합니다.

### 개별 OpenCV 설치

```bash
wget https://raw.githubusercontent.com/Lumi-01/Jetson-nano-yolov5-install/main/OpenCV-4.11.0.sh
chmod +x OpenCV-4.11.0.sh
./OpenCV-4.11.0.sh
```

스크립트는 기존의 `Y/n` 질문을 모두 **Yes로 자동 처리**합니다.

- CUDA 호환을 위해 GCC 8 전환이 필요하고 GCC 8이 설치되어 있으면 자동으로 전환합니다.
- 기존 `~/opencv`, `~/opencv_contrib`, `~/opencv.zip`, `~/opencv_contrib.zip`은 추가 확인 없이 교체됩니다.
- 최초 `sudo` 비밀번호 입력은 보안상 자동화하지 않으며 화면에 나타나면 한 번 직접 입력해야 합니다.
- OpenCV와 Torchvision은 기본적으로 빌드 작업 4개를 사용하여 Nano의 CPU 4코어를 모두 활용합니다.

스왑을 사용해도 메모리 압박이 심하면 작업 수를 각각 낮출 수 있습니다.

```bash
OPENCV_BUILD_JOBS=2 ./OpenCV-4.11.0.sh
TORCHVISION_BUILD_JOBS=2 ./jetson_nano_yolov5_lnstall.sh
```

## 2. OpenBLAS 코어 덤프 방지

```bash
echo 'export OPENBLAS_CORETYPE=ARMV8' >> ~/.bashrc
source ~/.bashrc
```

## 3. YOLOv5 설치

```bash
wget https://raw.githubusercontent.com/Lumi-01/Jetson-nano-yolov5-install/main/jetson_nano_yolov5_lnstall.sh
chmod +x jetson_nano_yolov5_lnstall.sh
./jetson_nano_yolov5_lnstall.sh
```

YOLOv5 스크립트는 기존 `~/yolov5` 또는 `~/yolov5-py36`을 자동 삭제하지 않습니다. 해당 경로가 이미 있으면 안전하게 중단되므로 내용을 확인한 뒤 직접 이름을 바꾸거나 제거합니다.

## 4. 설치 확인

```bash
source ~/yolov5-py36/bin/activate
cd ~/yolov5

# 기본 이미지 테스트
python detect.py --weights yolov5s.pt --source data/images/bus.jpg

# USB 카메라 테스트
python detect.py --weights yolov5s.pt --source 0

deactivate
```

결과는 `~/yolov5/runs/` 아래에 저장됩니다.

## 자동 시뮬레이션 실행

GitHub 저장소의 **Actions → Jetson script simulation → Run workflow**에서 `main` 브랜치를 선택하면 됩니다. 이 검사는 실제 패키지를 설치하지 않고 Bash 문법, 하드웨어 차단, 기존 설치 보호, 버전 고정 및 삭제 경계를 확인합니다.

실제 CUDA 빌드와 카메라 동작은 Jetson Nano에서 별도로 확인해야 합니다.
