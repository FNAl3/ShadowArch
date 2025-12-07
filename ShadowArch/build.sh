#!/bin/bash

# ShadowArch Auto-Builder (FIXED)
# This script handles:
# 1. Migrating to persistent disk (/mnt/build_workspace).
# 2. Redirecting Pacman Cache to disk (Saves RAM).
# 3. Building the ISO.

set -e # Exit on error

WORKSPACE_DIR="/mnt/build_workspace"
CURRENT_DIR=$(pwd)
PACMAN_CACHE_DIR="$WORKSPACE_DIR/pacman_cache"
ORIGINAL_CACHE="/var/cache/pacman/pkg"

echo "========================================"
echo "    ShadowArch Master Builder (Fixed)"
echo "========================================"

# --- Phase 1: Environment Check & Handover ---
if [[ "$CURRENT_DIR" != "$WORKSPACE_DIR" ]]; then
    echo "[!] Not in Workspace. Checking if setup is needed..."
    
    # Run setup if workspace doesn't look ready
    if [ ! -d "$WORKSPACE_DIR" ]; then
        echo "[*] Initializing Workspace Setup..."
        chmod +x setup_workspace.sh
        ./setup_workspace.sh
    fi
    
    echo "[->] Transferring to Persistent Storage..."
    cd "$WORKSPACE_DIR"
    exec ./build.sh
fi

# --- Phase 2: Build Process (Runs on Hard Drive) ---
echo "[+] Running from Persistent Storage ($WORKSPACE_DIR)."

# CRITICAL FIX: Redirect Pacman Cache to Disk
echo "[*] Setting up Persistent Pacman Cache..."
mkdir -p "$PACMAN_CACHE_DIR"
# Unmount if already mounted to avoid stacking
if mountPOINT=$(mount | grep "$ORIGINAL_CACHE"); then
    umount "$ORIGINAL_CACHE"
fi
# Bind mount
mount --bind "$PACMAN_CACHE_DIR" "$ORIGINAL_CACHE"
echo "[+] Cache directed to: $PACMAN_CACHE_DIR"

# 1. Preparation
echo "--> Step 1: Downloading Assets..."
chmod +x prepare_iso.sh
./prepare_iso.sh

# 2. Cleanup
if [ -d "work" ]; then
    echo "--> Cleaning previous work directory..."
    rm -rf work
fi

# 3. Build
echo "--> Step 2: Building ISO..."
# We explicitly force the work directory to be on the mounted disk
# Capturing output to log file
mkarchiso -v -w "$WORKSPACE_DIR/work" -o "$WORKSPACE_DIR/out" . 2>&1 | tee "$WORKSPACE_DIR/build_log.txt"

# Cleanup Hook
echo "--> Cleaning up Cache Mount..."
umount "$ORIGINAL_CACHE"

echo "========================================"
echo "    BUILD COMPLETE!"
echo "========================================"
echo "ISO is located in: $WORKSPACE_DIR/out/"
