#!/bin/bash

# 1. Download Dracula Theme
THEME_URL="https://github.com/dracula/gtk/archive/master.zip"
THEME_DIR="airootfs/usr/share/themes"
THEME_NAME="Dracula"

echo "=== Downloading GTK Theme ==="
mkdir -p "$THEME_DIR"
curl -L -o theme.zip "$THEME_URL"
unzip -o theme.zip -d "$THEME_DIR"
mv "$THEME_DIR/gtk-master" "$THEME_DIR/Dracula" 2>/dev/null || true
rm theme.zip
echo "Theme Ready: $THEME_DIR/Dracula"

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
    git clone "$PENTOOLS_REPO" "$PENTOOLS_DIR"
fi

# Make scripts executable
chmod +x "$PENTOOLS_DIR"/*.py 2>/dev/null
chmod +x "$PENTOOLS_DIR"/*.sh 2>/dev/null

# Create a symlink in /usr/local/bin for easy access if desired
# (Archiso handles permissions in profiledef.sh, but we can pre-create links if we want)

echo "=== Preparation Complete ==="
echo "You can now build the ISO."
