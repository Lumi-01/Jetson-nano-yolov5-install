#!/bin/bash

# ==============================================================================
# Description:
# This script automates the installation of Python 3.8 on a Jetson Nano
# running JetPack 4.6.4 (Ubuntu 18.04). It updates package lists,
# installs necessary dependencies, adds the 'deadsnakes' PPA, and finally
# installs Python 3.8 and its development headers.
# ==============================================================================

# --- Start of the script ---
echo "🚀 Starting the setup process for Python 3.8 on Jetson Nano..."

# --- 1. Update package lists ---
echo "STEP 1: Updating package lists..."
sudo apt-get update

# --- 2. Install python3-virtualenv ---
echo "STEP 2: Installing python3-virtualenv..."
sudo apt-get install -y python3-virtualenv

# --- 3. Install software-properties-common ---
# This utility is needed to manage Personal Package Archives (PPAs).
echo "STEP 3: Installing software-properties-common..."
sudo apt-get install -y software-properties-common

# --- 4. Add the 'deadsnakes' PPA ---
# This PPA provides newer Python versions for Ubuntu.
echo "STEP 4: Adding the 'deadsnakes' PPA..."
sudo add-apt-repository ppa:deadsnakes/ppa

# --- 5. Update package lists again ---
# An update is required to fetch the package lists from the newly added PPA.
echo "STEP 5: Updating package lists again..."
sudo apt-get update

# --- 6. Install Python 3.8 ---
# Installs Python 3.8 and its necessary development headers.
# The -y flag automatically confirms any installation prompts.
echo "STEP 6: Installing Python 3.8 and python3.8-dev... This may take a few moments."
sudo apt-get install -y python3.8 python3.8-dev

# --- Completion ---
echo "✅ Success! Python 3.8 has been successfully installed."
echo "You can verify the installation by running: python3.8 --version"
echo "Happy coding! ✨"