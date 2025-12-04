# MyArchSec Custom Pentest Distro

This is a custom Arch Linux distribution configuration built with `archiso`, designed for pentesting and forensics. It includes a custom installation script and tools for security auditing.

## Prerequisites

To build this ISO, you need:
- An Arch Linux system (or a VM).
- The `archiso` package installed (`sudo pacman -S archiso`).
- Root privileges.

## Directory Structure

- `packages.x86_64`: List of packages to include (Base + Security Tools).
- `profiledef.sh`: ISO definition (MyArchSec).
- `airootfs/`: Files to be overlaid on the live system.
  - `root/install_script.py`: The custom installation script.
  - `root/install_blackarch.sh`: Script to install BlackArch repository.
  - `root/config_example.yaml`: Example configuration file.

## How to Build

1. Copy this directory to your Arch Linux machine.
2. Run the following command from within this directory:

```bash
sudo mkarchiso -v -w /tmp/archiso-work -o out .
```

3. The resulting ISO will be in the `out/` directory.

## How to Install

1. Boot the ISO on the target machine.
2. Login as `root` (no password by default on live media).
3. Edit the configuration file `/root/config_example.yaml` with your desired settings.
4. Run the installation script:

```bash
python /root/install_script.py /root/config_example.yaml
```

## Post-Installation (BlackArch)

To access thousands of additional security tools, run the BlackArch installation script inside the live environment or after installation:

```bash
/root/install_blackarch.sh
```
