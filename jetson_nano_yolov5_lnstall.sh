#!/bin/bash

# ==============================================================================
#
#  Full Automation Script to Install YOLOv5 on NVIDIA Jetson (Python 3.6)
#
#  This script automates the entire setup process for a specific YOLOv5
#  environment compatible with Python 3.6 on a Jetson device. It handles:
#    1. Creation of a Python 3.6 virtual environment.
#    2. Installation of a pre-built PyTorch v1.10.0 wheel for aarch64.
#    3. Building and installing Torchvision v0.11.1 from source.
#    4. Cloning the correct YOLOv5 version.
#    5. Modifying requirements.txt and installing all dependencies.
#
#  Usage:
#    chmod +x install_yolov5_jetson.sh
#    ./install_yolov5_jetson.sh
#
# ==============================================================================

# Exit immediately if any command fails to prevent errors.
set -e

# --- Configuration ---
# Define the directory for the virtual environment.
VENV_DIR="$HOME/yolov5_py36"

echo "### Starting Full YOLOv5 Setup for Jetson (Python 3.6) ###"
echo "This process is fully automated and will take a significant amount of time."

# --- Step 1: Create Python 3.6 Virtual Environment ---
echo
echo "--- [Step 1/5] Creating Python 3.6 virtual environment at $VENV_DIR ---"
if [ -d "$VENV_DIR" ]; then
    echo "Virtual environment already exists. Skipping creation."
else
    # Use system-site-packages to link to system libraries like the pre-installed OpenCV.
    python3 -m virtualenv "$VENV_DIR" --python=python3.6 --system-site-packages
fi
echo "Virtual environment is ready."


# --- Step 2: Install PyTorch v1.10.0 and Core Dependencies ---
echo
echo "--- [Step 2/5] Installing PyTorch v1.10.0 and core dependencies ---"

# All subsequent 'pip' and 'python' commands will use the executables
# from the virtual environment's bin directory to ensure correct installation.
"$VENV_DIR/bin/pip3" install --upgrade pip setuptools wheel
"$VENV_DIR/bin/pip3" install 'Cython<3.0'
"$VENV_DIR/bin/pip3" install numpy==1.19.2

# Download and install the pre-built PyTorch wheel for Jetson.
wget https://nvidia.box.com/shared/static/fjtbno0vpo676a25cgvuqc1wty0fkkg6.whl -O torch-1.10.0-cp36-cp36m-linux_aarch64.whl
"$VENV_DIR/bin/pip3" install torch-1.10.0-cp36-cp36m-linux_aarch64.whl
# Clean up the downloaded wheel file.
rm torch-1.10.0-cp36-cp36m-linux_aarch64.whl
echo "PyTorch installed successfully."


# --- Step 3: Build and Install Torchvision v0.11.1 from Source ---
echo
echo "--- [Step 3/5] Building Torchvision v0.11.1 from source ---"
echo "--- WARNING: This will take a long time (30+ minutes)! Please be patient. ---"

# Install system libraries required for the build.
sudo apt-get update
sudo apt-get install -y libjpeg-dev zlib1g-dev

# Install a compatible version of the Pillow library.
"$VENV_DIR/bin/pip3" install Pillow==8.4.0

# Clone the specific v0.11.1 branch of the Torchvision repository.
git clone --branch v0.11.1 https://github.com/pytorch/vision ~/torchvision_v0.11.1
cd ~/torchvision_v0.11.1

# Set the build version environment variable and run the build with the venv's python.
export BUILD_VERSION=0.11.1
"$VENV_DIR/bin/python3" setup.py install

# Clean up the source directory to save space.
cd ~
rm -rf ~/torchvision_v0.11.1
echo "Torchvision built and installed successfully."


# --- Step 4: Clone and Configure YOLOv5 ---
echo
echo "--- [Step 4/5] Cloning and configuring YOLOv5 ---"

# Clone the official repository if it doesn't already exist.
if [ -d "$HOME/yolov5" ]; then
    echo "YOLOv5 directory already exists. Skipping clone."
    cd ~/yolov5
else
    git clone https://github.com/ultralytics/yolov5 ~/yolov5
    cd ~/yolov5
fi

# Reset to the last commit that officially supports Python 3.6.
git reset --hard 9bcc32a
echo "YOLOv5 is set to the correct version."


# --- Step 5: Modify requirements.txt and Install Dependencies ---
echo
echo "--- [Step 5/5] Installing remaining YOLOv5 dependencies ---"

# Automatically comment out packages that were installed manually.
# The 'sed' command edits the file in place.
echo "Modifying requirements.txt to prevent conflicts..."
sed -i '/numpy>=/s/^/#/' requirements.txt
sed -i '/opencv-python>=/s/^/#/' requirements.txt
sed -i '/Pillow>=/s/^/#/' requirements.txt
sed -i '/torch>=/s/^/#/' requirements.txt
sed -i '/torchvision>=/s/^/#/' requirements.txt

# Install the remaining dependencies using the venv's pip.
"$VENV_DIR/bin/pip3" install -r requirements.txt
echo "All dependencies installed."


# --- Finalization ---
echo
echo "✅ --- YOLOv5 Setup is Complete! --- ✅"