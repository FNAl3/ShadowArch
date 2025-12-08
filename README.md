# ShadowArch 🚀

**ShadowArch** is a simplified, Git-based installer for Arch Linux.
It deploys a fully configured system (Hyprland, Waybar, Pentesting Tools, Dracula Theme) directly from the official Arch Linux ISO.

---

## 📥 Installation

**Prerequisites:**
- Official [Arch Linux ISO](https://archlinux.org/download/) (flashed to USB).
- Functional Internet Connection.

### Step 1: Boot & Prepare
Boot into the Arch Linux Live ISO. Connect to Wi-Fi (`iwctl`) or Ethernet.

### Step 2: Clone & Run
Run the following commands strictly in order:

```bash
# 1. Update pkglist and install Git
pacman -Sy --noconfirm git

# 2. Clone the Repository
git clone https://github.com/FNAl3/ShadowArch.git

# 3. Enter directory and Run
cd ShadowArch
chmod +x install_system.sh
./install_system.sh
```

### Step 3: Interactive Setup
The script will launch and ask you for:
1.  **Hostname, User, Password**: Confirm or edit defaults.
2.  **Target Disk**: Select your drive (e.g., `/dev/sda`).
3.  **Partitioning Mode**:
    - **1) Automatic**: Warning! This **ERASES THE WHOLE DISK**. It creates a standardized Partition Layout (EFI, Swap, Root, Home). **Recommended**.
    - **2) Manual**: Launches `cfdisk` for custom layouts.

---

## 🎨 What you get
*   **Base System**: Arch Linux Kernel, Firmware, Base-devel.
*   **Desktop**: Hyprland (Wayland), Waybar, Wofi, Kitty.
*   **Theming**: Dracula GTK Theme, Custom Wallpapers, Icons.
*   **Tools**: Metasploit, Nmap, BurpSuite (via AUR/PenTools) - *Downloading directly to disk*.
*   **Audio**: Pipewire + Wireplumber.

## ⚙️ Customization
Before running the script, you can edit `airootfs/root/config.yaml` to change:
*   Default Package List.
*   Username / Passwords.
*   Timezone / Locale.

## ⚠️ Troubleshooting
*   **"No space left on device"**: This is fixed. The script now downloads generic assets directly to your target partition, bypassing RAM limits.
*   **"Signature errors"**: The script automatically refreshes Arch Keyrings before starting.
*   **VirtualBox Users**: Ensure **3D Acceleration** is ENABLED in your VM Display settings. Hyprland requires this to boot effectively.
