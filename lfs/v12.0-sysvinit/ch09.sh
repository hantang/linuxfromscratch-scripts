####################################################
### Part IV. Building the LFS System
####################################################

# ==================================================
## Chapter 9. System Configuration
# ==================================================

# --------------------------------------------------
# 9.2. LFS-Bootscripts-20230728
# LFS-Bootscripts-20230728 (lfs-bootscripts-20230728.tar.xz)
# --------------------------------------------------

# begin_install lfs-bootscripts-20230728 tar.xz
tar -xf lfs-bootscripts-20230728.tar.xz && cd lfs-bootscripts-20230728
make install
cd .. && rm -rf lfs-bootscripts-20230728
# end_install

# --------------------------------------------------
# 9.4. Managing Devices
# --------------------------------------------------

# cat /etc/udev/rules.d/70-persistent-net.rules
# udevadm test /sys/block/hdd
# sed -e 's/"write_cd_rules"/"write_cd_rules mode"/' \
#     -i /etc/udev/rules.d/83-cdrom-symlinks.rules
# udevadm info -a -p /sys/class/video4linux/video0

# cat > /etc/udev/rules.d/83-duplicate_devs.rules << "EOF"

# # Persistent symlinks for webcam and tuner
# KERNEL=="video*", ATTRS{idProduct}=="1910", ATTRS{idVendor}=="0d81", SYMLINK+="webcam"
# KERNEL=="video*", ATTRS{device}=="0x036f",  ATTRS{vendor}=="0x109e", SYMLINK+="tvtuner"

# EOF

# --------------------------------------------------
# 9.5. General Network Configuration
# --------------------------------------------------

cd /etc/sysconfig/
cat > ifconfig.eth0 << "EOF"
ONBOOT=yes
IFACE=eth0
SERVICE=ipv4-static
IP=192.168.1.2
GATEWAY=192.168.1.1
PREFIX=24
BROADCAST=192.168.1.255
EOF

cat > /etc/resolv.conf << "EOF"
# Begin /etc/resolv.conf

# domain <Your Domain Name>
nameserver 8.8.8.8
nameserver 8.8.4.4

# End /etc/resolv.conf
EOF

echo "lfs" > /etc/hostname

cat > /etc/hosts << "EOF"
# Begin /etc/hosts

127.0.0.1 localhost.localdomain localhost
# 127.0.1.1 <FQDN> <HOSTNAME>
# <192.168.1.1> <FQDN> <HOSTNAME> [alias1] [alias2 ...]
::1       localhost ip6-localhost ip6-loopback
ff02::1   ip6-allnodes
ff02::2   ip6-allrouters

# End /etc/hosts
EOF

# --------------------------------------------------
# 9.6. System V Bootscript Usage and Configuration
# --------------------------------------------------

cat > /etc/inittab << "EOF"
# Begin /etc/inittab

id:3:initdefault:

si::sysinit:/etc/rc.d/init.d/rc S

l0:0:wait:/etc/rc.d/init.d/rc 0
l1:S1:wait:/etc/rc.d/init.d/rc 1
l2:2:wait:/etc/rc.d/init.d/rc 2
l3:3:wait:/etc/rc.d/init.d/rc 3
l4:4:wait:/etc/rc.d/init.d/rc 4
l5:5:wait:/etc/rc.d/init.d/rc 5
l6:6:wait:/etc/rc.d/init.d/rc 6

ca:12345:ctrlaltdel:/sbin/shutdown -t1 -a -r now

su:S06:once:/sbin/sulogin
s1:1:respawn:/sbin/sulogin

1:2345:respawn:/sbin/agetty --noclear tty1 9600
2:2345:respawn:/sbin/agetty tty2 9600
3:2345:respawn:/sbin/agetty tty3 9600
4:2345:respawn:/sbin/agetty tty4 9600
5:2345:respawn:/sbin/agetty tty5 9600
6:2345:respawn:/sbin/agetty tty6 9600

# End /etc/inittab
EOF

cat > /etc/sysconfig/clock << "EOF"
# Begin /etc/sysconfig/clock

UTC=1

# Set this to any options you might need to give to hwclock,
# such as machine hardware clock type for Alphas.
CLOCKPARAMS=

# End /etc/sysconfig/clock
EOF

# cat > /etc/sysconfig/console << "EOF"
# # Begin /etc/sysconfig/console
# 
# KEYMAP="pl2"
# FONT="lat2a-16 -m 8859-2"
# 
# # End /etc/sysconfig/console
# EOF

# cat > /etc/sysconfig/console << "EOF"
# # Begin /etc/sysconfig/console
# 
# KEYMAP="de-latin1"
# KEYMAP_CORRECTIONS="euro2"
# FONT="lat0-16 -m 8859-15"
# UNICODE="1"
# 
# # End /etc/sysconfig/console
# EOF

# cat > /etc/sysconfig/console << "EOF"
# # Begin /etc/sysconfig/console
# 
# UNICODE="1"
# KEYMAP="bg_bds-utf8"
# FONT="LatArCyrHeb-16"
# 
# # End /etc/sysconfig/console
# EOF

# cat > /etc/sysconfig/console << "EOF"
# # Begin /etc/sysconfig/console
# 
# UNICODE="1"
# KEYMAP="bg_bds-utf8"
# FONT="cyr-sun16"
# 
# # End /etc/sysconfig/console
# EOF

# cat > /etc/sysconfig/console << "EOF"
# # Begin /etc/sysconfig/console
# 
# UNICODE="1"
# KEYMAP="de-latin1"
# KEYMAP_CORRECTIONS="euro2"
# LEGACY_CHARSET="iso-8859-15"
# FONT="LatArCyrHeb-16 -m 8859-15"
# 
# # End /etc/sysconfig/console
# EOF

# --------------------------------------------------
# 9.7. The Bash Shell Startup Files
# --------------------------------------------------

# locale -a
# LC_ALL=<locale name> locale charmap
# LC_ALL=<locale name> locale language
# LC_ALL=<locale name> locale charmap
# LC_ALL=<locale name> locale int_curr_symbol
# LC_ALL=<locale name> locale int_prefix

cat > /etc/profile << "EOF"
# Begin /etc/profile

export LANG=en_US.UTF-8

# End /etc/profile
EOF

# --------------------------------------------------
# 9.8. Creating the /etc/inputrc File
# --------------------------------------------------

cat > /etc/inputrc << "EOF"
# Begin /etc/inputrc
# Modified by Chris Lynn <roryo@roryo.dynup.net>

# Allow the command prompt to wrap to the next line
set horizontal-scroll-mode Off

# Enable 8-bit input
set meta-flag On
set input-meta On

# Turns off 8th bit stripping
set convert-meta Off

# Keep the 8th bit for display
set output-meta On

# none, visible or audible
set bell-style none

# All of the following map the escape sequence of the value
# contained in the 1st argument to the readline specific functions
"\eOd": backward-word
"\eOc": forward-word

# for linux console
"\e[1~": beginning-of-line
"\e[4~": end-of-line
"\e[5~": beginning-of-history
"\e[6~": end-of-history
"\e[3~": delete-char
"\e[2~": quoted-insert

# for xterm
"\eOH": beginning-of-line
"\eOF": end-of-line

# for Konsole
"\e[H": beginning-of-line
"\e[F": end-of-line

# End /etc/inputrc
EOF

# 9.9. Creating the /etc/shells File
cat > /etc/shells << "EOF"
# Begin /etc/shells

/bin/sh
/bin/bash

# End /etc/shells
EOF
