#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RAW_BASE="https://raw.githubusercontent.com/Lumi-01/Jetson-nano-yolov5-install/main"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/jetson-nano-yolov5-install"
LOG_DIR="$STATE_DIR/logs"
WORK_DIR=""
SUDO_KEEPALIVE_PID=""
TEMP_SWAP_FILE=""
TEMP_SWAP_ACTIVE=0
FORCE=0
ALLOW_LOW_SWAP=0

usage() {
  cat <<'EOF'
Usage: ./install-all.sh [--force] [--allow-low-swap]

Installs OpenCV 4.11.0, applies the OpenBLAS workaround, installs YOLOv5,
and verifies the resulting Python environment on an original Jetson Nano.

  --force           rerun stages already marked as completed
  --allow-low-swap  continue if temporary swap creation is not possible
  -h, --help        show this help
EOF
}

die() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

cleanup() {
  if [[ -n "$TEMP_SWAP_FILE" ]]; then
    if [[ "$TEMP_SWAP_ACTIVE" == "1" ]]; then
      printf 'Restoring the original swap configuration...\n'
      if sudo -n swapoff "$TEMP_SWAP_FILE" 2>/dev/null; then
        TEMP_SWAP_ACTIVE=0
      else
        printf 'Warning: could not disable temporary swap: %s\n' "$TEMP_SWAP_FILE" >&2
        printf 'After freeing memory, run: sudo swapoff %q && sudo rm -f %q\n' \
          "$TEMP_SWAP_FILE" "$TEMP_SWAP_FILE" >&2
      fi
    fi
    if [[ "$TEMP_SWAP_ACTIVE" == "0" ]]; then
      sudo -n rm -f -- "$TEMP_SWAP_FILE" 2>/dev/null || \
        printf 'Warning: remove the leftover temporary file manually: %s\n' "$TEMP_SWAP_FILE" >&2
    fi
  fi
  if [[ -n "$SUDO_KEEPALIVE_PID" ]] && kill -0 "$SUDO_KEEPALIVE_PID" 2>/dev/null; then
    kill "$SUDO_KEEPALIVE_PID" 2>/dev/null || true
    wait "$SUDO_KEEPALIVE_PID" 2>/dev/null || true
  fi
  if [[ -n "$WORK_DIR" && -d "$WORK_DIR" ]]; then
    rm -rf -- "$WORK_DIR"
  fi
}
trap cleanup EXIT

prepare_sudo() {
  command -v sudo >/dev/null 2>&1 || die "sudo is required."
  printf '%s\n' 'Administrator permission is required. Enter the sudo password once for the complete installation.'
  sudo -v || die "sudo authentication failed."
  (
    while true; do
      sleep 50
      sudo -n true 2>/dev/null || exit
    done
  ) &
  SUDO_KEEPALIVE_PID=$!
  export JETSON_SUDO_READY=1
}

ensure_swap() {
  local target_kb=$((8 * 1024 * 1024))
  local current_kb needed_kb needed_mb available_kb

  current_kb="$(awk '/^SwapTotal:/ {print $2}' /proc/meminfo)"
  current_kb="${current_kb:-0}"
  if (( current_kb >= target_kb )); then
    printf 'Swap: %.1f GiB already configured; no temporary swap needed.\n' \
      "$(awk -v kb="$current_kb" 'BEGIN {print kb / 1024 / 1024}')"
    return
  fi

  needed_kb=$((target_kb - current_kb))
  needed_mb=$(((needed_kb + 1023) / 1024))
  available_kb="$(df -Pk /var/tmp | awk 'NR == 2 {print $4}')"
  available_kb="${available_kb:-0}"
  if (( available_kb <= needed_kb + 1024 * 1024 )); then
    if [[ "$ALLOW_LOW_SWAP" == "1" ]]; then
      printf 'Warning: insufficient free space for temporary swap; continuing by request.\n' >&2
      return
    fi
    die "Not enough free space to add temporary swap while retaining 1GB free."
  fi

  command -v mkswap >/dev/null 2>&1 || die "mkswap is required."
  command -v swapon >/dev/null 2>&1 || die "swapon is required."
  command -v swapoff >/dev/null 2>&1 || die "swapoff is required."
  TEMP_SWAP_FILE="/var/tmp/jetson-install-all-${UID}-$$.swap"
  [[ ! -e "$TEMP_SWAP_FILE" ]] || die "Temporary swap path already exists: $TEMP_SWAP_FILE"

  printf 'Adding %s MiB of temporary swap to reach 8 GiB...\n' "$needed_mb"
  if command -v fallocate >/dev/null 2>&1; then
    if ! sudo fallocate -l "${needed_mb}M" "$TEMP_SWAP_FILE"; then
      sudo rm -f -- "$TEMP_SWAP_FILE"
      sudo dd if=/dev/zero of="$TEMP_SWAP_FILE" bs=1M count="$needed_mb"
    fi
  else
    sudo dd if=/dev/zero of="$TEMP_SWAP_FILE" bs=1M count="$needed_mb"
  fi

  if ! sudo chmod 600 "$TEMP_SWAP_FILE" || \
     ! sudo mkswap "$TEMP_SWAP_FILE" || \
     ! sudo swapon "$TEMP_SWAP_FILE"; then
    sudo rm -f -- "$TEMP_SWAP_FILE" 2>/dev/null || true
    TEMP_SWAP_FILE=""
    if [[ "$ALLOW_LOW_SWAP" == "1" ]]; then
      printf 'Warning: temporary swap setup failed; continuing by request.\n' >&2
      return
    fi
    die "Failed to create temporary swap."
  fi
  TEMP_SWAP_ACTIVE=1
  printf 'Temporary swap enabled: %s\n' "$TEMP_SWAP_FILE"
}

