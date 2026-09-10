# Troubleshooting

## `Illegal instruction (core dumped)` when importing OpenCV

Set the OpenBLAS CPU type for the Jetson Nano:

```bash
echo 'export OPENBLAS_CORETYPE=ARMV8' >> ~/.bashrc
source ~/.bashrc
python3 -c 'import cv2; print(cv2.__version__)'
```

Do not append `python3` to the `export` command. `export OPENBLAS_CORETYPE=ARMV8 python3` is invalid shell syntax.

## OpenCV build stops or the device freezes

- Confirm that swap is enabled with `free -h`.
- Retry with fewer jobs: `OPENCV_BUILD_JOBS=1 ./OpenCV-4.11.0.sh`.
- Check available storage with `df -h`.

## Existing installation detected

The YOLOv5 installer refuses to overwrite `~/yolov5` or `~/yolov5-py36`; inspect and rename those directories before retrying. The OpenCV installer is intentionally non-interactive and replaces its existing source directories and downloaded ZIP files automatically, so back up custom OpenCV changes before running it.

## `sudo` authentication fails

The scripts request administrator authentication once with `sudo -v` before installation and keep the timestamp active during the build. Confirm that the current account belongs to the `sudo` group. Do not put the password in the script and do not pipe it through `sudo -S`.

## Camera is not detected

List V4L2 devices:

```bash
v4l2-ctl --list-devices
```

Then pass the correct device path to YOLOv5, for example `--source /dev/video0`.
