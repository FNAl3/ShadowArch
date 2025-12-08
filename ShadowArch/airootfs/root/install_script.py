#!/usr/bin/env python3
import os
import sys
import yaml
import subprocess
import logging

# Setup logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

def fix_host_keyring():
    logging.info("Fixing host pacman keyring to prevent signature errors...")
    try:
        run_command("pacman-key --init", check=False)
        run_command("pacman-key --populate archlinux", check=False)
        run_command("pacman -Sy --noconfirm archlinux-keyring", check=False)
    except Exception as e:
        logging.warning(f"Keyring fix warning: {e}")

def cleanup_previous_mounts():
    logging.info("Checking for leftover mounts from previous runs...")
    try:
        run_command("umount -R /mnt", check=False)
        run_command("swapoff -a", check=False)
    except:
        pass

def run_command(command, check=True):
    logging.info(f"Running: {command}")
    try:
        subprocess.run(command, shell=True, check=check, executable='/bin/bash')
    except subprocess.CalledProcessError as e:
        logging.error(f"Command failed: {e}")
        if check:
            sys.exit(1)

def setup_mirrors():
    logging.info("Setting up mirrors...")
    if check_internet():
        logging.info("Internet detected. Updating mirrorlist with Reflector...")
        # Update mirrors: latest 20, https, sort by rate
        try:
            run_command("reflector --latest 20 --protocol https --sort rate --save /etc/pacman.d/mirrorlist --download-timeout 5", check=True)
            run_command("pacman -Sy", check=False) # Sync databases
        except:
             logging.warning("Reflector failed. Falling back to existing mirrorlist.")
    else:
        logging.warning("No internet. Skipping mirror update. Installation may fail if mirrors are invalid.")