for argument in "$@"; do
  case "$argument" in
    --force) FORCE=1 ;;
    --allow-low-swap) ALLOW_LOW_SWAP=1 ;;
    -h|--help) usage; exit 0 ;;
    *) usage >&2; die "Unknown argument: $argument" ;;
  esac
done

[[ "${EUID}" -ne 0 ]] || die "Do not run this installer as root. Run it as your normal user."
[[ "$(uname -m)" == "aarch64" ]] || die "This installer requires an aarch64 Jetson system."
[[ -r /proc/device-tree/model ]] || die "/proc/device-tree/model was not found."
DEVICE_MODEL="$(tr -d '\0' </proc/device-tree/model)"
[[ "$DEVICE_MODEL" == *"Jetson Nano"* && "$DEVICE_MODEL" != *"Orin"* ]] || \
  die "This complete installer targets the original Jetson Nano, not: $DEVICE_MODEL"
command -v python3.6 >/dev/null 2>&1 || die "Python 3.6 is required from JetPack 4.6.x."
command -v wget >/dev/null 2>&1 || die "wget is required."

mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/install-$(date +%Y%m%d-%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

printf 'Device: %s\n' "$DEVICE_MODEL"
printf 'Log: %s\n' "$LOG_FILE"
prepare_sudo
ensure_swap
export OPENCV_BUILD_JOBS="${OPENCV_BUILD_JOBS:-4}"
export TORCHVISION_BUILD_JOBS="${TORCHVISION_BUILD_JOBS:-4}"
printf 'Build jobs: OpenCV=%s, Torchvision=%s\n' "$OPENCV_BUILD_JOBS" "$TORCHVISION_BUILD_JOBS"

WORK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/jetson-install-all.XXXXXX")"
OPENCV_SCRIPT="$SCRIPT_DIR/OpenCV-4.11.0.sh"
YOLO_SCRIPT="$SCRIPT_DIR/jetson_nano_yolov5_lnstall.sh"
if [[ ! -f "$OPENCV_SCRIPT" ]]; then
  OPENCV_SCRIPT="$WORK_DIR/OpenCV-4.11.0.sh"
  wget -O "$OPENCV_SCRIPT" "$RAW_BASE/OpenCV-4.11.0.sh"
fi
if [[ ! -f "$YOLO_SCRIPT" ]]; then
  YOLO_SCRIPT="$WORK_DIR/jetson_nano_yolov5_lnstall.sh"
  wget -O "$YOLO_SCRIPT" "$RAW_BASE/jetson_nano_yolov5_lnstall.sh"
fi

if [[ "$FORCE" == "1" || ! -f "$STATE_DIR/opencv.done" ]]; then
  printf '%s\n' '[1/4] Installing OpenCV 4.11.0...'
  bash "$OPENCV_SCRIPT"
  touch "$STATE_DIR/opencv.done"
else
  printf '%s\n' '[1/4] OpenCV stage already completed; skipping.'
fi

printf '%s\n' '[2/4] Applying the OpenBLAS compatibility setting...'
OPENBLAS_LINE='export OPENBLAS_CORETYPE=ARMV8'
touch "$HOME/.bashrc"
if ! grep -Fqx -- "$OPENBLAS_LINE" "$HOME/.bashrc"; then
  printf '%s\n' "$OPENBLAS_LINE" >>"$HOME/.bashrc"
fi
export OPENBLAS_CORETYPE=ARMV8
touch "$STATE_DIR/openblas.done"

if [[ "$FORCE" == "1" || ! -f "$STATE_DIR/yolov5.done" ]]; then
  printf '%s\n' '[3/4] Installing PyTorch, Torchvision, and YOLOv5...'
  bash "$YOLO_SCRIPT"
  touch "$STATE_DIR/yolov5.done"
else
  printf '%s\n' '[3/4] YOLOv5 stage already completed; skipping.'
fi

printf '%s\n' '[4/4] Verifying Python imports...'
VENV_PYTHON="$HOME/yolov5-py36/bin/python"
[[ -x "$VENV_PYTHON" ]] || die "Virtual-environment Python was not found at $VENV_PYTHON."
"$VENV_PYTHON" - <<'PY'
import cv2
import torch
import torchvision

print("OpenCV:", cv2.__version__)
print("PyTorch:", torch.__version__)
print("Torchvision:", torchvision.__version__)
print("CUDA available:", torch.cuda.is_available())
PY

printf '\nComplete installation finished successfully.\nLog: %s\n' "$LOG_FILE"
