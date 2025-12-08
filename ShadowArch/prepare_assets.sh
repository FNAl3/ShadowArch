#!/bin/bash

# ShadowArch Asset Preparation
# Downloads themes and tools needed for installation.

set -e

# 1. Download Dracula Theme
THEME_URL="https://github.com/dracula/gtk/archive/master.zip"
THEME_DIR="airootfs/usr/share/themes"
THEME_NAME="Dracula"

echo "=== Downloading GTK Theme ==="
mkdir -p "$THEME_DIR"
if [ ! -d "$THEME_DIR/Dracula" ]; then
    curl -L -o theme.zip "$THEME_URL"
    unzip -o theme.zip -d "$THEME_DIR"
    mv "$THEME_DIR/gtk-master" "$THEME_DIR/Dracula" 2>/dev/null || true
    rm theme.zip
    echo "Theme Ready: $THEME_DIR/Dracula"
else
    echo "Theme already present."
fi

# 2. Download PenTools
PENTOOLS_REPO="https://github.com/FNAl3/PenTools"
PENTOOLS_DIR="airootfs/opt/PenTools"

echo "=== Downloading Custom PenTools ==="
if [ -d "$PENTOOLS_DIR" ]; then
    echo "Updating PenTools..."
    cd "$PENTOOLS_DIR"
    git pull
    cd - > /dev/null
else
    echo "Cloning PenTools..."
    git clone --depth 1 "$PENTOOLS_REPO" "$PENTOOLS_DIR"
fi

# Make scripts executable
chmod +x "$PENTOOLS_DIR"/*.py 2>/dev/null
chmod +x "$PENTOOLS_DIR"/*.sh 2>/dev/null

# 3. Setup Wallpapers
echo "=== Setting up Wallpapers ==="
mkdir -p airootfs/usr/share/backgrounds
if [ -f "logo.png" ]; then
    cp logo.png airootfs/usr/share/backgrounds/shadowk.png
    echo "Logo copied to backgrounds."
fi

echo "=== Preparation Complete ==="