def check_internet():
    try:
        # Check connection to Google DNS
        subprocess.check_call(["ping", "-c", "1", "8.8.8.8"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        return True
    except subprocess.CalledProcessError:
        return False

def load_config(config_path):
    with open(config_path, 'r') as f:
        return yaml.safe_load(f)

def partition_disk(disk):
    print(f"\n--- Partitioning {disk} ---")
    print("1) Automatic (Erase Disk + Advanced Layout)")
    print("   [EFI: 512MB | SWAP: 4GB | ROOT: 40% | VAR: 15% | TMP: 5% | HOME: Rest (40%)]")
    print("2) Manual (cfdisk)")
    
    choice = input("Select option [1]: ").strip()
    
    if choice == '2':
        # Manual Mode
        run_command(f"cfdisk {disk}", check=False)
        print("\nPlease enter the partition paths you created (Leave empty if not created):")
        efi_part = input("EFI Partition (e.g. /dev/sda1) [Required]: ").strip()
        root_part = input("ROOT Partition (e.g. /dev/sda3) [Required]: ").strip()
        swap_part = input("SWAP Partition (e.g. /dev/sda2): ").strip()
        var_part = input("VAR Partition (e.g. /dev/sda4): ").strip()
        tmp_part = input("TMP Partition (e.g. /dev/sda5): ").strip()
        home_part = input("HOME Partition (e.g. /dev/sda6): ").strip()
        
        if not efi_part or not root_part:
            logging.error("EFI and Root partitions are required!")
            sys.exit(1)
            
        return efi_part, swap_part, root_part, var_part, tmp_part, home_part
    else:
        # Automatic Mode
        logging.info("Wiping and partitioning automatically...")
        run_command(f"wipefs -a {disk}")
        run_command(f"parted -s {disk} mklabel gpt")
        
        # 1. EFI (512MB)
        run_command(f"parted -s {disk} mkpart ESP fat32 1MiB 513MiB")
        run_command(f"parted -s {disk} set 1 boot on")
        
        # 2. SWAP (4GB) -> 513 + 4096 = 4609
        run_command(f"parted -s {disk} mkpart primary linux-swap 513MiB 4609MiB")
        
        # 3. ROOT (Until 40%)
        run_command(f"parted -s {disk} mkpart primary ext4 4609MiB 40%")
        
        # 4. VAR (40% -> 55%)
        run_command(f"parted -s {disk} mkpart primary ext4 40% 55%")

        # 5. TMP (55% -> 60%)
        run_command(f"parted -s {disk} mkpart primary ext4 55% 60%")

        # 6. HOME (60% -> 100%)
        run_command(f"parted -s {disk} mkpart primary ext4 60% 100%")
        
        # Determine names
        p_prefix = f"{disk}p" if "nvme" in disk else f"{disk}"
        return f"{p_prefix}1", f"{p_prefix}2", f"{p_prefix}3", f"{p_prefix}4", f"{p_prefix}5", f"{p_prefix}6"

def format_partitions(efi_part, swap_part, root_part, var_part, tmp_part, home_part):
    logging.info("Formatting partitions...")
    
    run_command(f"mkfs.fat -F32 {efi_part}")
    run_command(f"mkfs.ext4 -F {root_part}")
    
    if swap_part: run_command(f"mkswap {swap_part}")
    if var_part:  run_command(f"mkfs.ext4 -F {var_part}")
    if tmp_part:  run_command(f"mkfs.ext4 -F {tmp_part}")
    if home_part: run_command(f"mkfs.ext4 -F {home_part}")

def mount_partitions(root_part, efi_part, swap_part, var_part, tmp_part, home_part):
    logging.info("Mounting partitions...")
    # Mount Root first
    run_command(f"mount {root_part} /mnt")
    
    # Create mountpoints
    run_command(f"mkdir -p /mnt/boot")
    run_command(f"mount {efi_part} /mnt/boot")
    
    if var_part:
        run_command(f"mkdir -p /mnt/var")
        run_command(f"mount {var_part} /mnt/var")
        
    if tmp_part:
        run_command(f"mkdir -p /mnt/tmp")
        run_command(f"mount {tmp_part} /mnt/tmp")
        
    if home_part:
        run_command(f"mkdir -p /mnt/home")
        run_command(f"mount {home_part} /mnt/home")
    
    if swap_part:
        run_command(f"swapon {swap_part}")

def install_in_chunks(packages, chunk_size=50):
    total = len(packages)
    for i in range(0, total, chunk_size):
        chunk = packages[i:i + chunk_size]
        logging.info(f"Installing chunk {i//chunk_size + 1} ({len(chunk)} packages)...")
        pkg_list = " ".join(chunk)
        # Using the cache bind mount ensures we don't fill RAM
        run_command(f"pacstrap /mnt {pkg_list}")

def install_base(packages):
    logging.info("Installing system in chunks to save RAM...")
    
    # Separation of concerns: Core vs Extra
    core_packages = ['base', 'linux', 'linux-firmware']
    extra_packages = [p for p in packages if p not in core_packages]
    
    # 1. Install Core first (Essential for boot)
    logging.info("Installing Core packages (Base/Kernel)...")
    run_command(f"pacstrap /mnt {' '.join(core_packages)}")
    
    # 2. Install Extras in chunks
    if extra_packages:
        install_in_chunks(extra_packages)

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
    
    keymap = config.get('keymap', 'us')
    
    # PATH RESOLUTION
    SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__)) # airootfs/root/
    REPO_ROOT = os.path.dirname(os.path.dirname(SCRIPT_DIR)) # ShadowArch/

    # 1. Copy Dotfiles (Skel) - Lightweight, keep local
    logging.info("Copying custom dotfiles...")
    skel_source = os.path.join(os.path.dirname(SCRIPT_DIR), 'etc', 'skel') # airootfs/etc/skel
    if os.path.exists(skel_source):
        run_command(f"cp -r {skel_source}/. /mnt/etc/skel/")
        run_command(f"cp -r {skel_source}/. /mnt/root/") # Also for root
    
    # 2. Setup Directories
    run_command("mkdir -p /mnt/usr/share/themes")
    run_command("mkdir -p /mnt/usr/share/backgrounds")
    run_command("mkdir -p /mnt/opt/PenTools")

    # 3. Download Assets (Direct to Disk to save RAM)
    logging.info("Downloading Assets directly to Target Disk...")
    
    # Theme: Dracula
    if check_internet():
        logging.info("Downloading Dracula Theme...")
        try:
             # Download zip to /mnt/tmp to avoid RAM
             run_command("mkdir -p /mnt/tmp_dl")
             run_command("curl -L -o /mnt/tmp_dl/theme.zip https://github.com/dracula/gtk/archive/master.zip", check=False)
             run_command("unzip -o /mnt/tmp_dl/theme.zip -d /mnt/usr/share/themes", check=False)
             run_command("mv /mnt/usr/share/themes/gtk-master /mnt/usr/share/themes/Dracula", check=False)
             run_command("rm -rf /mnt/tmp_dl")
        except:
             logging.warning("Failed to download theme.")

        logging.info("Cloning PenTools...")
        try:
            run_command("git clone --depth 1 https://github.com/FNAl3/PenTools /mnt/opt/PenTools", check=False)
            run_command("chmod +x /mnt/opt/PenTools/*.py", check=False)
            run_command("chmod +x /mnt/opt/PenTools/*.sh", check=False)
        except:
            logging.warning("Failed to clone PenTools.")
    else:
        logging.warning("No internet. Skipping asset downloads.")

    # 4. Wallpaper (Local in Repo)
    logo_path = os.path.join(REPO_ROOT, "logo.png")
    if os.path.exists(logo_path):
        run_command(f"cp {logo_path} /mnt/usr/share/backgrounds/shadowk.png")
    else:
         # Fallback to looking in airootfs if prepare_assets ran (backwards compat)
         bg_source = os.path.join(os.path.dirname(SCRIPT_DIR), 'usr', 'share', 'backgrounds', 'shadowk.png')
         if os.path.exists(bg_source):
            run_command(f"cp {bg_source} /mnt/usr/share/backgrounds/shadowk.png")

    # Deploy Post-Install Wizard
    logging.info("Deploying Shadow Wizard...")
    wizard_source = os.path.join(SCRIPT_DIR, 'shadow_wizard.sh')
    if os.path.exists(wizard_source):
        run_command(f"cp {wizard_source} /mnt/usr/local/bin/shadow-wizard")
        run_command("chmod +x /mnt/usr/local/bin/shadow-wizard")
    else:
        logging.warning(f"Shadow Wizard not found at {wizard_source}")

    import textwrap
    setup_script = textwrap.dedent(f"""\
#!/bin/bash
ln -sf /usr/share/zoneinfo/{timezone} /etc/localtime
hwclock --systohc
echo "{locale} UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG={locale}" > /etc/locale.conf
echo "KEYMAP={keymap}" > /etc/vconsole.conf
echo "{hostname}" > /etc/hostname

# Configure mkinitcpio
cat <<EOF > /etc/mkinitcpio.conf
MODULES=()
BINARIES=()
FILES=()
HOOKS=(base udev autodetect modconf kms keyboard keymap consolefont block filesystems fsck)
EOF

# Initialize Pacman Keys
echo "Initializing Pacman Keys..."
pacman-key --init
pacman-key --populate archlinux
pacman -Sy --noconfirm archlinux-keyring

# Root password
echo "root:{root_password}" | chpasswd

# User creation
useradd -m -G wheel -s /bin/bash {username}
echo "{username}:{password}" | chpasswd
echo "%wheel ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# Bootloader (GRUB)
pacman -S --noconfirm grub efibootmgr
mkinitcpio -P
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

# AUR Tools Installation
if ping -c 1 8.8.8.8 &> /dev/null; then
    echo "Internet detected. Installing AUR tools..."
    pacman -S --noconfirm git base-devel
    su - {username} <<SUBEOF
    if [ ! -d "yay" ]; then
        git clone https://aur.archlinux.org/yay.git
        cd yay
        makepkg -si --noconfirm
        cd ..
        rm -rf yay
    fi
    echo "Installing Security Tools from AUR..."
    yay -S --noconfirm metasploit dnsenum2 wafw00f responder ffuf
SUBEOF
fi

# Enable services
systemctl enable NetworkManager
systemctl enable sddm
systemctl enable sshd
systemctl enable httpd
""")
    with open('/mnt/setup.sh', 'w') as f:
        f.write(setup_script)
    
    run_command("chmod +x /mnt/setup.sh")
    run_command("arch-chroot /mnt /setup.sh")
    run_command("rm /mnt/setup.sh")

