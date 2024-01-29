#!/bin/bash

ARCH=$1
PYTHON_FULL_VER=$2
PYTHON_VER=$(echo ${PYTHON_FULL_VER} | cut -d "." -f 1-2)

set -ex
zig version

WORKDIR=$(pwd)
BUILDDIR=${WORKDIR}/build
DEPSDIR=${WORKDIR}/deps

trap "cd ${BUILDDIR}/python-build && tar -czf ${WORKDIR}/build-python-${PYTHON_FULL_VER}-linux-${ARCH}.tar.gz ." EXIT

########################
# Install dependencies #
########################
echo "::group::Install dependencies"

export DEBIAN_FRONTEND=noninteractive
sudo apt update
sudo apt -y install \
  wget build-essential pkg-config cmake autoconf git \
  python2 python3 python3-pip clang patchelf qemu-user-static \
  gettext bison libtool autopoint gperf
case "$ARCH" in
  x86_64)
    sudo apt -y install libc6-amd64-cross
    sudo ln -s /usr/x86_64-linux-gnu/lib/ld-linux-x86-64.so.2 /lib/ld-linux-x86-64.so.2
    ;;
  aarch64)
    sudo apt -y install libc6-arm64-cross
    sudo ln -s /usr/aarch64-linux-gnu/lib/ld-linux-aarch64.so.1 /lib/ld-linux-aarch64.so.1
    ;;
  arm)
    sudo apt -y install libc6-armhf-cross
    sudo ln -s /usr/arm-linux-gnueabihf/lib/ld-linux-armhf.so.3 /lib/ld-linux-armhf.so.3
    ;;
esac
sudo pip install https://github.com/mesonbuild/meson/archive/2baae24.zip ninja

mkdir ${BUILDDIR}
mkdir ${DEPSDIR}

export ZIG_TARGET=${ARCH}-linux-gnu.2.17

# Python's sysconfig module will retain references to these compiler values, which cause
# problems when sysconfig is used to pick a compiler during binary extension builds.
# Since clang (zig) is a drop-in replacement for gcc, we set these so the final sysconfig
# will work on other platforms.
sudo cp ${WORKDIR}/zigshim/zig_ar /usr/bin/${ARCH}-linux-gnu-gcc-ar
sudo cp ${WORKDIR}/zigshim/zig_cc /usr/bin/${ARCH}-linux-gnu-gcc
sudo cp ${WORKDIR}/zigshim/zig_cxx /usr/bin/${ARCH}-linux-gnu-g++

export AR="${ARCH}-linux-gnu-gcc-ar"
export CC="${ARCH}-linux-gnu-gcc"
export CXX="${ARCH}-linux-gnu-g++"
export CHOST=${ARCH}

echo "::endgroup::"
########
# zlib #
########
echo "::group::zlib"
cd ${BUILDDIR}

wget -q https://zlib.net/fossils/zlib-1.3.tar.gz
tar -xf zlib*.tar.gz
rm *.tar.gz
cd zlib*
./configure --prefix=${DEPSDIR}
make -j4
make install

echo "::endgroup::"
###########
# OpenSSL #
###########
echo "::group::OpenSSL"
cd ${BUILDDIR}

wget -q https://github.com/openssl/openssl/archive/refs/tags/OpenSSL_1_1_1w.tar.gz
tar -xf OpenSSL*.tar.gz
rm *.tar.gz
cd openssl-OpenSSL*
./Configure linux-${ARCH} no-shared --prefix=${DEPSDIR} --openssldir=${DEPSDIR}
make -j4
make install_sw

echo "::endgroup::"
##########
# libffi #
##########
echo "::group::libffi"
cd ${BUILDDIR}

wget -q https://github.com/libffi/libffi/releases/download/v3.4.2/libffi-3.4.2.tar.gz
tar -xf libffi*.tar.gz
rm *.tar.gz
cd libffi*
./configure --host=${ARCH}-linux --prefix=${DEPSDIR}
make -j4
make install

echo "::endgroup::"
###########
# sqlite3 #
###########
echo "::group::sqlite3"
cd ${BUILDDIR}

wget -q https://www.sqlite.org/2024/sqlite-autoconf-3450000.tar.gz
tar -xf sqlite*.tar.gz
rm *.tar.gz
cd sqlite*
./configure --host=${ARCH}-linux --prefix=${DEPSDIR}
make -j4
make install

