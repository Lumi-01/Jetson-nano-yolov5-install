#!/usr/bin/env bash
set -Eeuo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
YOLO_SCRIPT="$REPO_ROOT/jetson_nano_yolov5_lnstall.sh"
OPENCV_SCRIPT="$REPO_ROOT/OpenCV-4.11.0.sh"
TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/jetson-script-test.XXXXXX")"
trap 'rm -rf -- "$TEST_ROOT"' EXIT

expect_failure() {
  local expected="$1"
  shift
  local output status

  set +e
  output="$("$@" 2>&1)"
  status=$?
  set -e

  if (( status == 0 )); then
    printf 'Expected failure but command succeeded: %q\n' "$*" >&2
    return 1
  fi
  if ! grep -F -- "$expected" <<<"$output" >/dev/null; then
    printf 'Expected message not found: %s\nOutput:\n%s\n' "$expected" "$output" >&2
    return 1
  fi
}

printf '%s\n' 'Checking shell syntax...'
while IFS= read -r -d '' script; do
  bash -n "$script"
done < <(find "$REPO_ROOT" -maxdepth 1 -type f -name '*.sh' -print0)

printf '%s\n' 'Checking the non-Jetson hardware guards...'
expect_failure 'This installer requires an aarch64 Jetson system.' \
  env HOME="$TEST_ROOT/home-x86" bash "$YOLO_SCRIPT"
expect_failure '/proc/device-tree/model not found' \
  env HOME="$TEST_ROOT/home-opencv" bash "$OPENCV_SCRIPT"

printf '%s\n' 'Checking existing-installation guards...'
mkdir -p "$TEST_ROOT/mock-bin" "$TEST_ROOT/home-existing/yolov5"
cat >"$TEST_ROOT/mock-bin/uname" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' aarch64
EOF
cat >"$TEST_ROOT/mock-bin/python3.6" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
chmod +x "$TEST_ROOT/mock-bin/uname" "$TEST_ROOT/mock-bin/python3.6"

expect_failure 'yolov5 already exists' \
  env HOME="$TEST_ROOT/home-existing" PATH="$TEST_ROOT/mock-bin:$PATH" bash "$YOLO_SCRIPT"
rmdir "$TEST_ROOT/home-existing/yolov5"
mkdir -p "$TEST_ROOT/home-existing/yolov5-py36"
expect_failure 'yolov5-py36 already exists' \
  env HOME="$TEST_ROOT/home-existing" PATH="$TEST_ROOT/mock-bin:$PATH" bash "$YOLO_SCRIPT"

printf '%s\n' 'Checking pinned versions and cleanup boundaries...'
grep -F -- 'YOLO_COMMIT="9bcc32a"' "$YOLO_SCRIPT" >/dev/null
grep -F -- 'TORCHVISION_VERSION="0.11.1"' "$YOLO_SCRIPT" >/dev/null
grep -F -- "'pip<22' 'setuptools<60' 'wheel<0.38'" "$YOLO_SCRIPT" >/dev/null
grep -F -- 'rm -rf -- "$WORK_DIR"' "$YOLO_SCRIPT" >/dev/null
grep -F -- 'sudo -v' "$YOLO_SCRIPT" >/dev/null
grep -F -- 'sudo -n true' "$YOLO_SCRIPT" >/dev/null
grep -F -- 'sudo rm -rf -- "$HOME/opencv" "$HOME/opencv_contrib"' "$OPENCV_SCRIPT" >/dev/null
grep -F -- 'NO_JOB="${OPENCV_BUILD_JOBS:-2}"' "$OPENCV_SCRIPT" >/dev/null
grep -F -- 'Automatic confirmation enabled' "$OPENCV_SCRIPT" >/dev/null
grep -F -- 'sudo -v' "$OPENCV_SCRIPT" >/dev/null
grep -F -- 'sudo -n true' "$OPENCV_SCRIPT" >/dev/null
if grep -F -- 'sudo -S' "$YOLO_SCRIPT" "$OPENCV_SCRIPT" >/dev/null; then
  printf '%s\n' 'A script attempts to read a sudo password from standard input.' >&2
  exit 1
fi
if grep -E -- '^[[:space:]]*read([[:space:]]|$)' "$OPENCV_SCRIPT" >/dev/null; then
  printf '%s\n' 'Interactive read remains in the OpenCV installer.' >&2
  exit 1
fi
if grep -E -- 'rm[[:space:]]+-rf[[:space:]]+opencv\*' "$OPENCV_SCRIPT" >/dev/null; then
  printf '%s\n' 'Unsafe wildcard OpenCV cleanup found.' >&2
  exit 1
fi

printf '%s\n' 'All Jetson script simulations passed.'
