# ShadowK 025
![ShadowK Logo](logo.png)

**ShadowK 025** is a custom Arch Linux distribution designed for **Security Auditing, Pentesting, and Forensics**. It combines the raw power of Arch Linux with a pre-configured, beautiful **Cyberpunk/Purple** aesthetic (Hyprland) and a complete arsenal of security tools (Kali-Parity + Custom PenTools).

---

## 🚀 Features

*   **🛡️ Complete Arsenal**: Includes Metasploit, Burp Suite, Hydra, Sqlmap, Wireshark, and more out of the box.
*   **🔧 Custom Tools**: Automatically integrates [PenTools](https://github.com/FNAl3/PenTools) for advanced enumeration and attacks.
*   **🎨 Cyberpunk Aesthetic**:
    *   **Window Manager**: Hyprland (Wayland) with animations and blur.
    *   **Theme**: Dracula (GTK) & Cyberpunk Neon colors.
    *   **Look**: Custom "Kama" Boot Splash and Login Screen.
*   **🎧 Functional Audio**: Pipewire + WirePlumber + SOF Firmware (supports modern laptops).
*   **🔌 Enhanced Connectivity**:
    *   **SSH Server (`sshd`)**: Enabled by default.
    *   **Web Server (`httpd`)**: Apache pre-installed and enabled.
*   **⚡ Interactive Installer**: Custom Python script (`install_script.py`) to install the OS in minutes without manual commands.

---

## � Build System Infrastructure

This project uses a custom engineered build system to overcome the limitations of building large ISOs within a Live RAM environment.

### 🏗️ The Architecture
The build process is split into three intelligent layers to ensure stability and memory management:

#### 1. The Orchestrator (`build.sh`)
This is the main entry point. It features **Automatic Self-Relocation** logic:
*   **Detection**: It checks if it is running in RAM (Live ISO) or on Persistent Storage.
*   **Migration**: If in RAM, it triggers `setup_workspace.sh`.
*   **Handover**: Once set up, it automatically `exec`s the version of itself located on the hard drive.
*   **Cache Management**: It creates a local pacman cache on the disk and **bind-mounts** it to `/var/cache/pacman/pkg`, preventing RAM exhaustion during large downloads.

#### 2. The Persistence Manager (`setup_workspace.sh`)
Handles the physical storage preparation:
*   **Wipes** the target disk (`/dev/sda`).
*   **Partitions** it (GPT, 100% space).
*   **Formats** as EXT4 and mounts to `/mnt/build_workspace`.
*   **Clones** the entire project repository (including hidden `.git` files) to the new workspace.

#### 3. The Builder (`mkarchiso`)
Runs inside the persistent workspace context (`-w` work directory forced to disk), ensuring that the temporary build artifacts (which can exceed 10GB) never touch the RAM.

---

## 📂 Source Code Structure
| File / Folder | Purpose |
| :--- | :--- |
| **`profiledef.sh`** | **The Identity**. Defines the ISO name (`shadowk`), version, and file permissions. |
| **`packages.x86_64`** | **The Arsenal**. List of all packages to be installed (Kernel, Hyprland, Security Tools). |
| **`prepare_iso.sh`** | **The Chef**. Downloads external assets (Dracula Theme, PenTools code) before building. |
| **`syslinux/`** | **The Bootloader**. Contains the boot menu configuration and the custom **boot logo** (`kama_shadowarch.png`). |
| **`airootfs/`** | **The File System**. Files here are overlayed onto the OS. |
| `└── root/install_script.py` | **The Installer**. Interactive script to partition disks and install the system. |

---

## � Disk Partition Structure

The `install_script.py` automatically handles disk partitioning. It enforces a **UEFI/GPT** layout:

| Partition | Filesystem | Size | Description |
| :--- | :--- | :--- | :--- |
| **ESP** (EFI) | FAT32 | 512 MB | Bootloader (GRUB) and EFI executables. |
| **Swap** | Swap | 4 GB | Virtual memory. |
| **Root** (/) | EXT4 | **40%** | System binaries, /usr, /opt. |
| **Var** (/var) | EXT4 | **15%** | Logs, Pacman Cache, Databases. |
| **Tmp** (/tmp) | EXT4 | **5%** | Temporary files. |
| **Home** (/home) | EXT4 | Remainder | User data (~40%). |

> [!WARNING]
> The installer **wipes the entire target disk**. It does not support dual-boot or manual partitioning in this version.

---

## 🛠️ How to Build (Create the ISO)

You can build ShadowK from a standard Arch Linux install OR from a Live ISO.

### Option A: From a Live ISO (Recommended for Testing)
*If you are in a temporary VM or USB Live Session:*

1.  **Update Databases & Install Tools**:
    *Crucial step to avoid "package not found" errors.*
    ```bash
    pacman -Sy archiso git curl
    ```

2.  **Clone the Repository**:
    ```bash
    git clone https://github.com/FNAl3/ShadowArch.git
    cd ShadowArch
    ```

3.  **Run the One-Click Builder**:
    *This will automatically partition your disk (if blank), move the workspace to persistent storage, and compile the ISO.*
    ```bash
    chmod +x build.sh
    ./build.sh
    ```

✅ **Result:** Your ISO will be located in `/mnt/build_workspace/out/`.

### Option B: From an Existing Arch System
*If you already have Arch Linux installed on your machine:*

1.  **Install Prerequisites**:
    ```bash
    sudo pacman -S archiso git curl unzip
    ```

2.  **Get the Code**:
    ```bash
    git clone https://github.com/FNAl3/ShadowArch.git
    cd ShadowArch
    ```

3.  **Build**:
    We recommend using our automated wrapper to handle caching:
    ```bash
    chmod +x build.sh
    ./build.sh
    ```
    *(Alternatively, you can run `mkarchiso -v -w work -o out .` manually).*

### 4. Locate ISO
The final `.iso` file will be in the `out/` directory (or `/mnt/build_workspace/out` if using Option A).

---

## 🧪 Deployment / Boot Scenarios

### 🖥️ VirtualBox (Standard Testing)
1. **Create VM**: New > Type: Linux > Version: Arch Linux (64-bit).
2. **Resources**:
    *   **RAM**: Minimum 4GB (8GB Recommended).
    *   **CPU**: 2 Cores.
    *   **Video Memory**: 128MB + Enable 3D Acceleration.
3. **Settings**: Go to System > Motherboard > **Enable EFI** (Required for Hyprland).
4. **Boot**: Mount the generated ISO (from `out/shadowk-....iso`) and start.

### 🔌 Live USB (Real Hardware)
1. **Flash**: Write the ISO to a USB stick using **Etcher** or **Rufus** (Select **DD Mode** if asked).
2. **BIOS/UEFI**:
    *   Disable **Secure Boot**.
    *   Set Boot Priority to USB.
3. **Boot**: Select ShadowArch from the boot menu.

---

## 💾 How to Install (Target Machine)

1.  **Boot**: Insert the USB and boot. You will see the **ShadowK Boot Menu** (with the Kama Logo).
2.  **Login**: Use user `root`. No password is required for the Live environment.
3.  **Install**:
    Run the text-based installer directly (it has executable permissions):
    ```bash
    ./install_script.py /root/config_example.yaml
    ```
4.  **Configure**:
    The script will ask for:
    *   **Hostname**: Name of the machine (e.g., `ShadowBox`).
    *   **User/Pass**: Your new user credentials.
    *   **Disk**: Which drive to erase and install to (default `/dev/sda`).

5.  **Reboot**: Remove the USB and restart. You will be greeted by SDDM and the Hyprland desktop.

---

## ⌨️ Keybindings (Hyprland)

| Key | Action |
| :--- | :--- |
| `Super + Q` | Open Terminal (Kitty) |
| `Super + C` | Kill Window |
| `Super + M` | Exit Hyprland (Logout) |
| `Super + E` | File Manager (Dolphin/Thunar) |
| `Super + V` | Toggle Floating |
| `Super + Space` | App Launcher (Wofi) |

---
