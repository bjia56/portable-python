#!/bin/bash

ARCH=$1
PYTHON_FULL_VER=$2
PYTHON_VER=$(echo ${PYTHON_FULL_VER} | cut -d "." -f 1-2)

set -ex

WORKDIR=$(pwd)
BUILDDIR=${WORKDIR}/build
DEPSDIR=${WORKDIR}/deps

apt update
apt -y install wget build-essential cmake lld

cd /
wget -q https://ziglang.org/download/0.11.0/zig-linux-x86_64-0.11.0.tar.xz
tar -xf zig*.tar.xz
cd ${WORKDIR}

cp -r zigshim/* /zig-linux-x86_64-0.11.0
export PATH=${PATH}:/zig-linux-x86_64-0.11.0

mkdir ${BUILDDIR}
mkdir ${DEPSDIR}
cd ${BUILDDIR}

export AR=zig_ar
export CC=zig_cc
export CXX=zig_cxx
#export LD=lld

export TARGET=${ARCH}-linux-gnu.2.17
export ZIG_TARGET=${TARGET}

wget -q https://zlib.net/fossils/zlib-1.3.tar.gz
tar -xf zlib*.tar.gz
rm *.tar.gz
cd zlib*
./configure --prefix=${DEPSDIR}
make -j4
make install
cd ${BUILDDIR}

wget -q https://github.com/openssl/openssl/archive/refs/tags/OpenSSL_1_1_1w.tar.gz
tar -xf OpenSSL*.tar.gz
rm *.tar.gz
cd openssl-OpenSSL*
./config no-shared --prefix=${DEPSDIR} --openssldir=${DEPSDIR}
make -j4
make install_sw
cd ${BUILDDIR}

wget -q https://github.com/libffi/libffi/releases/download/v3.4.2/libffi-3.4.2.tar.gz
tar -xf libffi*.tar.gz
rm *.tar.gz
cd libffi*
./configure --prefix=${DEPSDIR}
make -j4
make install
cd ${BUILDDIR}

wget -q https://www.sqlite.org/2024/sqlite-autoconf-3450000.tar.gz
tar -xf sqlite*.tar.gz
rm *.tar.gz
cd sqlite*
./configure --prefix=${DEPSDIR}
make -j4
make install
cd ${BUILDDIR}

wget -q https://ftp.gnu.org/gnu/readline/readline-8.2.tar.gz
tar -xf readline*.tar.gz
rm *.tar.gz
cd readline*
./configure --prefix=${DEPSDIR}
make -j4
make install
cd ${BUILDDIR}

wget -q https://ftp.gnu.org/pub/gnu/ncurses/ncurses-6.4.tar.gz
tar -xf ncurses*.tar.gz
rm *.tar.gz
cd ncurses*
./configure --prefix=${DEPSDIR}
make -j4
make install
cd ${BUILDDIR}

wget -q -O bzip2.tar.gz https://github.com/commontk/bzip2/tarball/master
tar -xf bzip2*.tar.gz
rm *.tar.gz
cd commontk-bzip2*
mkdir build
cd build
cmake -DCMAKE_INSTALL_PREFIX:PATH=${DEPSDIR} ..
make -j4
make install
cd ${BUILDDIR}

wget -q https://github.com/tukaani-project/xz/releases/download/v5.4.5/xz-5.4.5.tar.gz
tar -xf xz*.tar.gz
rm *.tar.gz
cd xz*
mkdir build
cd build
cmake -DCMAKE_INSTALL_PREFIX:PATH=${DEPSDIR} ..
make -j4
make install
cd ${BUILDDIR}

wget -q -O libuuid-cmake.tar.gz https://github.com/gershnik/libuuid-cmake/archive/refs/tags/v2.39.3.tar.gz
tar -xf libuuid*tar.gz
rm *.tar.gz
cd libuuid*
mkdir build
cd build
cmake -DCMAKE_INSTALL_PREFIX:PATH=${DEPSDIR} -DLIBUUID_SHARED=OFF -DLIBUUID_STATIC=ON ..
make -j4
make install
cd ${BUILDDIR}

wget -q https://ftp.gnu.org/gnu/gdbm/gdbm-1.23.tar.gz
tar -xf gdbm*.tar.gz
rm *.tar.gz
cd gdbm*
./configure --prefix=${DEPSDIR}
make -j4
make install
cd ${BUILDDIR}

wget -q https://prdownloads.sourceforge.net/tcl/tcl8.6.13-src.tar.gz
tar -xf tcl*.tar.gz
rm *.tar.gz
cd tcl*/unix
./configure --prefix=${DEPSDIR}
make -j4
make install
cd ${BUILDDIR}

export CFLAGS="-I${DEPSDIR}/include"
wget -q -O python-cmake-buildsystem.tar.gz https://github.com/bjia56/python-cmake-buildsystem/tarball/python3.10
tar -xf python-cmake-buildsystem.tar.gz
rm *.tar.gz
mv *python-cmake-buildsystem* python-cmake-buildsystem
mkdir python-build
mkdir python-install
cd python-build
cmake \
    -DCMAKE_C_STANDARD=99 \
    -DPYTHON_VERSION=${PYTHON_FULL_VER} \
    -DCMAKE_BUILD_TYPE:STRING=Release \
    -DCMAKE_INSTALL_PREFIX:PATH=/build/python-install \
    -DBUILD_EXTENSIONS_AS_BUILTIN=OFF \
    -DBUILD_LIBPYTHON_SHARED=ON \
    -DBUILD_TESTING=ON \
    -DINSTALL_TEST=OFF \
    -DINSTALL_MANUAL=OFF \
    -DOPENSSL_ROOT_DIR:PATH=${DEPSDIR} \
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
    -DGDBM_LIBRARY:FILEPATH=${DEPSDIR}/lib/libgdbm.a \
    ../python-cmake-buildsystem
make -j4
make install
