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
*   **Desktop**: Hyprland (Wayland), Waybar, Wofi, **Foot**.
*   **Theming**: Dracula GTK Theme, Custom Wallpapers, Icons.

...

## ⌨️ Shortcuts (Hyprland)
| Key Combination | Action |
|-----------------|--------|
| `SUPER + Q` | Open Terminal (**Foot**) |
| `SUPER + R` | Open App Launcher (Wofi) |
| `SUPER + C` | Close Active Window |
| `SUPER + M` | Exit Hyprland (Logout) |
| `SUPER + E` | Open File Manager |
| `SUPER + V` | Toggle Floating Window |
| `SUPER + P` | Dwindle: Pseudo Tiling |
| `SUPER + J` | Dwindle: Toggle Split |
| `SUPER + ←/→/↑/↓` | Move Focus |
| `SUPER + 1-9` | Switch Workspace |
| `SUPER + SHIFT + 1-9` | Move Window to Workspace |

