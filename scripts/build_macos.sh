#!/bin/bash

ARCH=$1
PYTHON_FULL_VER=$2

WORKDIR=$(pwd)
NPROC=$(sysctl -n hw.logicalcpu)

set -ex

##############
# Initialize #
##############
echo "::group::Initialize"

mkdir python-build
mkdir python-install
mkdir deps

export MACOSX_DEPLOYMENT_TARGET=11
export CC=${WORKDIR}/scripts/cc

git clone https://github.com/python-cmake-buildsystem/python-cmake-buildsystem.git

echo "::endgroup::"
###########
# OpenSSL #
###########
echo "::group::OpenSSL"
cd ${WORKDIR}

wget -q https://www.openssl.org/source/openssl-1.1.1w.tar.gz
tar -xf openssl-1.1.1w.tar.gz

mkdir deps/openssl
cd openssl-1.1.1w
./Configure enable-rc5 zlib no-asm darwin64-x86_64-cc --prefix=${WORKDIR}/deps/openssl
make -j${NPROC}
make install

echo "::endgroup::"
#########
# bzip2 #
#########
echo "::group::bzip2"
cd ${WORKDIR}

git clone https://github.com/commontk/bzip2.git --branch master --single-branch --depth 1
mkdir deps/bzip2
cd bzip2
mkdir build
cd build
cmake \
  -G "Unix Makefiles" \
  -DCMAKE_C_COMPILER=${CC} \
  -DCMAKE_INSTALL_PREFIX:PATH=${WORKDIR}/deps/bzip2 \
  ..
make -j${NPROC}
make install

echo "::endgroup::"
########
# lzma #
########
echo "::group::lzma"
cd ${WORKDIR}

wget -q https://github.com/tukaani-project/xz/releases/download/v5.4.4/xz-5.4.4.tar.gz
tar -xf xz-5.4.4.tar.gz
mkdir deps/xz
cd xz-5.4.4
./configure --prefix ${WORKDIR}/deps/xz
make -j${NPROC}
make install

echo "::endgroup::"
###########
# sqlite3 #
###########
echo "::group::sqlite3"
cd ${WORKDIR}

wget -q https://www.sqlite.org/2023/sqlite-autoconf-3430100.tar.gz
tar -xf sqlite-autoconf-3430100.tar.gz
mkdir deps/sqlite3
cd sqlite-autoconf-3430100
./configure --prefix ${WORKDIR}/deps/sqlite3
make -j${NPROC}
make install

echo "::endgroup::"
########
# zlib #
########
echo "::group::zlib"
cd ${WORKDIR}

curl -L https://zlib.net/zlib13.zip --output zlib.zip
unzip zlib.zip
mkdir deps/zlib
cd zlib-1.3
mkdir build
cd build
cmake \
  -G "Unix Makefiles" \
  -DCMAKE_C_COMPILER=${CC} \
  -DCMAKE_INSTALL_PREFIX:PATH=${WORKDIR}/deps/zlib \
  ..
make -j${NPROC}
make install

echo "::endgroup::"
##########
# libffi #
##########
echo "::group::libffi"
cd ${WORKDIR}

git clone https://github.com/python-cmake-buildsystem/libffi.git --branch libffi-cmake-buildsystem-v3.4.2-2021-06-28-f9ea416 --single-branch --depth 1
mkdir deps/libffi
cd libffi
mkdir build
cd build
cmake \
  -G "Unix Makefiles" \
  -DCMAKE_C_COMPILER=${CC} \
  -DCMAKE_INSTALL_PREFIX:PATH=${WORKDIR}/deps/libffi \
  ..
make -j${NPROC}
make install

echo "::endgroup::"
#########
# Build #
#########
echo "::group::Build"
cd ${WORKDIR}

cd python-build
cmake \
  -G "Unix Makefiles" \
  -DCMAKE_C_COMPILER=${CC} \
  -DCMAKE_C_STANDARD=99 \
  -DPYTHON_VERSION=${PYTHON_FULL_VER} \
  -DCMAKE_BUILD_TYPE:STRING=Release \
  -DCMAKE_INSTALL_PREFIX:PATH=${WORKDIR}/python-install \
  -DBUILD_EXTENSIONS_AS_BUILTIN=OFF \
  -DBUILD_LIBPYTHON_SHARED=ON \
  -DBUILD_TESTING=ON \
  -DOPENSSL_ROOT_DIR:PATH=${WORKDIR}/deps/openssl \
  -DSQLite3_INCLUDE_DIR:PATH=${WORKDIR}/deps/sqlite3/include \
  -DSQLite3_LIBRARY:FILEPATH=${WORKDIR}/deps/sqlite3/lib/libsqlite3.a \
  -DZLIB_INCLUDE_DIR:PATH=${WORKDIR}/deps/zlib/include \
  -DZLIB_LIBRARY:FILEPATH=${WORKDIR}/deps/zlib/lib/libz.a \
  -DLZMA_INCLUDE_PATH:PATH=${WORKDIR}/deps/xz/include \
  -DLZMA_LIBRARY:FILEPATH=${WORKDIR}/deps/xz/lib/liblzma.a \
  -DBZIP2_INCLUDE_DIR:PATH=${WORKDIR}/deps/bzip2/include \
  -DBZIP2_LIBRARIES:FILEPATH=${WORKDIR}/deps/bzip2/lib/libbz2.a \
  -DLibFFI_INCLUDE_DIR:PATH=${WORKDIR}/deps/libffi/include \
  -DLibFFI_LIBRARY:FILEPATH=${WORKDIR}/deps/libffi/lib/libffi.a \
  ../python-cmake-buildsystem
make -j${NPROC}
make install
cd ${WORKDIR}

echo "::endgroup::"
###############
# Test python #
###############
echo "::group::Test python"
cd ${WORKDIR}

./python-install/bin/python --version

echo "::endgroup::"
###############
# Preload pip #
###############
echo "::group::Preload pip"
cd ${WORKDIR}

./python-install/bin/python -m ensurepip

###################
# Compress output #
###################
echo "::group::Compress output"
cd ${WORKDIR}

cd python-build
tar -czf ../build-python-${PYTHON_FULL_VER}-darwin-${ARCH}.tar.gz .
cd ${WORKDIR}
mv python-install python-${PYTHON_FULL_VER}-darwin-${ARCH}
tar -czf python-${PYTHON_FULL_VER}-darwin-${ARCH}.tar.gz python-${PYTHON_FULL_VER}-darwin-${ARCH}

echo "::endgroup::"
