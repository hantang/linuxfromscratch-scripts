#!/bin/bash

package_name=""
package_ext=""
base_dir=/sources
build_stage="lfs-system-ch08"
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
### Part IV. Building the LFS System
####################################################

# ==================================================
## Chapter 8. Installing Basic System Software
# ==================================================

# --------------------------------------------------
# 8.2. Package Management
# --------------------------------------------------

# grep -l 'libfoo.*deleted' /proc/*/maps | tr -cd 0-9\\n | xargs -r ps u
# ./configure --prefix=/usr/pkg/libfoo/1.1
# make
# make install
# ./configure --prefix=/usr
# make
# make DESTDIR=/usr/pkg/libfoo/1.1 install

# --------------------------------------------------
# 8.3. Man-pages-6.05.01
# Man-pages-6.05.01 (man-pages-6.05.01.tar.xz)
# --------------------------------------------------

begin_install man-pages-6.05.01 tar.xz
rm -v man3/crypt*
make prefix=/usr install
end_install

# --------------------------------------------------
# 8.4. Iana-Etc-20230810
# Iana-Etc-20230810 (iana-etc-20230810.tar.gz)
# --------------------------------------------------

begin_install iana-etc-20230810 tar.gz
cp services protocols /etc
end_install

# --------------------------------------------------
# 8.5. Glibc-2.38
# Glibc-2.38 (glibc-2.38.tar.xz)
# --------------------------------------------------

begin_install glibc-2.38 tar.xz
patch -Np1 -i ../glibc-2.38-fhs-1.patch
patch -Np1 -i ../glibc-2.38-memalign_fix-1.patch
mkdir -v build
cd       build
echo "rootsbindir=/usr/sbin" > configparms
../configure --prefix=/usr                            \
             --disable-werror                         \
             --enable-kernel=4.14                     \
             --enable-stack-protector=strong          \
             --with-headers=/usr/include              \
             libc_cv_slibdir=/usr/lib
make
# make check
touch /etc/ld.so.conf
sed '/test-installation/s@$(PERL)@echo not running@' -i ../Makefile
make install
sed '/RTLDLIST=/s@/usr@@g' -i /usr/bin/ldd
cp -v ../nscd/nscd.conf /etc/nscd.conf
mkdir -pv /var/cache/nscd
install -v -Dm644 ../nscd/nscd.tmpfiles /usr/lib/tmpfiles.d/nscd.conf
install -v -Dm644 ../nscd/nscd.service /usr/lib/systemd/system/nscd.service
mkdir -pv /usr/lib/locale
localedef -i POSIX -f UTF-8 C.UTF-8 2> /dev/null || true
localedef -i cs_CZ -f UTF-8 cs_CZ.UTF-8
localedef -i de_DE -f ISO-8859-1 de_DE
localedef -i de_DE@euro -f ISO-8859-15 de_DE@euro
localedef -i de_DE -f UTF-8 de_DE.UTF-8
localedef -i el_GR -f ISO-8859-7 el_GR
localedef -i en_GB -f ISO-8859-1 en_GB
localedef -i en_GB -f UTF-8 en_GB.UTF-8
localedef -i en_HK -f ISO-8859-1 en_HK
localedef -i en_PH -f ISO-8859-1 en_PH
localedef -i en_US -f ISO-8859-1 en_US
localedef -i en_US -f UTF-8 en_US.UTF-8
localedef -i es_ES -f ISO-8859-15 es_ES@euro
localedef -i es_MX -f ISO-8859-1 es_MX
localedef -i fa_IR -f UTF-8 fa_IR
localedef -i fr_FR -f ISO-8859-1 fr_FR
localedef -i fr_FR@euro -f ISO-8859-15 fr_FR@euro
localedef -i fr_FR -f UTF-8 fr_FR.UTF-8
localedef -i is_IS -f ISO-8859-1 is_IS
localedef -i is_IS -f UTF-8 is_IS.UTF-8
localedef -i it_IT -f ISO-8859-1 it_IT
localedef -i it_IT -f ISO-8859-15 it_IT@euro
localedef -i it_IT -f UTF-8 it_IT.UTF-8
localedef -i ja_JP -f EUC-JP ja_JP
localedef -i ja_JP -f SHIFT_JIS ja_JP.SJIS 2> /dev/null || true
localedef -i ja_JP -f UTF-8 ja_JP.UTF-8
localedef -i nl_NL@euro -f ISO-8859-15 nl_NL@euro
localedef -i ru_RU -f KOI8-R ru_RU.KOI8-R
localedef -i ru_RU -f UTF-8 ru_RU.UTF-8
localedef -i se_NO -f UTF-8 se_NO.UTF-8
localedef -i ta_IN -f UTF-8 ta_IN.UTF-8
localedef -i tr_TR -f UTF-8 tr_TR.UTF-8
localedef -i zh_CN -f GB18030 zh_CN.GB18030
localedef -i zh_HK -f BIG5-HKSCS zh_HK.BIG5-HKSCS
localedef -i zh_TW -f UTF-8 zh_TW.UTF-8

# make localedata/install-locales
# localedef -i POSIX -f UTF-8 C.UTF-8 2> /dev/null || true
# localedef -i ja_JP -f SHIFT_JIS ja_JP.SJIS 2> /dev/null || true

cat > /etc/nsswitch.conf << "EOF"
# Begin /etc/nsswitch.conf

passwd: files
group: files
shadow: files

hosts: files dns
networks: files

protocols: files
services: files
ethers: files
rpc: files

# End /etc/nsswitch.conf
EOF

tar -xf ../../tzdata2023c.tar.gz

ZONEINFO=/usr/share/zoneinfo
mkdir -pv $ZONEINFO/{posix,right}

for tz in etcetera southamerica northamerica europe africa antarctica  \
          asia australasia backward; do
    zic -L /dev/null   -d $ZONEINFO       ${tz}
    zic -L /dev/null   -d $ZONEINFO/posix ${tz}
    zic -L leapseconds -d $ZONEINFO/right ${tz}
done

cp -v zone.tab zone1970.tab iso3166.tab $ZONEINFO
zic -d $ZONEINFO -p America/New_York
unset ZONEINFO
# tzselect
# ln -sfv /usr/share/zoneinfo/<xxx> /etc/localtime
ln -sfv /usr/share/Asia/Shanghai /etc/localtime

cat > /etc/ld.so.conf << "EOF"
# Begin /etc/ld.so.conf
/usr/local/lib
/opt/lib

