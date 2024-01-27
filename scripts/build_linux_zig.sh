#!/bin/bash

ARCH=$1
PYTHON_FULL_VER=$2
PYTHON_VER=$(echo ${PYTHON_FULL_VER} | cut -d "." -f 1-2)

set -ex

WORKDIR=$(pwd)
BUILDDIR=${WORKDIR}/build
DEPSDIR=${WORKDIR}/deps

trap "cd ${BUILDDIR}/python-build && tar -czf ${WORKDIR}/build-python-${PYTHON_FULL_VER}-linux-${ARCH}.tar.gz ." EXIT

########################
# Install dependencies #
########################
echo "::group::Install dependencies"

export DEBIAN_FRONTEND=noninteractive
apt update
apt -y install wget build-essential pkg-config cmake autoconf git python3 meson clang patchelf
case "$ARCH" in
  x86_64)
    apt -y install libc6-amd64-cross
    ;;
  aarch64)
    apt -y install libc6-arm64-cross
    ;;
  armv7l)
    apt -y install libc6-armhf-cross
    ;;
esac


cd /
wget -q https://ziglang.org/download/0.11.0/zig-linux-x86_64-0.11.0.tar.xz
tar -xf zig*.tar.xz
cd ${WORKDIR}

cp -r zigshim/* /zig-linux-x86_64-0.11.0
export PATH=${PATH}:/zig-linux-x86_64-0.11.0

mkdir ${BUILDDIR}
mkdir ${DEPSDIR}

export AR=zig_ar
export CC=zig_cc
export CXX=zig_cxx
export CHOST=${ARCH}

export TARGET=${ARCH}-linux-gnu.2.17
export ZIG_TARGET=${TARGET}

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

wget -q -O libuuid-cmake.tar.gz https://github.com/gershnik/libuuid-cmake/archive/refs/tags/v2.39.3.tar.gz
tar -xf libuuid*tar.gz
rm *.tar.gz
cd libuuid*
mkdir build
cd build
cmake -DCMAKE_SYSTEM_PROCESSOR=${ARCH} -DCMAKE_INSTALL_PREFIX:PATH=${DEPSDIR} -DLIBUUID_SHARED=OFF -DLIBUUID_STATIC=ON ..
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
#######
# tcl #
#######
echo "::group::tcl"
cd ${BUILDDIR}

#wget -q https://prdownloads.sourceforge.net/tcl/tcl8.6.13-src.tar.gz
#tar -xf tcl*.tar.gz
#rm *.tar.gz
#cd tcl*/unix
#./configure --host=${ARCH}-linux --prefix=${DEPSDIR}
#make -j4
#make install

echo "::endgroup::"
######
# tk #
######
echo "::group::tk"
cd ${BUILDDIR}

#wget -q https://prdownloads.sourceforge.net/tcl/tk8.6.13-src.tar.gz
#tar -xf tk*.tar.gz
#rm *.tar.gz
#cd tk*/unix
#CFLAGS="-I${DEPSDIR}/include" ./configure --host=${ARCH}-linux --prefix=${DEPSDIR}
#make -j4
#make install

echo "::endgroup::"
##########
# Python #
##########
echo "::group::Python"
cd ${BUILDDIR}

wget -q -O python-cmake-buildsystem.tar.gz https://github.com/bjia56/python-cmake-buildsystem/tarball/portable-python
tar -xf python-cmake-buildsystem.tar.gz
rm *.tar.gz
mv *python-cmake-buildsystem* python-cmake-buildsystem
mkdir python-build
mkdir python-install
cd python-build
CFLAGS="-I${DEPSDIR}/include" cmake \
    -DCMAKE_SYSTEM_PROCESSOR=${ARCH} \
    -DCMAKE_CROSSCOMPILING_EMULATOR=${WORKDIR}/scripts/qemu_interpreter \
    -DCMAKE_C_STANDARD=99 \
    -DPYTHON_VERSION=${PYTHON_FULL_VER} \
    -DCMAKE_BUILD_TYPE:STRING=Release \
    -DCMAKE_INSTALL_PREFIX:PATH=${BUILDDIR}/python-install \
    -DBUILD_EXTENSIONS_AS_BUILTIN=OFF \
    -DBUILD_LIBPYTHON_SHARED=ON \
    -DUSE_SYSTEM_LIBRARIES=OFF \
    -DBUILD_TESTING=ON \
    -DINSTALL_TEST=OFF \
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
    -DUUID_LIBRARY:FILEPATH=${DEPSDIR}/lib/libuuid_static.a \
    -DCURSES_LIBRARIES:FILEPATH=${DEPSDIR}/lib/libncurses.a \
    -DPANEL_LIBRARIES:FILEPATH=${DEPSDIR}/lib/libpanel.a \
    -DGDBM_INCLUDE_PATH:FILEPATH=${DEPSDIR}/include/gdbm.h \
    -DGDBM_LIBRARY:FILEPATH=${DEPSDIR}/lib/libgdbm.a \
    -DGDBM_COMPAT_LIBRARY:FILEPATH=${DEPSDIR}/lib/libgdbm_compat.a \
    -DNDBM_TAG=NDBM \
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
ldd -v -r ./bin/python
echo
echo "libpython dependencies"
ldd -v -r ./lib/libpython${PYTHON_VER}.so

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
# we don't make ldd errors fatal here since sometimes ldd can
# crash but the patched binaries still work
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
./bin/python --version

echo "::endgroup::"
###############
# Preload pip #
###############
echo "::group::Preload pip"
cd ${BUILDDIR}

cd python-install
./bin/python -m ensurepip

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