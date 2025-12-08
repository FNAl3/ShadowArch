#!/bin/bash

# ShadowArch Git Installer Wrapper
# This script prepares the environment and runs the installer.

set -e

echo "========================================"
echo "    ShadowArch Installer Wrapper"
echo "========================================"

# 1. Install Dependencies (Python & YAML)
echo "[*] Checking Dependencies..."
if ! command -v python &> /dev/null || ! python -c "import yaml" 2>/dev/null; then
    echo "    Installing Python and PyYAML..."
    pacman -Sy --noconfirm python python-yaml
else
    echo "    Dependencies met."
fi

# 2. Launch Installer
echo "[*] Launching Installation Script..."
echo "    Config: config.yaml"
echo "========================================"

chmod +x airootfs/root/install_script.py
python airootfs/root/install_script.py airootfs/root/config.yaml

echo "========================================"
echo "    Wrapper Finished."
echo "========================================"
