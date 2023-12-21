########################################################################
### Part IV. Building the LFS System
########################################################################

# ======================================================================
## Chapter 10. Making the LFS System Bootable
# ======================================================================

# ----------------------------------------------------------------------
# 10.2. Creating the /etc/fstab File
# ----------------------------------------------------------------------

cat > /etc/fstab << "EOF"
# Begin /etc/fstab

# file system  mount-point  type     options             dump  fsck
#                                                              order

/dev/<xxx>     /            <fff>    defaults            1     1
/dev/<yyy>     swap         swap     pri=1               0     0

# End /etc/fstab
EOF

hdparm -I /dev/sda | grep NCQ

# ----------------------------------------------------------------------
# 10.3. Linux-6.4.12
# Linux-6.4.12 (linux-6.4.12.tar.xz)
# ----------------------------------------------------------------------

begin_install linux-6.4.12 tar.xz
# tar -xf linux-6.4.12.tar.xz && cd linux-6.4.12

make mrproper
make menuconfig
make
make modules_install

## admon caution
# mount /boot
cp -iv arch/x86/boot/bzImage /boot/vmlinuz-6.4.12-lfs-12.0-systemd
cp -iv System.map /boot/System.map-6.4.12
cp -iv .config /boot/config-6.4.12
cp -r Documentation -T /usr/share/doc/linux-6.4.12
install -v -m755 -d /etc/modprobe.d
cat > /etc/modprobe.d/usb.conf << "EOF"
# Begin /etc/modprobe.d/usb.conf

install ohci_hcd /sbin/modprobe ehci_hcd ; /sbin/modprobe -i ohci_hcd ; true
install uhci_hcd /sbin/modprobe ehci_hcd ; /sbin/modprobe -i uhci_hcd ; true

# End /etc/modprobe.d/usb.conf
EOF

# cd .. && rm -rf linux-6.4.12
end_install

# ----------------------------------------------------------------------
# 10.4. Using GRUB to Set Up the Boot Process
# ----------------------------------------------------------------------

# cd /tmp
# grub-mkrescue --output=grub-img.iso
# xorriso -as cdrecord -v dev=/dev/cdrw blank=as_needed grub-img.iso

grub-install /dev/sda

cat > /boot/grub/grub.cfg << "EOF"
# Begin /boot/grub/grub.cfg
set default=0
set timeout=5

insmod part_gpt
insmod ext2
set root=(hd0,2)

menuentry "GNU/Linux, Linux 6.4.12-lfs-12.0-systemd" {
        linux   /boot/vmlinuz-6.4.12-lfs-12.0-systemd root=/dev/sda2 ro
}
EOF
