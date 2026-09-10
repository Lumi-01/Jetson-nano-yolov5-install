# Detailed installation guide

## Supported baseline

- NVIDIA Jetson Nano
- JetPack 4.6.x / Ubuntu 18.04
- Python 3.6
- PyTorch 1.10.0
- Torchvision 0.11.1
- YOLOv5 commit `9bcc32a`

These versions are intentionally pinned because current releases no longer support Python 3.6 or the Jetson Nano software stack.

## OpenCV

Set up at least 8 GB of swap, then run:

```bash
wget https://raw.githubusercontent.com/Lumi-01/Jetson-nano-yolov5-install/main/OpenCV-4.11.0.sh
chmod +x OpenCV-4.11.0.sh
./OpenCV-4.11.0.sh
```

The installer defaults to two build jobs on the original Jetson Nano to reduce out-of-memory failures. After configuring sufficient swap, you may override it:

```bash
OPENCV_BUILD_JOBS=4 ./OpenCV-4.11.0.sh
```

The OpenCV installer proceeds automatically when it would previously have asked for `Y/n`: it switches to an installed GCC 8 when required and replaces existing `~/opencv`, `~/opencv_contrib`, `~/opencv.zip`, and `~/opencv_contrib.zip` paths. Back up custom source changes first. A `sudo` password prompt, if shown, still requires user input.

## YOLOv5

Run the automated installer:

```bash
wget https://raw.githubusercontent.com/Lumi-01/Jetson-nano-yolov5-install/main/jetson_nano_yolov5_lnstall.sh
chmod +x jetson_nano_yolov5_lnstall.sh
./jetson_nano_yolov5_lnstall.sh
```

The installer stops instead of deleting an existing `~/yolov5` or `~/yolov5-py36` directory. Rename or remove an old installation yourself after reviewing its contents.

## Activate later

```bash
source ~/yolov5-py36/bin/activate
cd ~/yolov5
```