EOF

cat >> /etc/ld.so.conf << "EOF"
# Add an include directory
include /etc/ld.so.conf.d/*.conf

EOF
mkdir -pv /etc/ld.so.conf.d
end_install

# --------------------------------------------------
# 8.6. Zlib-1.2.13
# Zlib-1.2.13 (zlib-1.2.13.tar.xz)
# --------------------------------------------------

begin_install zlib-1.2.13 tar.xz
./configure --prefix=/usr
make
# make check
make install
rm -fv /usr/lib/libz.a
end_install

# --------------------------------------------------
# 8.7. Bzip2-1.0.8
# Bzip2-1.0.8 (bzip2-1.0.8.tar.gz)
# --------------------------------------------------

begin_install bzip2-1.0.8 tar.gz
patch -Np1 -i ../bzip2-1.0.8-install_docs-1.patch
sed -i 's@\(ln -s -f \)$(PREFIX)/bin/@\1@' Makefile
sed -i "s@(PREFIX)/man@(PREFIX)/share/man@g" Makefile
make -f Makefile-libbz2_so
make clean
make
make PREFIX=/usr install
cp -av libbz2.so.* /usr/lib
ln -sv libbz2.so.1.0.8 /usr/lib/libbz2.so
cp -v bzip2-shared /usr/bin/bzip2
for i in /usr/bin/{bzcat,bunzip2}; do
  ln -sfv bzip2 $i
done
rm -fv /usr/lib/libbz2.a
end_install

# --------------------------------------------------
# 8.8. Xz-5.4.4
# Xz-5.4.4 (xz-5.4.4.tar.xz)
# --------------------------------------------------

begin_install xz-5.4.4 tar.xz
./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/xz-5.4.4
make
# make check
make install
end_install

# --------------------------------------------------
# 8.9. Zstd-1.5.5
# Zstd-1.5.5 (zstd-1.5.5.tar.gz)
# --------------------------------------------------

begin_install zstd-1.5.5 tar.gz
make prefix=/usr
# make check
make prefix=/usr install
rm -v /usr/lib/libzstd.a
end_install

# --------------------------------------------------
# 8.10. File-5.45
# File-5.45 (file-5.45.tar.gz)
# --------------------------------------------------

begin_install file-5.45 tar.gz
./configure --prefix=/usr
make
# make check
make install
end_install

# --------------------------------------------------
# 8.11. Readline-8.2
# Readline-8.2 (readline-8.2.tar.gz)
# --------------------------------------------------

begin_install readline-8.2 tar.gz
sed -i '/MV.*old/d' Makefile.in
sed -i '/{OLDSUFF}/c:' support/shlib-install
patch -Np1 -i ../readline-8.2-upstream_fix-1.patch
./configure --prefix=/usr    \
            --disable-static \
            --with-curses    \
            --docdir=/usr/share/doc/readline-8.2
make SHLIB_LIBS="-lncursesw"
make SHLIB_LIBS="-lncursesw" install
install -v -m644 doc/*.{ps,pdf,html,dvi} /usr/share/doc/readline-8.2
end_install

# --------------------------------------------------
# 8.12. M4-1.4.19
# M4-1.4.19 (m4-1.4.19.tar.xz)
# --------------------------------------------------

begin_install m4-1.4.19 tar.xz
./configure --prefix=/usr
make
# make check
make install
end_install

# --------------------------------------------------
# 8.13. Bc-6.6.0
# Bc-6.6.0 (bc-6.6.0.tar.xz)
# --------------------------------------------------

begin_install bc-6.6.0 tar.xz
CC=gcc ./configure --prefix=/usr -G -O3 -r
make
# make test
make install
end_install

# --------------------------------------------------
# 8.14. Flex-2.6.4
# Flex-2.6.4 (flex-2.6.4.tar.gz)
# --------------------------------------------------

begin_install flex-2.6.4 tar.gz
./configure --prefix=/usr \
            --docdir=/usr/share/doc/flex-2.6.4 \
            --disable-static
make
# make check
make install
ln -sv flex   /usr/bin/lex
ln -sv flex.1 /usr/share/man/man1/lex.1
end_install

# --------------------------------------------------
# 8.15. Tcl-8.6.13
# Tcl-8.6.13 (tcl8.6.13-src.tar.gz)
# --------------------------------------------------

cp tcl8.6.13-src.tar.gz tcl8.6.13.tar.gz
begin_install tcl8.6.13 tar.gz
SRCDIR=$(pwd)
cd unix
./configure --prefix=/usr           \
            --mandir=/usr/share/man
make

sed -e "s|$SRCDIR/unix|/usr/lib|" \
    -e "s|$SRCDIR|/usr/include|"  \
    -i tclConfig.sh

sed -e "s|$SRCDIR/unix/pkgs/tdbc1.1.5|/usr/lib/tdbc1.1.5|" \
    -e "s|$SRCDIR/pkgs/tdbc1.1.5/generic|/usr/include|"    \
    -e "s|$SRCDIR/pkgs/tdbc1.1.5/library|/usr/lib/tcl8.6|" \
    -e "s|$SRCDIR/pkgs/tdbc1.1.5|/usr/include|"            \
    -i pkgs/tdbc1.1.5/tdbcConfig.sh

sed -e "s|$SRCDIR/unix/pkgs/itcl4.2.3|/usr/lib/itcl4.2.3|" \
    -e "s|$SRCDIR/pkgs/itcl4.2.3/generic|/usr/include|"    \
    -e "s|$SRCDIR/pkgs/itcl4.2.3|/usr/include|"            \
    -i pkgs/itcl4.2.3/itclConfig.sh

unset SRCDIR
# make test
make install
chmod -v u+w /usr/lib/libtcl8.6.so
make install-private-headers
ln -sfv tclsh8.6 /usr/bin/tclsh
mv /usr/share/man/man3/{Thread,Tcl_Thread}.3
cd ..
tar -xf ../tcl8.6.13-html.tar.gz --strip-components=1
mkdir -v -p /usr/share/doc/tcl-8.6.13
cp -v -r  ./html/* /usr/share/doc/tcl-8.6.13
end_install

# --------------------------------------------------
# 8.16. Expect-5.45.4
# Expect-5.45.4 (expect5.45.4.tar.gz)
# --------------------------------------------------

begin_install expect5.45.4 tar.gz
./configure --prefix=/usr           \
            --with-tcl=/usr/lib     \
            --enable-shared         \
            --mandir=/usr/share/man \
            --with-tclinclude=/usr/include
make
# make test
make install
ln -svf expect5.45.4/libexpect5.45.4.so /usr/lib
end_install

# --------------------------------------------------
# 8.17. DejaGNU-1.6.3
# DejaGNU-1.6.3 (dejagnu-1.6.3.tar.gz)
# --------------------------------------------------

begin_install dejagnu-1.6.3 tar.gz
mkdir -v build
cd       build
../configure --prefix=/usr
makeinfo --html --no-split -o doc/dejagnu.html ../doc/dejagnu.texi
makeinfo --plaintext       -o doc/dejagnu.txt  ../doc/dejagnu.texi
make install
install -v -dm755  /usr/share/doc/dejagnu-1.6.3
install -v -m644   doc/dejagnu.{html,txt} /usr/share/doc/dejagnu-1.6.3
# make check
end_install

# --------------------------------------------------
# 8.18. Binutils-2.41
# Binutils-2.41 (binutils-2.41.tar.xz)
# --------------------------------------------------

begin_install binutils-2.41 tar.xz
mkdir -v build
cd       build
../configure --prefix=/usr       \
             --sysconfdir=/etc   \
             --enable-gold       \
             --enable-ld=default \
             --enable-plugins    \
             --enable-shared     \
             --disable-werror    \
             --enable-64-bit-bfd \
             --with-system-zlib
make tooldir=/usr
# make -k check
grep '^FAIL:' $(find -name '*.log')
make tooldir=/usr install
rm -fv /usr/lib/lib{bfd,ctf,ctf-nobfd,gprofng,opcodes,sframe}.a
end_install

# --------------------------------------------------
# 8.19. GMP-6.3.0
# GMP-6.3.0 (gmp-6.3.0.tar.xz)
# --------------------------------------------------

begin_install gmp-6.3.0 tar.xz
# ABI=32 ./configure ...
./configure --prefix=/usr    \
            --enable-cxx     \
            --disable-static \
            --docdir=/usr/share/doc/gmp-6.3.0
make
make html
# make check 2>&1 | tee gmp-check-log
awk '/# PASS:/{total+=$3} ; END{print total}' gmp-check-log
make install
make install-html
end_install

# --------------------------------------------------
# 8.20. MPFR-4.2.0
# MPFR-4.2.0 (mpfr-4.2.0.tar.xz)
# --------------------------------------------------

begin_install mpfr-4.2.0 tar.xz
sed -e 's/+01,234,567/+1,234,567 /' \
    -e 's/13.10Pd/13Pd/'            \
    -i tests/tsprintf.c
./configure --prefix=/usr        \
            --disable-static     \
            --enable-thread-safe \
            --docdir=/usr/share/doc/mpfr-4.2.0
make
make html
# make check
make install
make install-html
end_install

# --------------------------------------------------
# 8.21. MPC-1.3.1
# MPC-1.3.1 (mpc-1.3.1.tar.gz)
# --------------------------------------------------

begin_install mpc-1.3.1 tar.gz
./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/mpc-1.3.1
make
make html
# make check
make install
make install-html
end_install

# --------------------------------------------------
# 8.22. Attr-2.5.1
# Attr-2.5.1 (attr-2.5.1.tar.gz)
# --------------------------------------------------

begin_install attr-2.5.1 tar.gz
./configure --prefix=/usr     \
            --disable-static  \
            --sysconfdir=/etc \
            --docdir=/usr/share/doc/attr-2.5.1
make
# make check
make install
end_install

# --------------------------------------------------
# 8.23. Acl-2.3.1
# Acl-2.3.1 (acl-2.3.1.tar.xz)
# --------------------------------------------------

begin_install acl-2.3.1 tar.xz
./configure --prefix=/usr         \
            --disable-static      \
            --docdir=/usr/share/doc/acl-2.3.1
make
make install
end_install

# --------------------------------------------------
# 8.24. Libcap-2.69
# Libcap-2.69 (libcap-2.69.tar.xz)
# --------------------------------------------------

begin_install libcap-2.69 tar.xz
sed -i '/install -m.*STA/d' libcap/Makefile
make prefix=/usr lib=lib
# make test
make prefix=/usr lib=lib install
end_install

# --------------------------------------------------
# 8.25. Libxcrypt-4.4.36
# Libxcrypt-4.4.36 (libxcrypt-4.4.36.tar.xz)
# --------------------------------------------------

begin_install libxcrypt-4.4.36 tar.xz
./configure --prefix=/usr                \
            --enable-hashes=strong,glibc \
            --enable-obsolete-api=no     \
            --disable-static             \
            --disable-failure-tokens
make
# make check
make install
# make distclean
# ./configure --prefix=/usr                \
#             --enable-hashes=strong,glibc \
#             --enable-obsolete-api=glibc  \
#             --disable-static             \
#             --disable-failure-tokens
# make
# cp -av .libs/libcrypt.so.1* /usr/lib
end_install

# --------------------------------------------------
# 8.26. Shadow-4.13
# Shadow-4.13 (shadow-4.13.tar.xz)
# --------------------------------------------------

begin_install shadow-4.13 tar.xz
sed -i 's/groups$(EXEEXT) //' src/Makefile.in
find man -name Makefile.in -exec sed -i 's/groups\.1 / /'   {} \;
find man -name Makefile.in -exec sed -i 's/getspnam\.3 / /' {} \;
find man -name Makefile.in -exec sed -i 's/passwd\.5 / /'   {} \;
sed -e 's:#ENCRYPT_METHOD DES:ENCRYPT_METHOD YESCRYPT:' \
    -e 's:/var/spool/mail:/var/mail:'                   \
    -e '/PATH=/{s@/sbin:@@;s@/bin:@@}'                  \
    -i etc/login.defs
# sed -i 's:DICTPATH.*:DICTPATH\t/lib/cracklib/pw_dict:' etc/login.defs
touch /usr/bin/passwd
./configure --sysconfdir=/etc   \
            --disable-static    \
            --with-{b,yes}crypt \
            --with-group-name-max-length=32
make
make exec_prefix=/usr install
make -C man install-man
mkdir -p /etc/default
useradd -D --gid 999
pwconv
grpconv
sed -i '/MAIL/s/yes/no/' /etc/default/useradd
# passwd root
echo "root:lfs#1991" | chpasswd
end_install

# --------------------------------------------------
# 8.27. GCC-13.2.0
# GCC-13.2.0 (gcc-13.2.0.tar.xz)
# --------------------------------------------------

begin_install gcc-13.2.0 tar.xz
case $(uname -m) in
  x86_64)
    sed -e '/m64=/s/lib64/lib/' \
        -i.orig gcc/config/i386/t-linux64
  ;;
esac
mkdir -v build
cd       build
../configure --prefix=/usr            \
             LD=ld                    \
             --enable-languages=c,c++ \
             --enable-default-pie     \
             --enable-default-ssp     \
             --disable-multilib       \
             --disable-bootstrap      \
             --disable-fixincludes    \
             --with-system-zlib
make

# ulimit -s 32768
# chown -Rv tester .
# su tester -c "PATH=$PATH make -k check"
# ../contrib/test_summary

make install
chown -v -R root:root \
    /usr/lib/gcc/$(gcc -dumpmachine)/13.2.0/include{,-fixed}
ln -svr /usr/bin/cpp /usr/lib
ln -sv gcc.1 /usr/share/man/man1/cc.1
ln -sfv ../../libexec/gcc/$(gcc -dumpmachine)/13.2.0/liblto_plugin.so \
        /usr/lib/bfd-plugins/
echo 'int main(){}' > dummy.c
cc dummy.c -v -Wl,--verbose &> dummy.log
readelf -l a.out | grep ': /lib'
grep -E -o '/usr/lib.*/S?crt[1in].*succeeded' dummy.log
grep -B4 '^ /usr/include' dummy.log
grep 'SEARCH.*/usr/lib' dummy.log |sed 's|; |\n|g'
grep "/lib.*/libc.so.6 " dummy.log
grep found dummy.log
rm -v dummy.c a.out dummy.log
mkdir -pv /usr/share/gdb/auto-load/usr/lib
mv -v /usr/lib/*gdb.py /usr/share/gdb/auto-load/usr/lib
end_install

# --------------------------------------------------
# 8.28. Pkgconf-2.0.1
# Pkgconf-2.0.1 (pkgconf-2.0.1.tar.xz)
# --------------------------------------------------

begin_install pkgconf-2.0.1 tar.xz
./configure --prefix=/usr              \
            --disable-static           \
            --docdir=/usr/share/doc/pkgconf-2.0.1
make
make install
ln -sv pkgconf   /usr/bin/pkg-config
ln -sv pkgconf.1 /usr/share/man/man1/pkg-config.1
end_install

# --------------------------------------------------
# 8.29. Ncurses-6.4
# Ncurses-6.4 (ncurses-6.4.tar.gz)
# --------------------------------------------------

begin_install ncurses-6.4 tar.gz
./configure --prefix=/usr           \
            --mandir=/usr/share/man \
            --with-shared           \
            --without-debug         \
            --without-normal        \
            --with-cxx-shared       \
            --enable-pc-files       \
            --enable-widec          \
            --with-pkg-config-libdir=/usr/lib/pkgconfig
make
make DESTDIR=$PWD/dest install
install -vm755 dest/usr/lib/libncursesw.so.6.4 /usr/lib
rm -v  dest/usr/lib/libncursesw.so.6.4
cp -av dest/* /
for lib in ncurses form panel menu ; do
    rm -vf                    /usr/lib/lib${lib}.so
    echo "INPUT(-l${lib}w)" > /usr/lib/lib${lib}.so
    ln -sfv ${lib}w.pc        /usr/lib/pkgconfig/${lib}.pc
done
rm -vf                     /usr/lib/libcursesw.so
echo "INPUT(-lncursesw)" > /usr/lib/libcursesw.so
ln -sfv libncurses.so      /usr/lib/libcurses.so
cp -v -R doc -T /usr/share/doc/ncurses-6.4
# make distclean
# ./configure --prefix=/usr    \
#             --with-shared    \
#             --without-normal \
#             --without-debug  \
#             --without-cxx-binding \
#             --with-abi-version=5
# make sources libs
# cp -av lib/lib*.so.5* /usr/lib
end_install

# --------------------------------------------------
# 8.30. Sed-4.9
# Sed-4.9 (sed-4.9.tar.xz)
# --------------------------------------------------

begin_install sed-4.9 tar.xz
./configure --prefix=/usr
make
make html

# chown -Rv tester .
# su tester -c "PATH=$PATH make check"

make install
install -d -m755           /usr/share/doc/sed-4.9
install -m644 doc/sed.html /usr/share/doc/sed-4.9
end_install

# --------------------------------------------------
# 8.31. Psmisc-23.6
# Psmisc-23.6 (psmisc-23.6.tar.xz)
# --------------------------------------------------

begin_install psmisc-23.6 tar.xz
./configure --prefix=/usr
make
# make check
make install
end_install

# --------------------------------------------------
# 8.32. Gettext-0.22
# Gettext-0.22 (gettext-0.22.tar.xz)
# --------------------------------------------------

begin_install gettext-0.22 tar.xz
./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/gettext-0.22
make
# make check
make install
chmod -v 0755 /usr/lib/preloadable_libintl.so
end_install

# --------------------------------------------------
# 8.33. Bison-3.8.2
# Bison-3.8.2 (bison-3.8.2.tar.xz)
# --------------------------------------------------

begin_install bison-3.8.2 tar.xz
./configure --prefix=/usr --docdir=/usr/share/doc/bison-3.8.2
make
# make check
make install
end_install

# --------------------------------------------------
# 8.34. Grep-3.11
# Grep-3.11 (grep-3.11.tar.xz)
# --------------------------------------------------

begin_install grep-3.11 tar.xz
sed -i "s/echo/#echo/" src/egrep.sh
./configure --prefix=/usr
make
# make check
make install
end_install

# --------------------------------------------------
# 8.35. Bash-5.2.15
# Bash-5.2.15 (bash-5.2.15.tar.gz)
# --------------------------------------------------

begin_install bash-5.2.15 tar.gz
./configure --prefix=/usr             \
            --without-bash-malloc     \
            --with-installed-readline \
            --docdir=/usr/share/doc/bash-5.2.15
make

# chown -Rv tester .
# su -s /usr/bin/expect tester << EOF
# set timeout -1
# spawn make tests
# expect eof
# lassign [wait] _ _ _ value
# exit $value
# EOF

make install
# exec /usr/bin/bash --login
end_install

# --------------------------------------------------
# 8.36. Libtool-2.4.7
# Libtool-2.4.7 (libtool-2.4.7.tar.xz)
# --------------------------------------------------

begin_install libtool-2.4.7 tar.xz
./configure --prefix=/usr
make
# make -k check
make install
rm -fv /usr/lib/libltdl.a
end_install

# --------------------------------------------------
# 8.37. GDBM-1.23
# GDBM-1.23 (gdbm-1.23.tar.gz)
# --------------------------------------------------

begin_install gdbm-1.23 tar.gz
./configure --prefix=/usr    \
            --disable-static \
            --enable-libgdbm-compat
make
# make check
make install
end_install

# --------------------------------------------------
# 8.38. Gperf-3.1
# Gperf-3.1 (gperf-3.1.tar.gz)
# --------------------------------------------------

begin_install gperf-3.1 tar.gz
./configure --prefix=/usr --docdir=/usr/share/doc/gperf-3.1
make
# make -j1 check
make install
end_install

# --------------------------------------------------
# 8.39. Expat-2.5.0
# Expat-2.5.0 (expat-2.5.0.tar.xz)
# --------------------------------------------------

begin_install expat-2.5.0 tar.xz
./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/expat-2.5.0
make
# make check
make install
install -v -m644 doc/*.{html,css} /usr/share/doc/expat-2.5.0
end_install

# --------------------------------------------------
# 8.40. Inetutils-2.4
# Inetutils-2.4 (inetutils-2.4.tar.xz)
# --------------------------------------------------

begin_install inetutils-2.4 tar.xz
./configure --prefix=/usr        \
            --bindir=/usr/bin    \
            --localstatedir=/var \
            --disable-logger     \
            --disable-whois      \
            --disable-rcp        \
            --disable-rexec      \
            --disable-rlogin     \
            --disable-rsh        \
            --disable-servers
make
# make check
make install
mv -v /usr/{,s}bin/ifconfig
end_install

# --------------------------------------------------
# 8.41. Less-643
# Less-643 (less-643.tar.gz)
# --------------------------------------------------

begin_install less-643 tar.gz
./configure --prefix=/usr --sysconfdir=/etc
make
# make check
make install
end_install

# --------------------------------------------------
# 8.42. Perl-5.38.0
# Perl-5.38.0 (perl-5.38.0.tar.xz)
# --------------------------------------------------

begin_install perl-5.38.0 tar.xz
export BUILD_ZLIB=False
export BUILD_BZIP2=0
sh Configure -des                                         \
             -Dprefix=/usr                                \
             -Dvendorprefix=/usr                          \
             -Dprivlib=/usr/lib/perl5/5.38/core_perl      \
             -Darchlib=/usr/lib/perl5/5.38/core_perl      \
             -Dsitelib=/usr/lib/perl5/5.38/site_perl      \
             -Dsitearch=/usr/lib/perl5/5.38/site_perl     \
             -Dvendorlib=/usr/lib/perl5/5.38/vendor_perl  \
             -Dvendorarch=/usr/lib/perl5/5.38/vendor_perl \
             -Dman1dir=/usr/share/man/man1                \
             -Dman3dir=/usr/share/man/man3                \
             -Dpager="/usr/bin/less -isR"                 \
             -Duseshrplib                                 \
             -Dusethreads
make
# make test
make install
unset BUILD_ZLIB BUILD_BZIP2
end_install

# --------------------------------------------------
# 8.43. XML::Parser-2.46
# XML::Parser-2.46 (XML-Parser-2.46.tar.gz)
# --------------------------------------------------

begin_install XML-Parser-2.46 tar.gz
perl Makefile.PL
make
# make test
make install
end_install

# --------------------------------------------------
# 8.44. Intltool-0.51.0
# Intltool-0.51.0 (intltool-0.51.0.tar.gz)
# --------------------------------------------------

begin_install intltool-0.51.0 tar.gz
sed -i 's:\\\${:\\\$\\{:' intltool-update.in
./configure --prefix=/usr
make
# make check
make install
install -v -Dm644 doc/I18N-HOWTO /usr/share/doc/intltool-0.51.0/I18N-HOWTO
end_install

# --------------------------------------------------
# 8.45. Autoconf-2.71
# Autoconf-2.71 (autoconf-2.71.tar.xz)
# --------------------------------------------------

begin_install autoconf-2.71 tar.xz
sed -e 's/SECONDS|/&SHLVL|/'               \
    -e '/BASH_ARGV=/a\        /^SHLVL=/ d' \
    -i.orig tests/local.at
./configure --prefix=/usr
make
# make check
make install
end_install

# --------------------------------------------------
# 8.46. Automake-1.16.5
# Automake-1.16.5 (automake-1.16.5.tar.xz)
# --------------------------------------------------

begin_install automake-1.16.5 tar.xz
./configure --prefix=/usr --docdir=/usr/share/doc/automake-1.16.5
make
# make -j4 check
make install
end_install

# --------------------------------------------------
# 8.47. OpenSSL-3.1.2
# OpenSSL-3.1.2 (openssl-3.1.2.tar.gz)
# --------------------------------------------------

begin_install openssl-3.1.2 tar.gz
./config --prefix=/usr         \
         --openssldir=/etc/ssl \
         --libdir=lib          \
         shared                \
         zlib-dynamic
make
# make test
sed -i '/INSTALL_LIBS/s/libcrypto.a libssl.a//' Makefile
make MANSUFFIX=ssl install
mv -v /usr/share/doc/openssl /usr/share/doc/openssl-3.1.2
cp -vfr doc/* /usr/share/doc/openssl-3.1.2
end_install

# --------------------------------------------------
# 8.48. Kmod-30
# Kmod-30 (kmod-30.tar.xz)
# --------------------------------------------------

begin_install kmod-30 tar.xz
./configure --prefix=/usr          \
            --sysconfdir=/etc      \
            --with-openssl         \
            --with-xz              \
            --with-zstd            \
            --with-zlib
make
make install

for target in depmod insmod modinfo modprobe rmmod; do
  ln -sfv ../bin/kmod /usr/sbin/$target
done

ln -sfv kmod /usr/bin/lsmod
end_install

# --------------------------------------------------
# 8.49. Libelf from Elfutils-0.189
# Libelf (elfutils-0.189.tar.bz2)
# --------------------------------------------------

begin_install elfutils-0.189 tar.bz2
./configure --prefix=/usr                \
            --disable-debuginfod         \
            --enable-libdebuginfod=dummy
make
# make check
make -C libelf install
install -vm644 config/libelf.pc /usr/lib/pkgconfig
rm /usr/lib/libelf.a
end_install

# --------------------------------------------------
# 8.50. Libffi-3.4.4
# Libffi-3.4.4 (libffi-3.4.4.tar.gz)
# --------------------------------------------------

begin_install libffi-3.4.4 tar.gz
./configure --prefix=/usr          \
            --disable-static       \
            --with-gcc-arch=native
make
# make check
make install
end_install

# --------------------------------------------------
# 8.51. Python-3.11.4
# Python-3.11.4 (Python-3.11.4.tar.xz)
# --------------------------------------------------

begin_install Python-3.11.4 tar.xz
./configure --prefix=/usr        \
            --enable-shared      \
            --with-system-expat  \
            --with-system-ffi    \
            --enable-optimizations
make
make install

cat > /etc/pip.conf << EOF
[global]
root-user-action = ignore
disable-pip-version-check = true
EOF

install -v -dm755 /usr/share/doc/python-3.11.4/html

tar --strip-components=1  \
    --no-same-owner       \
    --no-same-permissions \
    -C /usr/share/doc/python-3.11.4/html \
    -xvf ../python-3.11.4-docs-html.tar.bz2
end_install

# --------------------------------------------------
# 8.52. Flit-Core-3.9.0
# Flit-Core-3.9.0 (flit_core-3.9.0.tar.gz)
# --------------------------------------------------

begin_install flit_core-3.9.0 tar.gz
pip3 wheel -w dist --no-build-isolation --no-deps $PWD
pip3 install --no-index --no-user --find-links dist flit_core
end_install

# --------------------------------------------------
# 8.53. Wheel-0.41.1
# Wheel-0.41.1 (wheel-0.41.1.tar.gz)
# --------------------------------------------------

begin_install wheel-0.41.1 tar.gz
pip3 wheel -w dist --no-build-isolation --no-deps $PWD
pip3 install --no-index --find-links=dist wheel
end_install

# --------------------------------------------------
# 8.54. Ninja-1.11.1
# Ninja-1.11.1 (ninja-1.11.1.tar.gz)
# --------------------------------------------------

begin_install ninja-1.11.1 tar.gz
sed -i '/int Guess/a \
  int   j = 0;\
  char* jobs = getenv( "NINJAJOBS" );\
  if ( jobs != NULL ) j = atoi( jobs );\
  if ( j > 0 ) return j;\
' src/ninja.cc
python3 configure.py --bootstrap
./ninja ninja_test
./ninja_test --gtest_filter=-SubprocessTest.SetWithLots
install -vm755 ninja /usr/bin/
install -vDm644 misc/bash-completion /usr/share/bash-completion/completions/ninja
install -vDm644 misc/zsh-completion  /usr/share/zsh/site-functions/_ninja
end_install

# --------------------------------------------------
# 8.55. Meson-1.2.1
# Meson-1.2.1 (meson-1.2.1.tar.gz)
# --------------------------------------------------

begin_install meson-1.2.1 tar.gz
pip3 wheel -w dist --no-build-isolation --no-deps $PWD
pip3 install --no-index --find-links dist meson
install -vDm644 data/shell-completions/bash/meson /usr/share/bash-completion/completions/meson
install -vDm644 data/shell-completions/zsh/_meson /usr/share/zsh/site-functions/_meson
end_install

# --------------------------------------------------
# 8.56. Coreutils-9.3
# Coreutils-9.3 (coreutils-9.3.tar.xz)
# --------------------------------------------------

begin_install coreutils-9.3 tar.xz
patch -Np1 -i ../coreutils-9.3-i18n-1.patch
autoreconf -fiv
FORCE_UNSAFE_CONFIGURE=1 ./configure \
            --prefix=/usr            \
            --enable-no-install-program=kill,uptime
make

# make NON_ROOT_USERNAME=tester check-root
# groupadd -g 102 dummy -U tester
# chown -Rv tester .
# su tester -c "PATH=$PATH make RUN_EXPENSIVE_TESTS=yes check"
# groupdel dummy

make install
mv -v /usr/bin/chroot /usr/sbin
mv -v /usr/share/man/man1/chroot.1 /usr/share/man/man8/chroot.8
sed -i 's/"1"/"8"/' /usr/share/man/man8/chroot.8
end_install

# --------------------------------------------------
# 8.57. Check-0.15.2
# Check-0.15.2 (check-0.15.2.tar.gz)
# --------------------------------------------------

begin_install check-0.15.2 tar.gz
./configure --prefix=/usr --disable-static
make
# make check
# make docdir=/usr/share/doc/check-0.15.2 install
end_install

# --------------------------------------------------
# 8.58. Diffutils-3.10
# Diffutils-3.10 (diffutils-3.10.tar.xz)
# --------------------------------------------------

begin_install diffutils-3.10 tar.xz
./configure --prefix=/usr
make
# make check
make install
end_install

# --------------------------------------------------
# 8.59. Gawk-5.2.2
# Gawk-5.2.2 (gawk-5.2.2.tar.xz)
# --------------------------------------------------

begin_install gawk-5.2.2 tar.xz
sed -i 's/extras//' Makefile.in
./configure --prefix=/usr
make
# chown -Rv tester .
# su tester -c "PATH=$PATH make check"
make LN='ln -f' install
ln -sv gawk.1 /usr/share/man/man1/awk.1
mkdir -pv                                   /usr/share/doc/gawk-5.2.2
cp    -v doc/{awkforai.txt,*.{eps,pdf,jpg}} /usr/share/doc/gawk-5.2.2
end_install

# --------------------------------------------------
# 8.60. Findutils-4.9.0
# Findutils-4.9.0 (findutils-4.9.0.tar.xz)
# --------------------------------------------------

begin_install findutils-4.9.0 tar.xz
./configure --prefix=/usr --localstatedir=/var/lib/locate
make
# chown -Rv tester .
# su tester -c "PATH=$PATH make check"
make install
end_install

# --------------------------------------------------
# 8.61. Groff-1.23.0
# Groff-1.23.0 (groff-1.23.0.tar.gz)
# --------------------------------------------------

begin_install groff-1.23.0 tar.gz
PAGE=<paper_size> ./configure --prefix=/usr
make
# make check
make install
end_install

# --------------------------------------------------
# 8.62. GRUB-2.06
# GRUB-2.06 (grub-2.06.tar.xz)
# --------------------------------------------------

begin_install grub-2.06 tar.xz
# unset {C,CPP,CXX,LD}FLAGS
patch -Np1 -i ../grub-2.06-upstream_fixes-1.patch
./configure --prefix=/usr          \
            --sysconfdir=/etc      \
            --disable-efiemu       \
            --disable-werror
make
make install
mv -v /etc/bash_completion.d/grub /usr/share/bash-completion/completions
end_install

# --------------------------------------------------
# 8.63. Gzip-1.12
# Gzip-1.12 (gzip-1.12.tar.xz)
# --------------------------------------------------

begin_install gzip-1.12 tar.xz
./configure --prefix=/usr
make
# make check
make install
end_install

# --------------------------------------------------
# 8.64. IPRoute2-6.4.0
# IPRoute2-6.4.0 (iproute2-6.4.0.tar.xz)
# --------------------------------------------------

begin_install iproute2-6.4.0 tar.xz
sed -i /ARPD/d Makefile
rm -fv man/man8/arpd.8
make NETNS_RUN_DIR=/run/netns
make SBINDIR=/usr/sbin install
mkdir -pv             /usr/share/doc/iproute2-6.4.0
cp -v COPYING README* /usr/share/doc/iproute2-6.4.0
end_install

# --------------------------------------------------
# 8.65. Kbd-2.6.1
# Kbd-2.6.1 (kbd-2.6.1.tar.xz)
# --------------------------------------------------

begin_install kbd-2.6.1 tar.xz
patch -Np1 -i ../kbd-2.6.1-backspace-1.patch
sed -i '/RESIZECONS_PROGS=/s/yes/no/' configure
sed -i 's/resizecons.8 //' docs/man/man8/Makefile.in
./configure --prefix=/usr --disable-vlock
make
# make check
make install
cp -R -v docs/doc -T /usr/share/doc/kbd-2.6.1
end_install

# --------------------------------------------------
# 8.66. Libpipeline-1.5.7
# Libpipeline-1.5.7 (libpipeline-1.5.7.tar.gz)
# --------------------------------------------------

begin_install libpipeline-1.5.7 tar.gz
./configure --prefix=/usr
make
# make check
make install
end_install

# --------------------------------------------------
# 8.67. Make-4.4.1
# Make-4.4.1 (make-4.4.1.tar.gz)
# --------------------------------------------------

begin_install make-4.4.1 tar.gz
./configure --prefix=/usr
make
# chown -Rv tester .
# su tester -c "PATH=$PATH make check"
make install
end_install

# --------------------------------------------------
# 8.68. Patch-2.7.6
# Patch-2.7.6 (patch-2.7.6.tar.xz)
# --------------------------------------------------

begin_install patch-2.7.6 tar.xz
./configure --prefix=/usr
make
# make check
make install
end_install

# --------------------------------------------------
# 8.69. Tar-1.35
# Tar-1.35 (tar-1.35.tar.xz)
# --------------------------------------------------

begin_install tar-1.35 tar.xz
FORCE_UNSAFE_CONFIGURE=1  \
./configure --prefix=/usr
make
# make check
make install
make -C doc install-html docdir=/usr/share/doc/tar-1.35
end_install

# --------------------------------------------------
# 8.70. Texinfo-7.0.3
# Texinfo-7.0.3 (texinfo-7.0.3.tar.xz)
# --------------------------------------------------

begin_install texinfo-7.0.3 tar.xz
./configure --prefix=/usr
make
# make check
make install
make TEXMF=/usr/share/texmf install-tex
pushd /usr/share/info
  rm -v dir
  for f in *
    do install-info $f dir 2>/dev/null
  done
popd
end_install

# --------------------------------------------------
# 8.71. Vim-9.0.1677
# Vim-9.0.1677 (vim-9.0.1677.tar.gz)
# --------------------------------------------------

begin_install vim-9.0.1677 tar.gz
echo '#define SYS_VIMRC_FILE "/etc/vimrc"' >> src/feature.h
./configure --prefix=/usr
make
# chown -Rv tester .
# su tester -c "LANG=en_US.UTF-8 make -j1 test" &> vim-test.log
make install
ln -sv vim /usr/bin/vi
for L in  /usr/share/man/{,*/}man1/vim.1; do
    ln -sv vim.1 $(dirname $L)/vi.1
