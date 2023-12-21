#!/bin/bash

package_name=""
package_ext=""
base_dir=/sources
build_stage="lfs-chroot-ch07"
startTime=""
endTime=""

begin_install() {
  startTime=`date +"%Y-%m-%d %H:%M:%S"`
  package_name=$1
  package_ext=$2
  cd ${base_dir}

  echo "[$build_stage] Starting build of $package_name at $startTime"

  tar xf $package_name.$package_ext
  cd $package_name
}

end_install() {
  endTime=`date +"%Y-%m-%d %H:%M:%S"`
  echo "[$build_stage] Finishing build of $package_name at $endTime"

  cd ${base_dir}
  rm -rf $package_name
  
  st=`date -d  "$startTime" +%s`
  et=`date -d  "$endTime" +%s`
  sumTime=$(($et-$st))
  echo "==>> Total time: $sumTime sec ($startTime => $endTime, $(date))."
}


###########################

cd ${base_dir}

###########################


####################################################
### Part III. Building the LFS Cross Toolchain and Temporary Tools
####################################################

# --------------------------------------------------
# 7.7. Gettext-0.22
# Gettext-0.22 (gettext-0.22.tar.xz)
# --------------------------------------------------

begin_install gettext-0.22 tar.xz
./configure --disable-shared
make
cp -v gettext-tools/src/{msgfmt,msgmerge,xgettext} /usr/bin
end_install

# --------------------------------------------------
# 7.8. Bison-3.8.2
# Bison-3.8.2 (bison-3.8.2.tar.xz)
# --------------------------------------------------

begin_install bison-3.8.2 tar.xz
./configure --prefix=/usr \
            --docdir=/usr/share/doc/bison-3.8.2
make
make install
end_install

# --------------------------------------------------
# 7.9. Perl-5.38.0
# Perl-5.38.0 (perl-5.38.0.tar.xz)
# --------------------------------------------------

begin_install perl-5.38.0 tar.xz
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
end_install

# --------------------------------------------------
# 7.10. Python-3.11.4
# Python-3.11.4 (Python-3.11.4.tar.xz)
# --------------------------------------------------

begin_install Python-3.11.4 tar.xz
./configure --prefix=/usr   \
            --enable-shared \
            --without-ensurepip
make
make install
end_install

# --------------------------------------------------
# 7.11. Texinfo-7.0.3
# Texinfo-7.0.3 (texinfo-7.0.3.tar.xz)
# --------------------------------------------------

begin_install texinfo-7.0.3 tar.xz
./configure --prefix=/usr
make
make install
end_install

# --------------------------------------------------
# 7.12. Util-linux-2.39.1
# Util-linux-2.39.1 (util-linux-2.39.1.tar.xz)
# --------------------------------------------------

begin_install util-linux-2.39.1 tar.xz
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
end_install

# --------------------------------------------------
# 7.13. Cleaning up and Saving the Temporary System
# --------------------------------------------------

# rm -rf /usr/share/{info,man,doc}/*
# find /usr/{lib,libexec} -name \*.la -delete
# rm -rf /tools

# exit
# mountpoint -q $LFS/dev/shm && umount $LFS/dev/shm
# umount $LFS/dev/pts
# umount $LFS/{sys,proc,run,dev}
# cd $LFS
# tar -cJpf $HOME/lfs-temp-tools-12.0.tar.xz .
