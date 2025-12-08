# ShadowArch

ShadowArch is a **Custom Arch Linux Deployment Framework**.
It allows you to rapidly deploy a fully configured Arch Linux system (Hyprland, Pentesting Tools, Theming) using a simple Git-based workflow.

## 🚀 Installation

You do NOT need to download a custom ISO. You can install ShadowArch directly from the official Arch Linux installation media.

### 1. Boot Arch Linux
Download the official [Arch Linux ISO](https://archlinux.org/download/), flash it to a USB, and boot it.

### 2. Clone & Run
Connect to the internet, then run the following commands:

```bash
# 1. Install Git
pacman -Sy --noconfirm git

# 2. Clone Repo
git clone https://github.com/FNAl3/ShadowArch.git
cd ShadowArch

# 3. Launch Installer
chmod +x install_system.sh
./install_system.sh
```

The script will automatically:
- Download dependencies (python, yaml).
- Fetch assets (Dracula theme, Wallpapers).
- Launch the guided installer.

## ⚙️ Configuration
The installation is driven by `airootfs/root/config.yaml`. You can edit this file before running the script to customize:
- **Packages**: Add/remove tools.
- **Users**: Set username/passwords.
- **Disk**: Select target drive (`/dev/sda`, `/dev/nvme0n1`).

## 🎨 Features
- **Desktop**: Hyprland (Wayland) + Waybar + Wofi.
- **Theme**: Dracula GTK + Custom Wallpaper.
- **Tools**: Pre-configured security tools (Metasploit, Nmap, etc.) via AUR.
- **Audio**: Pipewire setup out-of-the-box.

## 🛠️ Development
To modify the installer, edit `airootfs/root/install_script.py`.
To add new default assets, modify `prepare_assets.sh`.
