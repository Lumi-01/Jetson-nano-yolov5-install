#!/bin/bash
#
# This script automates the setup of a YOLOv5 environment on an NVIDIA Jetson device.
# It specifically targets Python 3.6 and installs compatible versions of
# PyTorch, Torchvision, and other dependencies.
#
# Exit immediately if a command exits with a non-zero status.
set -e

echo "--- Starting YOLOv5 Setup for NVIDIA Jetson (Python 3.6) ---"

# --- 1. Create and Activate Virtual Environment ---
echo "[1/6] Creating Python 3.6 virtual environment in '~/yolov5-py36'..."
python3 -m virtualenv ~/yolov5-py36 --python=python3.6 --system-site-packages
source ~/yolov5-py36/bin/activate
echo "Virtual environment activated for this session."

# --- 2. Install Core Python Packages ---
echo "[2/6] Upgrading pip and installing base packages (Cython, Numpy, Pillow)..."
pip3 install --upgrade pip setuptools wheel
pip3 install 'Cython<3.0'
pip3 install numpy==1.19.2
# This specific Pillow version helps avoid potential syntax errors with older Python versions.
pip3 install Pillow==8.4.0

# --- 3. Install PyTorch ---
echo "[3/6] Downloading and installing PyTorch v1.10.0 for Jetson..."
wget https://nvidia.box.com/shared/static/fjtbno0vpo676a25cgvuqc1wty0fkkg6.whl -O torch-1.10.0-cp36-cp36m-linux_aarch64.whl
pip3 install torch-1.10.0-cp36-cp36m-linux_aarch64.whl
# Clean up the downloaded file
rm torch-1.10.0-cp36-cp36m-linux_aarch64.whl

# --- 4. Install Torchvision from Source ---
echo "[4/6] Building and installing Torchvision v0.11.1 from source..."
echo "Installing build dependencies for Torchvision..."
sudo apt-get update && sudo apt-get install -y libjpeg-dev zlib1g-dev

echo "Cloning Torchvision v0.11.1 repository..."
git clone --branch v0.11.1 https://github.com/pytorch/vision ~/torchvision_build
cd ~/torchvision_build

export BUILD_VERSION=0.11.1
echo "Starting Torchvision build. WARNING: This process can take over 30 minutes."
python3 setup.py install
echo "Torchvision build complete."

# Clean up the build directory
cd ~
rm -rf ~/torchvision_build

# --- 5. Clone and Configure YOLOv5 ---
echo "[5/6] Cloning YOLOv5 and checking out a Python 3.6 compatible version..."
git clone https://github.com/ultralytics/yolov5 ~/yolov5
cd ~/yolov5
# This commit is the last version to officially support Python 3.6.
git reset --hard 9bcc32a0335265a25c1477d54406a6c2f328f644

# --- 6. Install YOLOv5 Dependencies ---
echo "[6/6] Modifying requirements.txt and installing dependencies..."
# Comment out packages that were manually installed or are handled by the system.
# This prevents version conflicts.
sed -i '/numpy/s/^/#/' requirements.txt
sed -i '/opencv-python/s/^/#/' requirements.txt
sed -i '/Pillow/s/^/#/' requirements.txt
sed -i '/torch>=/s/^/#/' requirements.txt
sed -i '/torchvision>=/s/^/#/' requirements.txt

pip3 install -r requirements.txt

echo ""
echo "--- YOLOv5 Setup Successfully Completed! ---"
echo ""
echo "The virtual environment 'yolov5-py36' is ready."
echo "To activate it in a new terminal session, run:"
echo "source ~/yolov5-py36/bin/activate"
echo "---------------------------------------------"