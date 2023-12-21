####################################################
### Part IV. Building the LFS System
####################################################

# ==================================================
## Chapter 11. The End
# ==================================================

# --------------------------------------------------
# 11.1. The End
# --------------------------------------------------

# echo 12.0-systemd > /etc/lfs-release

# cat > /etc/lsb-release << "EOF"
# DISTRIB_ID="Linux From Scratch"
# DISTRIB_RELEASE="12.0-systemd"
# DISTRIB_CODENAME="<your name here>"
# DISTRIB_DESCRIPTION="Linux From Scratch"
# EOF

# cat > /etc/os-release << "EOF"
# NAME="Linux From Scratch"
# VERSION="12.0-systemd"
# ID=lfs
# PRETTY_NAME="Linux From Scratch 12.0-systemd"
# VERSION_CODENAME="<your name here>"
# EOF

linux_dist="Linux From Scratch"
linux_dist_short="lfs"
linux_version="12.0-systemd"
linux_code="hi-lfs"

echo ${linux_version} > /etc/${linux_dist_short}-release

cat > /etc/lsb-release << EOF
DISTRIB_ID="${linux_dist}"
DISTRIB_RELEASE="${linux_version}"
DISTRIB_CODENAME="${linux_code}"
DISTRIB_DESCRIPTION="${linux_dist}"
EOF

cat > /etc/os-release << EOF
NAME="${linux_dist}"
linux_version="${linux_version}"
ID="${linux_dist_short}"
PRETTY_NAME="${linux_dist} ${linux_version}"
linux_version_CODENAME="${linux_code}"
EOF

# --------------------------------------------------
# 11.3. Rebooting the System
# --------------------------------------------------

# logout
# umount -Rv $LFS

# umount -v $LFS/dev/pts
# mountpoint -q $LFS/dev/shm && umount $LFS/dev/shm
# umount -v $LFS/dev
# umount -v $LFS/run
# umount -v $LFS/proc
# umount -v $LFS/sys
# umount -v $LFS/home
# umount -v $LFS
# umount -v $LFS
