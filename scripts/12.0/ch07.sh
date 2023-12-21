########################################################################
### Part III. Building the LFS Cross Toolchain and Temporary Tools
########################################################################

# ======================================================================
## Chapter 7. Entering Chroot and Building Additional Temporary Tools
# ======================================================================

# ----------------------------------------------------------------------
# 7.2. Changing Ownership
# ----------------------------------------------------------------------

chown -R root:root $LFS/{usr,lib,var,etc,bin,sbin,tools}
case $(uname -m) in
  x86_64) chown -R root:root $LFS/lib64 ;;
esac

# ----------------------------------------------------------------------
# 7.3. Preparing Virtual Kernel File Systems
# ----------------------------------------------------------------------

mkdir -pv $LFS/{dev,proc,sys,run}
mount -v --bind /dev $LFS/dev
mount -v --bind /dev/pts $LFS/dev/pts
mount -vt proc proc $LFS/proc
mount -vt sysfs sysfs $LFS/sys
mount -vt tmpfs tmpfs $LFS/run
if [ -h $LFS/dev/shm ]; then
  mkdir -pv $LFS/$(readlink $LFS/dev/shm)
else
  mount -t tmpfs -o nosuid,nodev tmpfs $LFS/dev/shm
fi

# ----------------------------------------------------------------------
# 7.4. Entering the Chroot Environment
# ----------------------------------------------------------------------

chroot "$LFS" /usr/bin/env -i   \
    HOME=/root                  \
    TERM="$TERM"                \
    PS1='(lfs chroot) \u:\w\$ ' \
    PATH=/usr/bin:/usr/sbin     \
    /bin/bash --login

# ----------------------------------------------------------------------
# 7.5. Creating Directories
# ----------------------------------------------------------------------

mkdir -pv /{boot,home,mnt,opt,srv}
mkdir -pv /etc/{opt,sysconfig}
mkdir -pv /lib/firmware
mkdir -pv /media/{floppy,cdrom}
mkdir -pv /usr/{,local/}{include,src}
mkdir -pv /usr/local/{bin,lib,sbin}
mkdir -pv /usr/{,local/}share/{color,dict,doc,info,locale,man}
mkdir -pv /usr/{,local/}share/{misc,terminfo,zoneinfo}
mkdir -pv /usr/{,local/}share/man/man{1..8}
mkdir -pv /var/{cache,local,log,mail,opt,spool}
mkdir -pv /var/lib/{color,misc,locate}

ln -sfv /run /var/run
ln -sfv /run/lock /var/lock

install -dv -m 0750 /root
install -dv -m 1777 /tmp /var/tmp

# ----------------------------------------------------------------------
# 7.6. Creating Essential Files and Symlinks
# ----------------------------------------------------------------------

ln -sv /proc/self/mounts /etc/mtab

cat > /etc/hosts << EOF
127.0.0.1  localhost $(hostname)
::1        localhost
EOF

cat > /etc/passwd << "EOF"
root:x:0:0:root:/root:/bin/bash
bin:x:1:1:bin:/dev/null:/usr/bin/false
daemon:x:6:6:Daemon User:/dev/null:/usr/bin/false
messagebus:x:18:18:D-Bus Message Daemon User:/run/dbus:/usr/bin/false
uuidd:x:80:80:UUID Generation Daemon User:/dev/null:/usr/bin/false
nobody:x:65534:65534:Unprivileged User:/dev/null:/usr/bin/false
EOF

cat > /etc/group << "EOF"
root:x:0:
bin:x:1:daemon
sys:x:2:
kmem:x:3:
tape:x:4:
tty:x:5:
daemon:x:6:
floppy:x:7:
disk:x:8:
lp:x:9:
dialout:x:10:
audio:x:11:
video:x:12:
utmp:x:13:
usb:x:14:
cdrom:x:15:
adm:x:16:
messagebus:x:18:
input:x:24:
mail:x:34:
kvm:x:61:
uuidd:x:80:
wheel:x:97:
users:x:999:
nogroup:x:65534:
EOF

echo "tester:x:101:101::/home/tester:/bin/bash" >> /etc/passwd
echo "tester:x:101:" >> /etc/group
install -o tester -d /home/tester
exec /usr/bin/bash --login
touch /var/log/{btmp,lastlog,faillog,wtmp}
chgrp -v utmp /var/log/lastlog
chmod -v 664  /var/log/lastlog
chmod -v 600  /var/log/btmp