echo "::endgroup::"
#########
# expat #
#########
echo "::group::expat"
cd ${BUILDDIR}

wget -q https://github.com/libexpat/libexpat/releases/download/R_2_5_0/expat-2.5.0.tar.gz
tar -xf expat*.tar.gz
rm *.tar.gz
cd expat*
./configure --host=${ARCH}-linux --prefix=${DEPSDIR}
make -j4
make install

echo "::endgroup::"
############
# readline #
############
echo "::group::readline"
cd ${BUILDDIR}

wget -q https://ftp.gnu.org/gnu/readline/readline-8.2.tar.gz
tar -xf readline*.tar.gz
rm *.tar.gz
cd readline*
./configure --host=${ARCH}-linux --prefix=${DEPSDIR}
make -j4
make install

echo "::endgroup::"
###########
# ncurses #
###########
echo "::group::ncurses"
cd ${BUILDDIR}

wget -q https://ftp.gnu.org/pub/gnu/ncurses/ncurses-6.4.tar.gz
tar -xf ncurses*.tar.gz
rm *.tar.gz
cd ncurses*
./configure --host=${ARCH}-linux --with-normal --enable-overwrite --disable-stripping --prefix=${DEPSDIR}
make -j4
make install

echo "::endgroup::"
#########
# bzip2 #
#########
echo "::group::bzip2"
cd ${BUILDDIR}

wget -q -O bzip2.tar.gz https://github.com/commontk/bzip2/tarball/master
tar -xf bzip2*.tar.gz
rm *.tar.gz
cd commontk-bzip2*
mkdir build
cd build
cmake -DCMAKE_SYSTEM_PROCESSOR=${ARCH} -DCMAKE_INSTALL_PREFIX:PATH=${DEPSDIR} ..
make -j4
make install

echo "::endgroup::"
######
# xz #
######
echo "::group::xz"
cd ${BUILDDIR}

wget -q https://github.com/tukaani-project/xz/releases/download/v5.4.5/xz-5.4.5.tar.gz
tar -xf xz*.tar.gz
rm *.tar.gz
cd xz*
mkdir build
cd build
cmake -DCMAKE_SYSTEM_PROCESSOR=${ARCH} -DCMAKE_INSTALL_PREFIX:PATH=${DEPSDIR} ..
make -j4
make install

echo "::endgroup::"
########
# uuid #
########
echo "::group::uuid"
cd ${BUILDDIR}

wget -q https://github.com/util-linux/util-linux/archive/refs/tags/v2.39.3.tar.gz
tar -xf *.tar.gz
cd util-linux*
./autogen.sh
./configure --host=${ARCH}-linux --disable-all-programs --enable-libuuid --prefix=${DEPSDIR}
make -j4
make install

echo "::endgroup::"
########
# gdbm #
########
echo "::group::gdbm"
cd ${BUILDDIR}

wget -q https://ftp.gnu.org/gnu/gdbm/gdbm-1.23.tar.gz
tar -xf gdbm*.tar.gz
rm *.tar.gz
cd gdbm*
./configure --host=${ARCH}-linux --enable-libgdbm-compat --prefix=${DEPSDIR}
make -j4
make install

echo "::endgroup::"
###########
# libxml2 #
###########
echo "::group::libxml2"
cd ${BUILDDIR}

wget -q https://download.gnome.org/sources/libxml2/2.12/libxml2-2.12.4.tar.xz
tar -xf libxml2*.tar.xz
rm *.tar.xz
cd libxml2*
CFLAGS="-I${DEPSDIR}/include" LDFLAGS="-L${DEPSDIR}/lib" ./configure --host=${ARCH}-linux --without-python --prefix=${DEPSDIR}
make -j4
make install

echo "::endgroup::"
#############
# libgcrypt #
#############
echo "::group::libgcrypt"
cd ${BUILDDIR}

wget -q https://gnupg.org/ftp/gcrypt/libgpg-error/libgpg-error-1.47.tar.bz2
tar -xf libgpg-error*.tar.bz2
rm *.tar.bz2
cd libgpg-error*
./configure --host=${ARCH}-linux --prefix=${DEPSDIR}
make -j4
make install

cd ${BUILDDIR}