done
ln -sv ../vim/vim90/doc /usr/share/doc/vim-9.0.1677

cat > /etc/vimrc << "EOF"
" Begin /etc/vimrc

" Ensure defaults are set before customizing settings, not after
source $VIMRUNTIME/defaults.vim
let skip_defaults_vim=1

set nocompatible
set backspace=2
set mouse=
syntax on
if (&term == "xterm") || (&term == "putty")
  set background=dark
endif

" End /etc/vimrc
EOF

# vim -c ':options'
end_install

# --------------------------------------------------
# 8.72. MarkupSafe-2.1.3
# MarkupSafe-2.1.3 (MarkupSafe-2.1.3.tar.gz)
# --------------------------------------------------

begin_install MarkupSafe-2.1.3 tar.gz
pip3 wheel -w dist --no-build-isolation --no-deps $PWD
pip3 install --no-index --no-user --find-links dist Markupsafe
end_install

# --------------------------------------------------
# 8.73. Jinja2-3.1.2
# Jinja2-3.1.2 (Jinja2-3.1.2.tar.gz)
# --------------------------------------------------

begin_install Jinja2-3.1.2 tar.gz
pip3 wheel -w dist --no-build-isolation --no-deps $PWD
pip3 install --no-index --no-user --find-links dist Jinja2
end_install