# ----------------------------------------------------------------------
# 7.7. Gettext-0.22
# Gettext-0.22 (gettext-0.22.tar.xz)
# ----------------------------------------------------------------------

begin_install gettext-0.22 tar.xz
# tar -xf gettext-0.22.tar.xz && cd gettext-0.22

./configure --disable-shared
make
cp -v gettext-tools/src/{msgfmt,msgmerge,xgettext} /usr/bin

# cd .. && rm -rf gettext-0.22
end_install

# ----------------------------------------------------------------------
# 7.8. Bison-3.8.2
# Bison-3.8.2 (bison-3.8.2.tar.xz)
# ----------------------------------------------------------------------

begin_install bison-3.8.2 tar.xz
# tar -xf bison-3.8.2.tar.xz && cd bison-3.8.2

./configure --prefix=/usr \
            --docdir=/usr/share/doc/bison-3.8.2
make
make install

# cd .. && rm -rf bison-3.8.2
end_install

# ----------------------------------------------------------------------
# 7.9. Perl-5.38.0
# Perl-5.38.0 (perl-5.38.0.tar.xz)
# ----------------------------------------------------------------------

begin_install perl-5.38.0 tar.xz
# tar -xf perl-5.38.0.tar.xz && cd perl-5.38.0

sh Configure -des                                        \
             -Dprefix=/usr                               \
             -Dvendorprefix=/usr                         \
             -Duseshrplib                                \
             -Dprivlib=/usr/lib/perl5/5.38/core_perl     \
             -Darchlib=/usr/lib/perl5/5.38/core_perl     \
             -Dsitelib=/usr/lib/perl5/5.38/site_perl     \
             -Dsitearch=/usr/lib/perl5/5.38/site_perl    \
             -Dvendorlib=/usr/lib/perl5/5.38/vendor_perl \
             -Dvendorarch=/usr/lib/perl5/5.38/vendor_perl
make
make install

# cd .. && rm -rf perl-5.38.0
end_install

# ----------------------------------------------------------------------
# 7.10. Python-3.11.4
# Python-3.11.4 (Python-3.11.4.tar.xz)
# ----------------------------------------------------------------------

begin_install Python-3.11.4 tar.xz
# tar -xf Python-3.11.4.tar.xz && cd Python-3.11.4

./configure --prefix=/usr   \
            --enable-shared \
            --without-ensurepip
make
make install

# cd .. && rm -rf Python-3.11.4
end_install

# ----------------------------------------------------------------------
# 7.11. Texinfo-7.0.3
# Texinfo-7.0.3 (texinfo-7.0.3.tar.xz)
# ----------------------------------------------------------------------

begin_install texinfo-7.0.3 tar.xz
# tar -xf texinfo-7.0.3.tar.xz && cd texinfo-7.0.3

./configure --prefix=/usr
make
make install

# cd .. && rm -rf texinfo-7.0.3
end_install

# ----------------------------------------------------------------------
# 7.12. Util-linux-2.39.1
# Util-linux-2.39.1 (util-linux-2.39.1.tar.xz)
# ----------------------------------------------------------------------

begin_install util-linux-2.39.1 tar.xz
# tar -xf util-linux-2.39.1.tar.xz && cd util-linux-2.39.1

mkdir -pv /var/lib/hwclock
./configure ADJTIME_PATH=/var/lib/hwclock/adjtime    \
            --libdir=/usr/lib    \
            --runstatedir=/run   \
            --docdir=/usr/share/doc/util-linux-2.39.1 \
            --disable-chfn-chsh  \
            --disable-login      \
            --disable-nologin    \
            --disable-su         \
            --disable-setpriv    \
            --disable-runuser    \
            --disable-pylibmount \
            --disable-static     \
            --without-python
make
make install

# cd .. && rm -rf util-linux-2.39.1
end_install

# ----------------------------------------------------------------------
# 7.13. Cleaning up and Saving the Temporary System
# ----------------------------------------------------------------------

rm -rf /usr/share/{info,man,doc}/*
find /usr/{lib,libexec} -name \*.la -delete
rm -rf /tools
exit
mountpoint -q $LFS/dev/shm && umount $LFS/dev/shm
umount $LFS/dev/pts
umount $LFS/{sys,proc,run,dev}
cd $LFS
tar -cJpf $HOME/lfs-temp-tools-12.0.tar.xz .