wget -q https://www.gnupg.org/ftp/gcrypt/libgcrypt/libgcrypt-1.8.11.tar.bz2
tar -xf libgcrypt*.tar.bz2
rm *.tar.bz2
cd libgcrypt*
./configure --host=${ARCH}-linux --prefix=${DEPSDIR}
make -j4
make install

echo "::endgroup::"
###########
# libxslt #
###########
echo "::group::libxslt"
cd ${BUILDDIR}

wget -q https://download.gnome.org/sources/libxslt/1.1/libxslt-1.1.39.tar.xz
tar -xf libxslt*.tar.xz
rm *.tar.xz
cd libxslt*
CFLAGS="-I${DEPSDIR}/include -I${DEPSDIR}/include/libxml2" LDFLAGS="-L${DEPSDIR}/lib" ./configure --host=${ARCH}-linux --with-libxml-prefix=${DEPSDIR} --without-python --prefix=${DEPSDIR}
make -j4
make install

echo "::endgroup::"
############
# freetype #
############
echo "::group::freetype"
cd ${BUILDDIR}

wget -q https://download.savannah.gnu.org/releases/freetype/freetype-2.13.2.tar.gz
tar -xf freetype*.tar.gz
rm *.tar.gz
cd freetype*
CFLAGS="-I${DEPSDIR}/include" LDFLAGS="-L${DEPSDIR}/lib" ./configure --host=${ARCH}-linux --prefix=${DEPSDIR}
make -j4
make install

echo "::endgroup::"
##############
# fontconfig #
##############
echo "::group::fontconfig"
cd ${BUILDDIR}

wget -q https://www.freedesktop.org/software/fontconfig/release/fontconfig-2.15.0.tar.gz
tar -xf fontconfig*.tar.gz
rm *.tar.gz
cd fontconfig*
CFLAGS="-I${DEPSDIR}/include" LDFLAGS="-L${DEPSDIR}/lib"  PKG_CONFIG_PATH="${DEPSDIR}/lib/pkgconfig" ./configure --host=${ARCH}-linux --enable-libxml2 --disable-cache-build --prefix=${DEPSDIR}
make -j4
make install

echo "::endgroup::"
#######
# X11 #
#######
echo "::group::X11"
cd ${BUILDDIR}

wget -q https://www.x.org/releases/individual/lib/libXau-1.0.11.tar.gz
wget -q https://www.x.org/releases/individual/lib/libXdmcp-1.1.2.tar.gz
wget -q https://www.x.org/releases/individual/lib/libX11-1.8.7.tar.gz
wget -q https://www.x.org/releases/individual/lib/libXext-1.3.5.tar.gz
wget -q https://www.x.org/releases/individual/lib/libICE-1.0.7.tar.gz
wget -q https://www.x.org/releases/individual/lib/libSM-1.2.2.tar.gz
wget -q https://www.x.org/releases/individual/lib/libXrender-0.9.11.tar.gz
wget -q https://www.x.org/releases/individual/lib/libXft-2.3.8.tar.gz
wget -q https://www.x.org/releases/individual/lib/libXScrnSaver-1.2.4.tar.gz
wget -q https://www.x.org/releases/individual/lib/xtrans-1.5.0.tar.gz
wget -q https://www.x.org/releases/individual/proto/xproto-7.0.31.tar.gz
wget -q https://www.x.org/releases/individual/proto/xextproto-7.3.0.tar.gz
wget -q https://www.x.org/releases/individual/proto/xcb-proto-1.16.0.tar.gz
wget -q https://www.x.org/releases/individual/proto/kbproto-1.0.7.tar.gz
wget -q https://www.x.org/releases/individual/proto/inputproto-2.3.2.tar.gz
wget -q https://www.x.org/releases/individual/proto/renderproto-0.11.1.tar.gz
wget -q https://www.x.org/releases/individual/proto/scrnsaverproto-1.2.2.tar.gz
wget -q https://www.x.org/releases/individual/xcb/libxcb-1.16.tar.gz
wget -q https://www.x.org/releases/individual/xcb/libpthread-stubs-0.5.tar.gz
git clone git://anongit.freedesktop.org/git/xorg/util/modular util/modular
CFLAGS="-I${DEPSDIR}/include" LDFLAGS="-L${DEPSDIR}/lib" ./util/modular/build.sh --modfile ${WORKDIR}/scripts/x11_modfile.txt ${DEPSDIR}
rm *.tar.gz