def get_input(prompt, default):
    response = input(f"{prompt} [{default}]: ").strip()
    return response if response else default

def confirm_action(prompt):
    response = input(f"{prompt} (y/N): ").strip().lower()
    return response == 'y'

def main():
    if len(sys.argv) != 2:
        print("Usage: ./install_script.py <config_file>")
        sys.exit(1)
        
    config_file = sys.argv[1]
    if not os.path.exists(config_file):
        print(f"Config file {config_file} not found.")
        sys.exit(1)
        
    config = load_config(config_file)
    
    print("\n--- Interactive Configuration ---")
    config['hostname'] = get_input("Hostname", config.get('hostname', 'archlinux'))
    config['username'] = get_input("Username", config.get('username', 'user'))
    config['password'] = get_input("User Password", config.get('password', 'password'))
    config['root_password'] = get_input("Root Password", config.get('root_password', 'root'))
    config['disk'] = get_input("Target Disk", config.get('disk', '/dev/sda'))
    
    print("\n---------------------------------")
    print(f"Target Disk: {config['disk']}")
    print(f"Hostname:    {config['hostname']}")
    print(f"Username:    {config['username']}")
    print("---------------------------------")
    
    if not confirm_action("WARNING: ALL DATA ON TARGET DISK WILL BE ERASED. Continue?"):
        print("Aborting installation.")
        sys.exit(1)
    
    disk = config.get('disk')
    efi_part, swap_part, root_part, var_part, tmp_part, home_part = partition_disk(disk)
    format_partitions(efi_part, swap_part, root_part, var_part, tmp_part, home_part)
    mount_partitions(root_part, efi_part, swap_part, var_part, tmp_part, home_part)
    
    packages = config.get('packages', [])
    essentials = ['vim', 'networkmanager', 'sudo', 'os-prober']
    for p in essentials:
        if p not in packages:
            packages.append(p)
            
    logging.info("Binding pacman cache to target disk...")
    run_command("mkdir -p /mnt/var/cache/pacman/pkg")
    run_command("mkdir -p /var/cache/pacman/pkg")
    run_command("mount --bind /mnt/var/cache/pacman/pkg /var/cache/pacman/pkg")


    fix_host_keyring()
    setup_mirrors()

    packages = [p if p != 'neofetch' else 'fastfetch' for p in packages]

    logging.info("Pre-creating system configs for mkinitcpio hooks...")
    run_command("mkdir -p /mnt/etc")
    run_command(f"echo 'KEYMAP={config.get('keymap', 'us')}' > /mnt/etc/vconsole.conf")

    try:
        install_base(packages)
    finally:
        run_command("umount /var/cache/pacman/pkg")

    generate_fstab()
    configure_system(config)
    
    logging.info("Installation complete! You can now reboot.")

if __name__ == "__main__":
    main()
