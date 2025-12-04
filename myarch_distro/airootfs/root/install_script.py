#!/usr/bin/env python3
import os
import sys
import yaml
import subprocess
import logging

# Setup logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

def run_command(command, check=True):
    logging.info(f"Running: {command}")
    try:
        subprocess.run(command, shell=True, check=check, executable='/bin/bash')
    except subprocess.CalledProcessError as e:
        logging.error(f"Command failed: {e}")
        sys.exit(1)

def load_config(config_path):
    with open(config_path, 'r') as f:
        return yaml.safe_load(f)

def partition_disk(disk):
    logging.info(f"Partitioning {disk}...")
    # Wipe disk
    run_command(f"wipefs -a {disk}")
    
    # Create GPT partition table
    run_command(f"parted -s {disk} mklabel gpt")
    
    # Create EFI partition (512MB)
    run_command(f"parted -s {disk} mkpart ESP fat32 1MiB 513MiB")
    run_command(f"parted -s {disk} set 1 boot on")
    
    # Create Root partition (Rest)
    run_command(f"parted -s {disk} mkpart primary ext4 513MiB 100%")

def format_partitions(disk):
    logging.info("Formatting partitions...")
    # Assuming standard naming convention (might vary for nvme)
    p1 = f"{disk}1"
    p2 = f"{disk}2"
    if "nvme" in disk:
        p1 = f"{disk}p1"
        p2 = f"{disk}p2"
        
    run_command(f"mkfs.fat -F32 {p1}")
    run_command(f"mkfs.ext4 -F {p2}")
    
    return p1, p2

def mount_partitions(root_part, efi_part):
    logging.info("Mounting partitions...")
    run_command(f"mount {root_part} /mnt")
    run_command(f"mkdir -p /mnt/boot")
    run_command(f"mount {efi_part} /mnt/boot")

def install_base(packages):
    logging.info("Installing base system...")
    pkg_list = " ".join(packages)
    run_command(f"pacstrap /mnt base linux linux-firmware {pkg_list}")

def generate_fstab():
    logging.info("Generating fstab...")
    run_command("genfstab -U /mnt >> /mnt/etc/fstab")

def configure_system(config):
    logging.info("Configuring system...")
    
    hostname = config.get('hostname', 'archlinux')
    timezone = config.get('timezone', 'UTC')
    locale = config.get('locale', 'en_US.UTF-8')
    username = config.get('username', 'user')
    password = config.get('password', 'password')
    root_password = config.get('root_password', 'root')
    
    # Write configuration script to be run inside chroot
    setup_script = f"""
#!/bin/bash
ln -sf /usr/share/zoneinfo/{timezone} /etc/localtime
hwclock --systohc
echo "{locale} UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG={locale}" > /etc/locale.conf
echo "{hostname}" > /etc/hostname

# Root password
echo "root:{root_password}" | chpasswd

# User creation
useradd -m -G wheel -s /bin/bash {username}
echo "{username}:{password}" | chpasswd
echo "%wheel ALL=(ALL) ALL" >> /etc/sudoers

# Bootloader (GRUB)
pacman -S --noconfirm grub efibootmgr
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

# Enable services
systemctl enable NetworkManager
"""
    with open('/mnt/setup.sh', 'w') as f:
        f.write(setup_script)
    
    run_command("chmod +x /mnt/setup.sh")
    run_command("arch-chroot /mnt /setup.sh")
    run_command("rm /mnt/setup.sh")

def main():
    if len(sys.argv) != 2:
        print("Usage: ./install_script.py <config_file>")
        sys.exit(1)
        
    config_file = sys.argv[1]
    if not os.path.exists(config_file):
        print(f"Config file {config_file} not found.")
        sys.exit(1)
        
    config = load_config(config_file)
    
    disk = config.get('disk')
    if not disk:
        print("Disk not specified in config.")
        sys.exit(1)
        
    partition_disk(disk)
    efi_part, root_part = format_partitions(disk)
    mount_partitions(root_part, efi_part)
    
    packages = config.get('packages', [])
    # Add essential packages if not present
    essentials = ['vim', 'networkmanager', 'sudo']
    for p in essentials:
        if p not in packages:
            packages.append(p)
            
    install_base(packages)
    generate_fstab()
    configure_system(config)
    
    logging.info("Installation complete! You can now reboot.")

if __name__ == "__main__":
    main()
