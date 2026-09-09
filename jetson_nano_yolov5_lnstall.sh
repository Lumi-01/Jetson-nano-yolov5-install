#!/usr/bin/env bash
set -Eeuo pipefail

VENV_DIR="${HOME}/yolov5-py36"
YOLO_DIR="${HOME}/yolov5"
YOLO_COMMIT="9bcc32a"
TORCHVISION_VERSION="0.11.1"

die() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

[[ "$(uname -m)" == "aarch64" ]] || die "This installer requires an aarch64 Jetson system."
command -v python3.6 >/dev/null 2>&1 || die "Python 3.6 is required. Install the JetPack-provided Python first."
[[ ! -e "$VENV_DIR" ]] || die "$VENV_DIR already exists. Rename or remove it after reviewing its contents."
[[ ! -e "$YOLO_DIR" ]] || die "$YOLO_DIR already exists. Rename or remove it after reviewing its contents."

printf '%s\n' '[1/7] Installing system prerequisites...'
sudo apt-get update
sudo apt-get install -y git wget python3-virtualenv libjpeg-dev zlib1g-dev

printf '%s\n' '[2/7] Creating the Python 3.6 virtual environment...'
python3.6 -m virtualenv "$VENV_DIR" --python=python3.6 --system-site-packages
# shellcheck disable=SC1091
source "$VENV_DIR/bin/activate"

printf '%s\n' '[3/7] Installing Python 3.6-compatible build tools...'
python -m pip install --upgrade 'pip<22' 'setuptools<60' 'wheel<0.38'
python -m pip install 'Cython<3.0' 'numpy==1.19.2' 'Pillow==8.4.0'

WORK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/jetson-yolov5.XXXXXX")"
cleanup() {
  rm -rf -- "$WORK_DIR"
}
trap cleanup EXIT

printf '%s\n' '[4/7] Installing PyTorch 1.10.0...'
TORCH_WHEEL="$WORK_DIR/torch-1.10.0-cp36-cp36m-linux_aarch64.whl"
wget -O "$TORCH_WHEEL" 'https://nvidia.box.com/shared/static/fjtbno0vpo676a25cgvuqc1wty0fkkg6.whl'
python -m pip install "$TORCH_WHEEL"

printf '%s\n' '[5/7] Building Torchvision 0.11.1 (this can take over 30 minutes)...'
git clone --depth 1 --branch "v${TORCHVISION_VERSION}" --single-branch \
  https://github.com/pytorch/vision "$WORK_DIR/vision"
(
  cd "$WORK_DIR/vision"
  export BUILD_VERSION="$TORCHVISION_VERSION"
  python setup.py install
)

printf '%s\n' '[6/7] Checking out the Python 3.6-compatible YOLOv5 revision...'
git clone https://github.com/ultralytics/yolov5 "$YOLO_DIR"
(
  cd "$YOLO_DIR"
  git checkout --detach "$YOLO_COMMIT"
  sed -i -E \
    -e '/^[[:space:]]*numpy([<>=]|$)/s/^/# managed by Jetson installer: /' \
    -e '/^[[:space:]]*opencv-python([<>=]|$)/s/^/# managed by Jetson installer: /' \
    -e '/^[[:space:]]*Pillow([<>=]|$)/s/^/# managed by Jetson installer: /' \
    -e '/^[[:space:]]*torch([<>=]|$)/s/^/# managed by Jetson installer: /' \
    -e '/^[[:space:]]*torchvision([<>=]|$)/s/^/# managed by Jetson installer: /' \
    requirements.txt
)

printf '%s\n' '[7/7] Installing the remaining YOLOv5 dependencies...'
python -m pip install -r "$YOLO_DIR/requirements.txt"

printf '\nInstallation complete. Activate it with:\n  source %q/bin/activate\n' "$VENV_DIR"