# --------------------------------------------------
# 8.74. Systemd-254
# Systemd-254 (systemd-254.tar.gz)
# --------------------------------------------------

begin_install systemd-254 tar.gz
sed -i -e 's/GROUP="render"/GROUP="video"/' \
       -e 's/GROUP="sgx", //' rules.d/50-udev-default.rules.in
mkdir -p build
cd       build

meson setup \
      --prefix=/usr                 \
      --buildtype=release           \
      -Ddefault-dnssec=no           \
      -Dfirstboot=false             \
      -Dinstall-tests=false         \
      -Dldconfig=false              \
      -Dsysusers=false              \
      -Drpmmacrosdir=no             \
      -Dhomed=false                 \
      -Duserdb=false                \
      -Dman=false                   \
      -Dmode=release                \
      -Dpamconfdir=no               \
      -Ddev-kvm-mode=0660           \
      -Ddocdir=/usr/share/doc/systemd-254 \
      ..
ninja
ninja install
tar -xf ../../systemd-man-pages-254.tar.xz \
    --no-same-owner --strip-components=1   \
    -C /usr/share/man
systemd-machine-id-setup
systemctl preset-all
systemctl disable systemd-sysupdate{,-reboot}
end_install

# --------------------------------------------------
# 8.75. D-Bus-1.14.8
# D-Bus-1.14.8 (dbus-1.14.8.tar.xz)
# --------------------------------------------------

