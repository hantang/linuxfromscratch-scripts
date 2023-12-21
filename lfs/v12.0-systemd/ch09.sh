####################################################
### Part IV. Building the LFS System
####################################################

# ==================================================
## Chapter 9. System Configuration
# ==================================================

# --------------------------------------------------
# 9.2. General Network Configuration
# --------------------------------------------------

# systemctl disable systemd-networkd-wait-online
# ln -s /dev/null /etc/systemd/network/99-default.link

# cat > /etc/systemd/network/10-ether0.link << "EOF"
# [Match]
# # Change the MAC address as appropriate for your network device
# MACAddress=12:34:45:78:90:AB
# 
# [Link]
# Name=ether0
# EOF

cat > /etc/systemd/network/10-eth-static.network << "EOF"
[Match]
Name=*

[Network]
Address=192.168.0.2/24
Gateway=192.168.0.1
DNS=192.168.0.1
Domains=*
EOF

cat > /etc/systemd/network/10-eth-dhcp.network << "EOF"
[Match]
Name=*

[Network]
DHCP=ipv4

[DHCPv4]
UseDomains=true
EOF

# systemctl disable systemd-resolved

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
# <192.168.0.2> <FQDN> <HOSTNAME> [alias1] [alias2] ...
::1       localhost ip6-localhost ip6-loopback
ff02::1   ip6-allnodes
ff02::2   ip6-allrouters

# End /etc/hosts
EOF

# --------------------------------------------------
# 9.4. Managing Devices
# --------------------------------------------------

# udevadm info -a -p /sys/class/video4linux/video0

# cat > /etc/udev/rules.d/83-duplicate_devs.rules << "EOF"

# # Persistent symlinks for webcam and tuner
# KERNEL=="video*", ATTRS{idProduct}=="1910", ATTRS{idVendor}=="0d81", SYMLINK+="webcam"
# KERNEL=="video*", ATTRS{device}=="0x036f",  ATTRS{vendor}=="0x109e", SYMLINK+="tvtuner"

# EOF

# --------------------------------------------------
# 9.5. Configuring the system clock
# --------------------------------------------------

cat > /etc/adjtime << "EOF"
0.0 0 0.0
0
LOCAL
EOF

# timedatectl set-local-rtc 1
# timedatectl set-time YYYY-MM-DD HH:MM:SS
# timedatectl set-timezone TIMEZONE
# timedatectl list-timezones
# systemctl disable systemd-timesyncd

# --------------------------------------------------
# 9.6. Configuring the Linux Console
# --------------------------------------------------

# cat > /etc/vconsole.conf << "EOF"
# KEYMAP=de-latin1
# FONT=Lat2-Terminus16
# EOF

# localectl set-keymap MAP
# localectl set-x11-keymap LAYOUT [MODEL] [VARIANT] [OPTIONS]

# --------------------------------------------------
# 9.7. Configuring the System Locale
# --------------------------------------------------

# locale -a
# LC_ALL=<locale name> locale charmap
# LC_ALL=<locale name> locale language
# LC_ALL=<locale name> locale charmap
# LC_ALL=<locale name> locale int_curr_symbol
# LC_ALL=<locale name> locale int_prefix

cat > /etc/locale.conf << "EOF"
LANG=en_US.UTF-8
EOF

# localectl set-locale LANG="<ll>_<CC>.<charmap><@modifiers>"
# localectl set-locale LANG="en_US.UTF-8" LC_CTYPE="en_US"

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


# --------------------------------------------------
# 9.10. Systemd Usage and Configuration
# --------------------------------------------------

# mkdir -pv /etc/systemd/system/getty@tty1.service.d

# cat > /etc/systemd/system/getty@tty1.service.d/noclear.conf << EOF
# [Service]
# TTYVTDisallocate=no
# EOF

# ln -sfv /dev/null /etc/systemd/system/tmp.mount
# mkdir -p /etc/tmpfiles.d
# cp /usr/lib/tmpfiles.d/tmp.conf /etc/tmpfiles.d
# mkdir -pv /etc/systemd/system/foobar.service.d

# cat > /etc/systemd/system/foobar.service.d/foobar.conf << EOF
# [Service]
# Restart=always
# RestartSec=30
# EOF

# mkdir -pv /etc/systemd/coredump.conf.d

# cat > /etc/systemd/coredump.conf.d/maxuse.conf << EOF
# [Coredump]
# MaxUse=5G
# EOF
