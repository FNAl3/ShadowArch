#!/bin/bash

# ShadowArch Post-Install Wizard
# Detects hardware and configures drivers

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== ShadowArch Post-Install Wizard ===${NC}"

if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}Please run as root.${NC}"
  exit 1
fi

echo -e "${BLUE}Checking Internet Connectivity...${NC}"
if ping -c 1 8.8.8.8 &> /dev/null; then
    echo -e "${GREEN}Internet detected.${NC}"
else
    echo -e "${RED}No internet connection. Driver installation might fail.${NC}"
    read -p "Continue anyway? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

echo -e "${BLUE}Detecting Hardware...${NC}"
GPU_NVIDIA=$(lspci | grep -i nvidia)
GPU_VMWARE=$(lspci | grep -i -E "vmware|virtualbox")

if [[ -n "$GPU_NVIDIA" ]]; then
    echo -e "${GREEN}NVIDIA GPU Detected!${NC}"
    read -p "Install proprietary NVIDIA drivers (dkms)? (Y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ || -z $REPLY ]]; then
        echo "Installing NVIDIA drivers..."
        pacman -S --noconfirm linux-headers nvidia-dkms nvidia-utils egl-wayland lib32-nvidia-utils 
        
        echo "Configuring Kernel Parameters (GRUB)..."
        sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="/GRUB_CMDLINE_LINUX_DEFAULT="nvidia_drm.modeset=1 /' /etc/default/grub
        grub-mkconfig -o /boot/grub/grub.cfg
        
        echo "Configuring mkinitcpio..."
        sed -i 's/MODULES=(/MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm /' /etc/mkinitcpio.conf
        mkinitcpio -P
    fi

elif [[ -n "$GPU_VMWARE" ]]; then
    echo -e "${GREEN}Virtual Machine Detected (VMware/VirtualBox).${NC}"
    echo "Ensuring guest utilities are installed..."
    pacman -S --noconfirm virtualbox-guest-utils xf86-video-vmware vulkan-swrast
    systemctl enable vboxservice 2>/dev/null || true
else
    echo "Standard AMD/Intel GPU or unknown. No special proprietary drivers needed usually."
fi

echo -e "${BLUE}System configured! Reboot recommended.${NC}"
