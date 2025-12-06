iso_name="shadowArch"
iso_label="SHADOWARCH_2025"
iso_publisher="ShadowK-025 <https://github.com/ArchShadow>"
iso_application="ShadowArch 025 Live ISO"

iso_version="$(date +%Y.%m.%d)"
install_dir="arch"
buildmodes=('iso')
bootmodes=('bios.syslinux' 'uefi.grub')
arch="x86_64"
pacman_conf="pacman.conf"
airootfs_image_type="squashfs"
airootfs_image_tool_options=('-comp' 'xz' '-Xbcj' 'x86' '-b' '1M' '-Xdict-size' '1M')
file_permissions=(
  ["/root"]="0:0:750"
  ["/root/install_blackarch.sh"]="0:0:755"
  ["/root/install_script.py"]="0:0:755"
  ["/etc/shadow"]="0:0:400"
  ["/etc/gshadow"]="0:0:400"
  ["/etc/passwd"]="0:0:644"
  ["/etc/group"]="0:0:644"
  ["/etc/mkinitcpio.conf"]="0:0:644"
  ["/etc/vconsole.conf"]="0:0:644"
  ["/etc/locale.conf"]="0:0:644"
  ["/etc/hostname"]="0:0:644"
  ["/etc/hosts"]="0:0:644"
)
