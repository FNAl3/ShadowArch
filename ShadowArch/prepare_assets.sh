#!/bin/bash

# ShadowArch Asset Preparation
# Downloads themes, icons, and tools to the airootfs directory so they are included in the ISO.

set -e

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AIROOTFS_DIR="$REPO_ROOT/airootfs"

echo "[*] Preparing Assets..."

# 1. Create Directories
mkdir -p "$AIROOTFS_DIR/usr/share/themes"
mkdir -p "$AIROOTFS_DIR/usr/share/backgrounds"
mkdir -p "$AIROOTFS_DIR/opt/PenTools"

# 2. Download Dracula Theme
echo "    Downloading Dracula Theme..."
if [ ! -d "$AIROOTFS_DIR/usr/share/themes/Dracula" ]; then
    curl -L -o /tmp/dracula.zip https://github.com/dracula/gtk/archive/master.zip
    unzip -o -q /tmp/dracula.zip -d /tmp/
    mv /tmp/gtk-master "$AIROOTFS_DIR/usr/share/themes/Dracula"
    rm /tmp/dracula.zip
else
    echo "    Dracula Theme already present."
fi

# 3. Clone PenTools
echo "    Cloning PenTools..."
if [ ! -d "$AIROOTFS_DIR/opt/PenTools/.git" ]; then
    rm -rf "$AIROOTFS_DIR/opt/PenTools"
    git clone --depth 1 https://github.com/FNAl3/PenTools "$AIROOTFS_DIR/opt/PenTools"
    chmod +x "$AIROOTFS_DIR/opt/PenTools"/*.py
    chmod +x "$AIROOTFS_DIR/opt/PenTools"/*.sh
else
    echo "    PenTools already present."
fi

# 4. Copy Wallpaper
echo "    Copying Wallpaper..."
if [ -f "$REPO_ROOT/logo.png" ]; then
    cp "$REPO_ROOT/logo.png" "$AIROOTFS_DIR/usr/share/backgrounds/shadowk.png"
else
    echo "    Warning: logo.png not found in project root."
fi

echo "[*] Assets Prepared."
