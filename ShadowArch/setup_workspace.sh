#!/bin/bash

# Configuration
DISK="/dev/sda"
MOUNTPOINT="/mnt/build_workspace"
CURRENT_DIR=$(pwd)

echo "=========================================="
echo "   ShadowArch Build Workspace Setup"
echo "=========================================="
echo "This script will:"
echo "1. Format $DISK (ALL DATA WILL BE LOST)"
echo "2. Mount it to $MOUNTPOINT"
echo "3. Copy the project from RAM to disk"
echo "=========================================="

# Check if disk exists
if [ ! -b "$DISK" ]; then
    echo "Error: Disk $DISK not found."
    exit 1
fi

# Confirmation
read -p "Are you sure you want to Wipe $DISK? (y/N): " confirm
if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
    echo "Aborted."
    exit 1
fi

echo "--> Wiping disk headers..."
wipefs -a "$DISK"

echo "--> Creating partition table (GPT)..."
parted -s "$DISK" mklabel gpt
parted -s "$DISK" mkpart primary ext4 0% 100%

echo "--> Formatting partition ${DISK}1 (ext4)..."
mkfs.ext4 -F "${DISK}1"

echo "--> Creating mountpoint..."
mkdir -p "$MOUNTPOINT"

echo "--> Mounting..."
mount "${DISK}1" "$MOUNTPOINT"

echo "--> Migrating Project..."
echo "    Source: $CURRENT_DIR"
echo "    Dest:   $MOUNTPOINT"
cp -rT "$CURRENT_DIR" "$MOUNTPOINT"

echo "=========================================="
echo "   SUCCESS!"
echo "=========================================="
echo "To continue building, run:"
echo ""
echo "    cd $MOUNTPOINT"
echo "    ./prepare_iso.sh"
echo "    mkarchiso -v -w work -o out ."
echo ""
echo "=========================================="