begin_install dbus-1.14.8 tar.xz
./configure --prefix=/usr                        \
            --sysconfdir=/etc                    \
            --localstatedir=/var                 \
            --runstatedir=/run                   \
            --enable-user-session                \
            --disable-static                     \
            --disable-doxygen-docs               \
            --disable-xml-docs                   \
            --docdir=/usr/share/doc/dbus-1.14.8  \
            --with-system-socket=/run/dbus/system_bus_socket
make
# make check
make install
ln -sfv /etc/machine-id /var/lib/dbus
end_install

# --------------------------------------------------
# 8.76. Man-DB-2.11.2
# Man-DB-2.11.2 (man-db-2.11.2.tar.xz)
# --------------------------------------------------

begin_install man-db-2.11.2 tar.xz
./configure --prefix=/usr                         \
            --docdir=/usr/share/doc/man-db-2.11.2 \
            --sysconfdir=/etc                     \
            --disable-setuid                      \
            --enable-cache-owner=bin              \
            --with-browser=/usr/bin/lynx          \
            --with-vgrind=/usr/bin/vgrind         \
            --with-grap=/usr/bin/grap
make
# make -k check
make install
end_install

# --------------------------------------------------
# 8.77. Procps-ng-4.0.3
# Procps-ng-4.0.3 (procps-ng-4.0.3.tar.xz)
# --------------------------------------------------