echo "::endgroup::"
#######
# tcl #
#######
echo "::group::tcl"
cd ${BUILDDIR}

wget -q https://prdownloads.sourceforge.net/tcl/tcl8.6.13-src.tar.gz
tar -xf tcl*.tar.gz
rm *.tar.gz
cd tcl*/unix
./configure --host=${ARCH}-linux --prefix=${DEPSDIR}
make -j4
make install

echo "::endgroup::"
######
# tk #
######
echo "::group::tk"
cd ${BUILDDIR}

wget -q https://prdownloads.sourceforge.net/tcl/tk8.6.13-src.tar.gz
tar -xf tk*.tar.gz
rm *.tar.gz
cd tk*/unix
CFLAGS="-I${DEPSDIR}/include" ./configure --host=${ARCH}-linux --prefix=${DEPSDIR}
make -j4
make install

echo "::endgroup::"
#############
# mpdecimal #
#############
echo "::group::mpdecimal"
cd ${BUILDDIR}

wget -q https://www.bytereef.org/software/mpdecimal/releases/mpdecimal-2.5.0.tar.gz
tar -xzf mpdecimal*.tar.gz
cd mpdecimal-2.5.0
./configure --disable-cxx --host=${ARCH}-linux --prefix=${DEPSDIR}
make -j4
make install

echo "::endgroup::"
##########
# Python #
##########
echo "::group::Python"
cd ${BUILDDIR}

if [[ "${RUN_TESTS}" == "true" ]]; then
  INSTALL_TEST="ON"
else
  INSTALL_TEST="OFF"
fi

wget -q -O python-cmake-buildsystem.tar.gz https://github.com/bjia56/python-cmake-buildsystem/tarball/portable-python
tar -xf python-cmake-buildsystem.tar.gz
rm *.tar.gz
mv *python-cmake-buildsystem* python-cmake-buildsystem
mkdir python-build
mkdir python-install
cd python-build
CFLAGS="-I${DEPSDIR}/include" cmake \
  -DCMAKE_SYSTEM_PROCESSOR=${ARCH} \
  -DCMAKE_CROSSCOMPILING_EMULATOR=${WORKDIR}/scripts/qemu_${ARCH}_interpreter \
  -DCMAKE_C_STANDARD=99 \
  -DPYTHON_VERSION=${PYTHON_FULL_VER} \
  -DCMAKE_BUILD_TYPE:STRING=Release \
  -DCMAKE_INSTALL_PREFIX:PATH=${BUILDDIR}/python-install \
  -DBUILD_EXTENSIONS_AS_BUILTIN=ON \
  -DBUILD_LIBPYTHON_SHARED=ON \
  -DUSE_SYSTEM_LIBRARIES=OFF \
  -DBUILD_TESTING=${INSTALL_TEST} \
  -DINSTALL_TEST=${INSTALL_TEST} \
  -DINSTALL_MANUAL=OFF \
  -DOPENSSL_INCLUDE_DIR:PATH=${DEPSDIR}/include \
  -DOPENSSL_LIBRARIES="${DEPSDIR}/lib/libssl.a;${DEPSDIR}/lib/libcrypto.a" \
  -DSQLite3_INCLUDE_DIR:PATH=${DEPSDIR}/include \
  -DSQLite3_LIBRARY:FILEPATH=${DEPSDIR}/lib/libsqlite3.a \
  -DZLIB_INCLUDE_DIR:PATH=${DEPSDIR}/include \
  -DZLIB_LIBRARY:FILEPATH=${DEPSDIR}/lib/libz.a \
  -DLZMA_INCLUDE_PATH:PATH=${DEPSDIR}/include \
  -DLZMA_LIBRARY:FILEPATH=${DEPSDIR}/lib/liblzma.a \
  -DBZIP2_INCLUDE_DIR:PATH=${DEPSDIR}/include \
  -DBZIP2_LIBRARIES:FILEPATH=${DEPSDIR}/lib/libbz2.a \
  -DLibFFI_INCLUDE_DIR:PATH=${DEPSDIR}/include \
  -DLibFFI_LIBRARY:FILEPATH=${DEPSDIR}/lib/libffi.a \
  -DREADLINE_INCLUDE_PATH:FILEPATH=${DEPSDIR}/include/readline/readline.h \
  -DREADLINE_LIBRARY:FILEPATH=${DEPSDIR}/lib/libreadline.a \
  -DUUID_LIBRARY:FILEPATH=${DEPSDIR}/lib/libuuid.a \
  -DCURSES_LIBRARIES:FILEPATH=${DEPSDIR}/lib/libncurses.a \
  -DPANEL_LIBRARIES:FILEPATH=${DEPSDIR}/lib/libpanel.a \
  -DGDBM_INCLUDE_PATH:FILEPATH=${DEPSDIR}/include/gdbm.h \
  -DGDBM_LIBRARY:FILEPATH=${DEPSDIR}/lib/libgdbm.a \
  -DGDBM_COMPAT_LIBRARY:FILEPATH=${DEPSDIR}/lib/libgdbm_compat.a \
  -DNDBM_TAG=NDBM \
  -DTK_INCLUDE_PATH:FILEPATH=${DEPSDIR}/include/tk.h \
  -DTK_LIBRARY:FILEPATH=${DEPSDIR}/lib/libtk8.6.a \
  -DTCL_INCLUDE_PATH:FILEPATH=${DEPSDIR}/include/tcl.h \
  -DTCL_LIBRARY:FILEPATH=${DEPSDIR}/lib/libtcl8.6.a \
  -DX11_INCLUDE_DIR:PATH=${DEPSDIR}/include/X11 \
  -DX11_LIBRARIES="${DEPSDIR}/lib/libXau.a;${DEPSDIR}/lib/libXdmcp.a;${DEPSDIR}/lib/libX11.a;${DEPSDIR}/lib/libXext.a;${DEPSDIR}/lib/libICE.a;${DEPSDIR}/lib/libSM.a;${DEPSDIR}/lib/libXrender.a;${DEPSDIR}/lib/libXft.a;${DEPSDIR}/lib/libXss.a" \
  ../python-cmake-buildsystem
