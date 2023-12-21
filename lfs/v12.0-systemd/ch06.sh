#!/bin/bash

package_name=""
package_ext=""
base_dir=$LFS/sources
build_stage="lfs-cross-ch06"
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

# ==================================================
## Chapter 6. Cross Compiling Temporary Tools
# ==================================================

# --------------------------------------------------
# 6.2. M4-1.4.19
# M4-1.4.19 (m4-1.4.19.tar.xz)
# --------------------------------------------------

begin_install m4-1.4.19 tar.xz
./configure --prefix=/usr   \
            --host=$LFS_TGT \
            --build=$(build-aux/config.guess)
make
make DESTDIR=$LFS install
end_install

# --------------------------------------------------
# 6.3. Ncurses-6.4
# Ncurses-6.4 (ncurses-6.4.tar.gz)
# --------------------------------------------------

begin_install ncurses-6.4 tar.gz
sed -i s/mawk// configure
mkdir build
pushd build
  ../configure
  make -C include
  make -C progs tic
popd
./configure --prefix=/usr                \
            --host=$LFS_TGT              \
            --build=$(./config.guess)    \
            --mandir=/usr/share/man      \
            --with-manpage-format=normal \
            --with-shared                \
            --without-normal             \
            --with-cxx-shared            \
            --without-debug              \
            --without-ada                \
            --disable-stripping          \
            --enable-widec
make
make DESTDIR=$LFS TIC_PATH=$(pwd)/build/progs/tic install
echo "INPUT(-lncursesw)" > $LFS/usr/lib/libncurses.so
end_install

# --------------------------------------------------
# 6.4. Bash-5.2.15
# Bash-5.2.15 (bash-5.2.15.tar.gz)
# --------------------------------------------------

begin_install bash-5.2.15 tar.gz
./configure --prefix=/usr                      \
            --build=$(sh support/config.guess) \
            --host=$LFS_TGT                    \
            --without-bash-malloc
make
make DESTDIR=$LFS install
ln -sv bash $LFS/bin/sh
end_install

# --------------------------------------------------
# 6.5. Coreutils-9.3
# Coreutils-9.3 (coreutils-9.3.tar.xz)
# --------------------------------------------------

begin_install coreutils-9.3 tar.xz
./configure --prefix=/usr                     \
            --host=$LFS_TGT                   \
            --build=$(build-aux/config.guess) \
            --enable-install-program=hostname \
            --enable-no-install-program=kill,uptime \
            gl_cv_macro_MB_CUR_MAX_good=y
make
make DESTDIR=$LFS install
mv -v $LFS/usr/bin/chroot              $LFS/usr/sbin
mkdir -pv $LFS/usr/share/man/man8
mv -v $LFS/usr/share/man/man1/chroot.1 $LFS/usr/share/man/man8/chroot.8
sed -i 's/"1"/"8"/'                    $LFS/usr/share/man/man8/chroot.8
end_install

# --------------------------------------------------
# 6.6. Diffutils-3.10
# Diffutils-3.10 (diffutils-3.10.tar.xz)
# --------------------------------------------------

begin_install diffutils-3.10 tar.xz
./configure --prefix=/usr   \
            --host=$LFS_TGT \
            --build=$(./build-aux/config.guess)
make
make DESTDIR=$LFS install
end_install

# --------------------------------------------------
# 6.7. File-5.45
# File-5.45 (file-5.45.tar.gz)
# --------------------------------------------------

begin_install file-5.45 tar.gz
mkdir build
pushd build
  ../configure --disable-bzlib      \
               --disable-libseccomp \
               --disable-xzlib      \
               --disable-zlib
  make
popd
./configure --prefix=/usr --host=$LFS_TGT --build=$(./config.guess)
make FILE_COMPILE=$(pwd)/build/src/file
make DESTDIR=$LFS install
rm -v $LFS/usr/lib/libmagic.la
end_install

# --------------------------------------------------
# 6.8. Findutils-4.9.0
# Findutils-4.9.0 (findutils-4.9.0.tar.xz)
# --------------------------------------------------

begin_install findutils-4.9.0 tar.xz
./configure --prefix=/usr                   \
            --localstatedir=/var/lib/locate \
            --host=$LFS_TGT                 \
            --build=$(build-aux/config.guess)
make
make DESTDIR=$LFS install
end_install

# --------------------------------------------------
# 6.9. Gawk-5.2.2
# Gawk-5.2.2 (gawk-5.2.2.tar.xz)
# --------------------------------------------------

begin_install gawk-5.2.2 tar.xz
sed -i 's/extras//' Makefile.in
./configure --prefix=/usr   \
            --host=$LFS_TGT \
            --build=$(build-aux/config.guess)
make
make DESTDIR=$LFS install
end_install

# --------------------------------------------------
# 6.10. Grep-3.11
# Grep-3.11 (grep-3.11.tar.xz)
# --------------------------------------------------

