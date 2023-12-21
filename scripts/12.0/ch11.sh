########################################################################
### Part IV. Building the LFS System
########################################################################

# ======================================================================
## Chapter 11. The End
# ======================================================================

# ----------------------------------------------------------------------
# 11.1. The End
# ----------------------------------------------------------------------

echo 12.0 > /etc/lfs-release

cat > /etc/lsb-release << "EOF"
DISTRIB_ID="Linux From Scratch"
DISTRIB_RELEASE="12.0"
DISTRIB_CODENAME="<your name here>"
DISTRIB_DESCRIPTION="Linux From Scratch"
EOF

cat > /etc/os-release << "EOF"
NAME="Linux From Scratch"
VERSION="12.0"
ID=lfs
PRETTY_NAME="Linux From Scratch 12.0"
VERSION_CODENAME="<your name here>"
EOF

# ----------------------------------------------------------------------
# 11.3. Rebooting the System
# ----------------------------------------------------------------------

logout
umount -v $LFS/dev/pts
mountpoint -q $LFS/dev/shm && umount $LFS/dev/shm
umount -v $LFS/dev
umount -v $LFS/run
umount -v $LFS/proc
umount -v $LFS/sys
umount -v $LFS/home
umount -v $LFS
umount -v $LFS