begin_install procps-ng-4.0.3 tar.xz
./configure --prefix=/usr                           \
            --docdir=/usr/share/doc/procps-ng-4.0.3 \
            --disable-static                        \
            --disable-kill                          \
            --with-systemd
make
# make check
make install
end_install

# --------------------------------------------------
# 8.78. Util-linux-2.39.1
# Util-linux-2.39.1 (util-linux-2.39.1.tar.xz)
# --------------------------------------------------

begin_install util-linux-2.39.1 tar.xz
sed -i '/test_mkfds/s/^/#/' tests/helpers/Makemodule.am
./configure ADJTIME_PATH=/var/lib/hwclock/adjtime \
            --bindir=/usr/bin    \
            --libdir=/usr/lib    \
            --runstatedir=/run   \
            --sbindir=/usr/sbin  \
            --disable-chfn-chsh  \
            --disable-login      \
            --disable-nologin    \
            --disable-su         \
            --disable-setpriv    \
            --disable-runuser    \
            --disable-pylibmount \
            --disable-static     \
            --without-python     \
            --docdir=/usr/share/doc/util-linux-2.39.1
make
# bash tests/run.sh --srcdir=$PWD --builddir=$PWD
# chown -Rv tester .
# su tester -c "make -k check"
make install
end_install

