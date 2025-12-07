#!/bin/bash

# ShadowArch Comprehensive Post-Install Wizard
# Scans system for Hardware and installs necessary drivers/optimizations

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}==========================================${NC}"
echo -e "${BLUE}   ShadowArch System Hardware Scanner     ${NC}"
echo -e "${BLUE}==========================================${NC}"

if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}Please run as root (sudo shadow-wizard).${NC}"
  exit 1
fi

echo -e "${BLUE}[*] Checking Internet Connectivity...${NC}"
if ping -c 1 8.8.8.8 &> /dev/null; then
    echo -e "${GREEN}    Connected.${NC}"
else
    echo -e "${RED}    No internet connection.${NC}"
    echo -e "${YELLOW}    Driver installation requires internet. Exiting.${NC}"
    exit 1
fi

# Refresh repos
echo -e "${BLUE}[*] Refreshing Repositories...${NC}"
pacman -Sy > /dev/null 2>&1

echo -e "\n${BLUE}=== Hardware Detection ===${NC}"

# 1. CPU Detection (Microcode)
CPU_VENDOR=$(lscpu | grep "Vendor ID" | awk '{print $3}')
echo -e "${BLUE}[*] Detecting CPU...${NC} ($CPU_VENDOR)"

if [[ "$CPU_VENDOR" == "GenuineIntel" ]]; then
    echo -e "${GREEN}    Intel CPU Detected.${NC}"
    if pacman -Qi intel-ucode &> /dev/null; then
        echo "    intel-ucode already installed."
    else
        echo "    Installing Intel Microcode..."
        pacman -S --noconfirm intel-ucode
        echo "    Updating Bootloader..."
        grub-mkconfig -o /boot/grub/grub.cfg
    fi
elif [[ "$CPU_VENDOR" == "AuthenticAMD" ]]; then
    echo -e "${GREEN}    AMD CPU Detected.${NC}"
    if pacman -Qi amd-ucode &> /dev/null; then
        echo "    amd-ucode already installed."
    else
        echo "    Installing AMD Microcode..."
        pacman -S --noconfirm amd-ucode
        echo "    Updating Bootloader..."
        grub-mkconfig -o /boot/grub/grub.cfg
    fi
fi

# 2. GPU Detection
echo -e "${BLUE}[*] Detecting GPU...${NC}"
GPU_NVIDIA=$(lspci | grep -i nvidia)
GPU_VMWARE=$(lspci | grep -i -E "vmware|virtualbox")

if [[ -n "$GPU_NVIDIA" ]]; then
    echo -e "${GREEN}    NVIDIA GPU Detected!${NC}"
    read -p "    Install proprietary NVIDIA drivers (dkms)? (Y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ || -z $REPLY ]]; then
        echo "    Installing NVIDIA drivers..."
        pacman -S --noconfirm linux-headers nvidia-dkms nvidia-utils egl-wayland lib32-nvidia-utils 
        
        echo "    Configuring GRUB for NVIDIA DRM..."
        sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="/GRUB_CMDLINE_LINUX_DEFAULT="nvidia_drm.modeset=1 /' /etc/default/grub
        grub-mkconfig -o /boot/grub/grub.cfg
        
        echo "    Configuring mkinitcpio..."
        sed -i 's/MODULES=(/MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm /' /etc/mkinitcpio.conf
        mkinitcpio -P
    fi
elif [[ -n "$GPU_VMWARE" ]]; then
    echo -e "${GREEN}    Virtual Machine Detected.${NC}"
    echo "    Ensuring Guest Utilities & Software Rendering..."
    pacman -S --noconfirm virtualbox-guest-utils xf86-video-vmware vulkan-swrast
    systemctl enable vboxservice 2>/dev/null || true
else
    echo -e "${GREEN}    Standard/Intel/AMD GPU detected. Using Open Source drivers.${NC}"
fi

# 3. System Chassis (Laptop vs Desktop)
echo -e "${BLUE}[*] Detecting System Type...${NC}"
# Fallback check if chassis_type file doesn't exist (e.g. some VMs)
if [ -f /sys/class/dmi/id/chassis_type ]; then
    CHASSIS_TYPE=$(cat /sys/class/dmi/id/chassis_type)
    # Types 9, 10, 14, 30, 31, 32 imply laptops/convertibles
    if [[ "$CHASSIS_TYPE" =~ ^(9|10|14|30|31|32)$ ]]; then
        echo -e "${GREEN}    Laptop Detected.${NC}"
        
        # Power Management
        echo "    Installing TLP (Power Management)..."
        pacman -S --noconfirm tlp
        systemctl enable tlp
        
        # Bluetooth
        echo "    Installing Bluetooth Stack..."
        pacman -S --noconfirm bluez bluez-utils
        systemctl enable bluetooth
    else
        echo "    Desktop/Server detected. Skipping Laptop optimizations."
    fi
else
    echo "    Chassis type undetermined. Assuming Desktop."
fi

# 4. Sensors
echo -e "${BLUE}[*] Configuring Sensors...${NC}"
if pacman -Qi lm_sensors &> /dev/null; then
    echo "    lm_sensors installed. Detecting sensors..."
    sensors-detect --auto
else
    echo "    Installing lm_sensors..."
    pacman -S --noconfirm lm_sensors
    sensors-detect --auto
fi

echo -e "\n${BLUE}=== System Scan Complete ===${NC}"
echo -e "${GREEN}All detected hardware has been configured.${NC}"
echo -e "${YELLOW}Please reboot your system to apply all changes (especially Kernel/Microcode updates).${NC}"