begin_install grep-3.11 tar.xz
./configure --prefix=/usr   \
            --host=$LFS_TGT \
            --build=$(./build-aux/config.guess)
make
make DESTDIR=$LFS install
end_install

# --------------------------------------------------
# 6.11. Gzip-1.12
# Gzip-1.12 (gzip-1.12.tar.xz)
# --------------------------------------------------

begin_install gzip-1.12 tar.xz
./configure --prefix=/usr --host=$LFS_TGT
make
make DESTDIR=$LFS install
end_install

# --------------------------------------------------
# 6.12. Make-4.4.1
# Make-4.4.1 (make-4.4.1.tar.gz)
# --------------------------------------------------

begin_install make-4.4.1 tar.gz
./configure --prefix=/usr   \
            --without-guile \
            --host=$LFS_TGT \
            --build=$(build-aux/config.guess)
make
make DESTDIR=$LFS install
end_install

# --------------------------------------------------
# 6.13. Patch-2.7.6
# Patch-2.7.6 (patch-2.7.6.tar.xz)
# --------------------------------------------------

begin_install patch-2.7.6 tar.xz
./configure --prefix=/usr   \
            --host=$LFS_TGT \
            --build=$(build-aux/config.guess)
make
make DESTDIR=$LFS install
end_install

# --------------------------------------------------
# 6.14. Sed-4.9
# Sed-4.9 (sed-4.9.tar.xz)
# --------------------------------------------------

begin_install sed-4.9 tar.xz
./configure --prefix=/usr   \
            --host=$LFS_TGT \
            --build=$(./build-aux/config.guess)
make
make DESTDIR=$LFS install
end_install

# --------------------------------------------------
# 6.15. Tar-1.35
# Tar-1.35 (tar-1.35.tar.xz)
# --------------------------------------------------

begin_install tar-1.35 tar.xz
./configure --prefix=/usr                     \
            --host=$LFS_TGT                   \
            --build=$(build-aux/config.guess)
make
make DESTDIR=$LFS install
end_install

# --------------------------------------------------
# 6.16. Xz-5.4.4
# Xz-5.4.4 (xz-5.4.4.tar.xz)
# --------------------------------------------------

begin_install xz-5.4.4 tar.xz
./configure --prefix=/usr                     \
            --host=$LFS_TGT                   \
            --build=$(build-aux/config.guess) \
            --disable-static                  \
            --docdir=/usr/share/doc/xz-5.4.4
make
make DESTDIR=$LFS install
rm -v $LFS/usr/lib/liblzma.la
end_install

# --------------------------------------------------
# 6.17. Binutils-2.41 - Pass 2
# Binutils-2.41 (binutils-2.41.tar.xz)
# --------------------------------------------------

begin_install binutils-2.41 tar.xz
sed '6009s/$add_dir//' -i ltmain.sh
mkdir -v build
cd       build
../configure                   \
    --prefix=/usr              \
    --build=$(../config.guess) \
    --host=$LFS_TGT            \
    --disable-nls              \
    --enable-shared            \
    --enable-gprofng=no        \
    --disable-werror           \
    --enable-64-bit-bfd
make
make DESTDIR=$LFS install
rm -v $LFS/usr/lib/lib{bfd,ctf,ctf-nobfd,opcodes,sframe}.{a,la}
end_install

# --------------------------------------------------
# 6.18. GCC-13.2.0 - Pass 2
# GCC-13.2.0 (gcc-13.2.0.tar.xz)
# --------------------------------------------------

begin_install gcc-13.2.0 tar.xz
tar -xf ../mpfr-4.2.0.tar.xz
mv -v mpfr-4.2.0 mpfr
tar -xf ../gmp-6.3.0.tar.xz
mv -v gmp-6.3.0 gmp
tar -xf ../mpc-1.3.1.tar.gz
mv -v mpc-1.3.1 mpc
case $(uname -m) in
  x86_64)
    sed -e '/m64=/s/lib64/lib/' -i.orig gcc/config/i386/t-linux64
  ;;
esac
sed '/thread_header =/s/@.*@/gthr-posix.h/' \
    -i libgcc/Makefile.in libstdc++-v3/include/Makefile.in
mkdir -v build
cd       build
../configure                                       \
    --build=$(../config.guess)                     \
    --host=$LFS_TGT                                \
    --target=$LFS_TGT                              \
    LDFLAGS_FOR_TARGET=-L$PWD/$LFS_TGT/libgcc      \
    --prefix=/usr                                  \
    --with-build-sysroot=$LFS                      \
    --enable-default-pie                           \
    --enable-default-ssp                           \
    --disable-nls                                  \
    --disable-multilib                             \
    --disable-libatomic                            \
    --disable-libgomp                              \
    --disable-libquadmath                          \
    --disable-libsanitizer                         \
    --disable-libssp                               \
    --disable-libvtv                               \
    --enable-languages=c,c++
make
make DESTDIR=$LFS install
ln -sv gcc $LFS/usr/bin/cc
end_install