# --------------------------------------------------
# 8.79. E2fsprogs-1.47.0
# E2fsprogs-1.47.0 (e2fsprogs-1.47.0.tar.gz)
# --------------------------------------------------

begin_install e2fsprogs-1.47.0 tar.gz
mkdir -v build
cd       build
../configure --prefix=/usr           \
             --sysconfdir=/etc       \
             --enable-elf-shlibs     \
             --disable-libblkid      \
             --disable-libuuid       \
             --disable-uuidd         \
             --disable-fsck
make
# make check
make install
rm -fv /usr/lib/{libcom_err,libe2p,libext2fs,libss}.a
gunzip -v /usr/share/info/libext2fs.info.gz
install-info --dir-file=/usr/share/info/dir /usr/share/info/libext2fs.info
makeinfo -o      doc/com_err.info ../lib/et/com_err.texinfo
install -v -m644 doc/com_err.info /usr/share/info
install-info --dir-file=/usr/share/info/dir /usr/share/info/com_err.info
sed 's/metadata_csum_seed,//' -i /etc/mke2fs.conf
end_install

# --------------------------------------------------
# 8.81. Stripping
# --------------------------------------------------

save_usrlib="$(cd /usr/lib; ls ld-linux*[^g])
             libc.so.6
             libthread_db.so.1
             libquadmath.so.0.0.0
             libstdc++.so.6.0.32
             libitm.so.1.0.0
             libatomic.so.1.2.0"

