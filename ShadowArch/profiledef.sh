iso_name="shadowk"
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
)
