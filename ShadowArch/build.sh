#!/bin/bash

# ShadowArch Auto-Builder
# This script handles the End-to-End process:
# 1. Checks if running on persistent disk.
# 2. If not, runs setup_workspace.sh to migrate.
# 3. Reloads itself from the new location to continue the build.

set -e # Exit on error

WORKSPACE_DIR="/mnt/build_workspace"
CURRENT_DIR=$(pwd)

echo "========================================"
echo "    ShadowArch Master Builder"
echo "========================================"

# --- Phase 1: Environment Check ---
if [[ "$CURRENT_DIR" != "$WORKSPACE_DIR" ]]; then
    echo "[!] Not running from persistent workspace ($WORKSPACE_DIR)."
    echo "[*] Initializing Workspace Setup..."
    
    chmod +x setup_workspace.sh
    ./setup_workspace.sh
    
    echo "----------------------------------------"
    echo "[*] Workspace Ready. Transferring control to persistent storage..."
    echo "----------------------------------------"
    
    # Handover control to the script on the hard drive
    cd "$WORKSPACE_DIR"
    exec ./build.sh
fi

# --- Phase 2: Build Process (Runs on Hard Drive) ---
echo "[+] Running from Persistent Storage. Starting Build..."

# 1. Preparation
echo "--> Step 1: Downloading Assets (prepare_iso.sh)..."
chmod +x prepare_iso.sh
./prepare_iso.sh

# 2. Cleanup
if [ -d "work" ]; then
    echo "--> Cleaning previous work directory..."
    rm -rf work
fi

# 3. Build
echo "--> Step 2: Building ISO (mkarchiso)..."
mkarchiso -v -w work -o out .

echo "========================================"
echo "    BUILD COMPLETE!"
echo "========================================"
echo "ISO is located in: $WORKSPACE_DIR/out/"
