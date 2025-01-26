#!/bin/bash
set -e

# --------------------------------------------
# Partitioning
# --------------------------------------------
DISK="/dev/nvme0n1"
echo "Wiping ${DISK}..."
sgdisk --zap-all ${DISK}

echo "Creating partitions..."
sgdisk -n 1:0:+4G -t 1:ef00 ${DISK}    # EFI
sgdisk -n 2:0:+32G -t 2:8200 ${DISK}   # Swap
sgdisk -n 3:0:+128G -t 3:8300 ${DISK}  # Root
sgdisk -n 4:0:0 -t 4:8300 ${DISK}      # Home

# --------------------------------------------
# Filesystems
# --------------------------------------------
echo "Formatting partitions..."
mkfs.fat -F32 ${DISK}p1
mkswap ${DISK}p2
mkfs.xfs -f ${DISK}p3
mkfs.xfs -f ${DISK}p4

# --------------------------------------------
# Mounting
# --------------------------------------------
echo "Mounting filesystems..."
mount ${DISK}p3 /mnt/gentoo
mkdir -p /mnt/gentoo/{boot/efi,home}
mount ${DISK}p1 /mnt/gentoo/boot/efi
mount ${DISK}p4 /mnt/gentoo/home
swapon ${DISK}p2

# --------------------------------------------
# Stage3 Installation
# --------------------------------------------
cd /mnt/gentoo
echo "Downloading stage3..."
STAGE3_URL="https://distfiles.gentoo.org/releases/amd64/autobuilds/20250119T170328Z/stage3-amd64-desktop-systemd-20250119T170328Z.tar.xz"
wget ${STAGE3_URL}
tar xpf stage3-*.tar.xz --xattrs-include='*.*' --numeric-owner

# --------------------------------------------
# make.conf Configuration
# --------------------------------------------
cat <<EOF > /mnt/gentoo/etc/portage/make.conf
COMMON_FLAGS="-march=tigerlake -O2 -pipe"
FEATURES="getbinpkg"
EMERGE_DEFAULT_OPTS="--getbinpkg"
GENTOO_MIRRORS="https://distfiles.gentoo.org https://gentoo.osuosl.org/"
BINHOST="https://gentoo.osuosl.org/experimental/amd64/binpkg/default/linux/23.0/x86-64/"

USE="X wayland elogind systemd alsa bluetooth networkmanager wifi nvidia xfs"
ACCEPT_LICENSE="*"
VIDEO_CARDS="intel nvidia"
INPUT_DEVICES="libinput"

L10N="en en-US"
LINGUAS="en en_US"

MAKEOPTS="-j8"
EOF

# --------------------------------------------
# Portage Configuration
# --------------------------------------------
# mkdir -p /mnt/gentoo/etc/portage/repos.conf
# cp /mnt/gentoo/usr/share/portage/config/repos.conf /mnt/gentoo/etc/portage/repos.conf/gentoo.conf
getuto

# --------------------------------------------
# Chroot Preparation
# --------------------------------------------
cp --dereference /etc/resolv.conf /mnt/gentoo/etc/
mount --types proc /proc /mnt/gentoo/proc
mount --rbind /sys /mnt/gentoo/sys
mount --make-rslave /mnt/gentoo/sys
mount --rbind /dev /mnt/gentoo/dev
mount --make-rslave /mnt/gentoo/dev

# --------------------------------------------
# Chroot Script
# --------------------------------------------
cat <<EOF > /mnt/gentoo/chroot.sh
#!/bin/bash
set -e

# Initial setup
source /etc/profile
export PS1="(chroot) \$PS1"

# Portage sync
emerge-webrsync
eselect profile set default/linux/amd64/23.0/desktop/systemd

# Timezone
ln -sf /usr/share/zoneinfo/UTC /etc/localtime

# Locale
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
eselect locale set en_US.utf8

# Update @world
emerge -quN @world

# Kernel (binary)
emerge -q sys-kernel/gentoo-kernel-bin sys-kernel/linux-firmware

# Initramfs
emerge -q sys-kernel/dracut
dracut --kver \$(ls /usr/src/linux | head -n1) --force --add "xfs nvidia systemd" /boot/initramfs-genkernel-amd64-\$(ls /usr/src/linux | head -n1)

# System configuration
echo "gentoo-legion5" > /etc/hostname

# Network
systemctl enable systemd-networkd.service
systemctl enable systemd-resolved.service
systemctl enable NetworkManager.service

# Bluetooth
systemctl enable bluetooth.service

# Sound
systemctl --global enable pipewire.socket
systemctl --global enable pipewire-pulse.socket

# SSD Trim
systemctl enable fstrim.timer

# User setup
useradd -m -G wheel,audio,video,portage,plugdev,usb users
passwd users
echo "%wheel ALL=(ALL:ALL) ALL" >> /etc/sudoers

# NVIDIA Drivers
emerge -q x11-drivers/nvidia-drivers
emerge -q media-libs/libglvnd

# Optimus Manager
emerge -q sys-power/optimus-manager
systemctl enable optimus-manager.service

# Intel microcode
emerge -q sys-firmware/intel-microcode

# KDE Plasma
emerge -q kde-plasma/plasma-meta
emerge -q kde-apps/kde-apps-meta
emerge -q app-admin/sudo sys-apps/udev sys-apps/usbutils

# Display Manager
emerge -q x11-misc/sddm
systemctl enable sddm.service

# Bootloader
emerge -q sys-boot/grub
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=Gentoo
grub-mkconfig -o /boot/grub/grub.cfg

# Update environment
env-update
source /etc/profile

# Cleanup
rm -rf /var/tmp/portage/*
EOF

# --------------------------------------------
# Execute Chroot
# --------------------------------------------
chmod +x /mnt/gentoo/chroot.sh
chroot /mnt/gentoo /chroot.sh

# --------------------------------------------
# Cleanup
# --------------------------------------------
umount -l /mnt/gentoo/dev{/shm,/pts,}
umount -R /mnt/gentoo
swapoff ${DISK}p2

echo "Installation complete! Reboot and remove installation media."