make -j4
make install

echo "::endgroup::"
#############################################
# Check executable dependencies (pre-patch) #
#############################################
echo "::group::Check executable dependencies (pre-patch)"
cd ${BUILDDIR}

cd python-install
echo "python dependencies"
readelf -d ./bin/python
echo
echo "libpython dependencies"
readelf -d ./lib/libpython${PYTHON_VER}.so

echo "::endgroup::"
################
# Patch python #
################
echo "::group::Patch python"
cd ${BUILDDIR}

cd python-install
${WORKDIR}/scripts/patch_libpython.sh ./lib/libpython${PYTHON_VER}.so ./bin/python
patchelf --replace-needed libpython${PYTHON_VER}.so "\$ORIGIN/../lib/libpython${PYTHON_VER}.so" ./bin/python

echo "::endgroup::"
##############################################
# Check executable dependencies (post-patch) #
##############################################
echo "::group::Check executable dependencies (post-patch)"
cd ${BUILDDIR}

cd python-install
# we don't make ldd errors fatal here since ldd doesn't work
# when cross compiling
echo "python dependencies"
ldd -v -r ./bin/python || true
echo
echo "libpython dependencies"
ldd -v -r ./lib/libpython${PYTHON_VER}.so || true

echo "::endgroup::"
###############
# Test python #
###############
echo "::group::Test python"
cd ${BUILDDIR}

cd python-install
qemu-${ARCH}-static ./bin/python --version

echo "::endgroup::"
###############
# Preload pip #
###############
echo "::group::Preload pip"
cd ${BUILDDIR}

cd python-install
qemu-${ARCH}-static ./bin/python -m ensurepip

echo "::endgroup::"
###################
# Compress output #
###################
echo "::group::Compress output"
cd ${BUILDDIR}

python3 -m pip install pyclean
python3 -m pyclean -v python-install
mv python-install python-${PYTHON_FULL_VER}-linux-${ARCH}
tar -czf ${WORKDIR}/python-${PYTHON_FULL_VER}-linux-${ARCH}.tar.gz python-${PYTHON_FULL_VER}-linux-${ARCH}
zip ${WORKDIR}/python-${PYTHON_FULL_VER}-linux-${ARCH}.zip $(tar tf ${WORKDIR}/python-${PYTHON_FULL_VER}-linux-${ARCH}.tar.gz)

echo "::endgroup::"
