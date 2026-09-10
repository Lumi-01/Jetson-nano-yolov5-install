# Jetson Nano YOLOv5 Setup

Install a Jetson Nano-compatible YOLOv5 environment with Python 3.6, PyTorch 1.10.0, Torchvision 0.11.1, and CUDA-enabled OpenCV.

> This project targets the original Jetson Nano running JetPack 4.6.x (Ubuntu 18.04). It is not a general-purpose installer for newer Jetson platforms.

[한국어 가이드](docs/README.ko.md)

## Before you start

- Back up important files.
- Make sure at least 8 GB of swap is available before building OpenCV.
- Use a stable power supply and allow several hours for the OpenCV build.
- Do not run the scripts as `root`; they request `sudo` only when required.
- The OpenCV installer automatically answers its continuation prompts with Yes. Existing `~/opencv`, `~/opencv_contrib`, and their ZIP downloads are replaced without another prompt.
- After the safety checks, each installer asks for the `sudo` password once with `sudo -v` and keeps that authorization alive during the long-running build. Passwords are never stored.

## Quick start

### Recommended: complete setup

The unified installer performs the OpenCV, OpenBLAS, and YOLOv5 steps in order, requests the `sudo` password once, records a log, and skips successfully completed stages when rerun.

```bash
wget https://raw.githubusercontent.com/Lumi-01/Jetson-nano-yolov5-install/main/install-all.sh
chmod +x install-all.sh
./install-all.sh
```

If less than 8GB of swap is configured, the preflight check stops to avoid an unstable OpenCV build. After accepting that risk, use `./install-all.sh --allow-low-swap`.

### Individual installation

#### 1. Install OpenCV 4.11.0

```bash
wget https://raw.githubusercontent.com/Lumi-01/Jetson-nano-yolov5-install/main/OpenCV-4.11.0.sh
chmod +x OpenCV-4.11.0.sh
./OpenCV-4.11.0.sh
```

#### 2. Prevent the OpenBLAS core-dump issue

```bash
echo 'export OPENBLAS_CORETYPE=ARMV8' >> ~/.bashrc
source ~/.bashrc
```

#### 3. Install YOLOv5

```bash
wget https://raw.githubusercontent.com/Lumi-01/Jetson-nano-yolov5-install/main/jetson_nano_yolov5_lnstall.sh
chmod +x jetson_nano_yolov5_lnstall.sh
./jetson_nano_yolov5_lnstall.sh
```

The Torchvision build can take more than 30 minutes.

## Verify the installation

```bash
source ~/yolov5-py36/bin/activate
cd ~/yolov5

# Image test
python detect.py --weights yolov5s.pt --source data/images/bus.jpg

# USB camera test
python detect.py --weights yolov5s.pt --source 0

deactivate
```

Detection output is written under `~/yolov5/runs/`.

## Documentation

- [Detailed installation guide](docs/installation.md)
- [한국어 가이드](docs/README.ko.md)
- [Troubleshooting](docs/troubleshooting.md)

## Automated tests

GitHub Actions checks every shell script with `bash -n` and safely exercises the hardware and existing-installation guards on an Ubuntu runner. It also verifies the pinned versions, temporary-directory cleanup, explicit OpenCV cleanup targets, and the original Nano's conservative build-job default. Use **Actions → Jetson script simulation → Run workflow** to run it manually.

## Included files

| File | Purpose |
| --- | --- |
| `install-all.sh` | Runs the complete OpenCV, OpenBLAS, and YOLOv5 setup |
| `OpenCV-4.11.0.sh` | Builds CUDA-enabled OpenCV 4.11.0 |
| `jetson_nano_yolov5_lnstall.sh` | Installs the Python 3.6 YOLOv5 environment |
| `yolov5 install guide` | Original manual notes retained for reference |
| Files prefixed with `-Not used-` | Archived experiments; not part of the supported path |

## Credits

The OpenCV installer is based on [Qengineering/Install-OpenCV-Jetson-Nano](https://github.com/Qengineering/Install-OpenCV-Jetson-Nano).