cd /usr/lib

for LIB in $save_usrlib; do
    objcopy --only-keep-debug $LIB $LIB.dbg
    cp $LIB /tmp/$LIB
    strip --strip-unneeded /tmp/$LIB
    objcopy --add-gnu-debuglink=$LIB.dbg /tmp/$LIB
    install -vm755 /tmp/$LIB /usr/lib
    rm /tmp/$LIB
done

online_usrbin="bash find strip"
online_usrlib="libbfd-2.41.so
               libsframe.so.1.0.0
               libhistory.so.8.2
               libncursesw.so.6.4
               libm.so.6
               libreadline.so.8.2
               libz.so.1.2.13
               $(cd /usr/lib; find libnss*.so* -type f)"

for BIN in $online_usrbin; do
    cp /usr/bin/$BIN /tmp/$BIN
    strip --strip-unneeded /tmp/$BIN
    install -vm755 /tmp/$BIN /usr/bin
    rm /tmp/$BIN
done

for LIB in $online_usrlib; do
    cp /usr/lib/$LIB /tmp/$LIB
    strip --strip-unneeded /tmp/$LIB
    install -vm755 /tmp/$LIB /usr/lib
    rm /tmp/$LIB
done

for i in $(find /usr/lib -type f -name \*.so* ! -name \*dbg) \
         $(find /usr/lib -type f -name \*.a)                 \
         $(find /usr/{bin,sbin,libexec} -type f); do
    case "$online_usrbin $online_usrlib $save_usrlib" in
        *$(basename $i)* )
            ;;
        * ) strip --strip-unneeded $i
            ;;
    esac
done

unset BIN LIB save_usrlib online_usrbin online_usrlib

# --------------------------------------------------
# 8.82. Cleaning Up
# --------------------------------------------------

rm -rf /tmp/*
find /usr/lib /usr/libexec -name \*.la -delete
find /usr -depth -name $(uname -m)-lfs-linux-gnu\* | xargs rm -rf
userdel -r tester
