#!/bin/bash

ARCH=$1
PYTHON_FULL_VER=$2
PYTHON_VER=$(echo ${PYTHON_FULL_VER} | cut -d "." -f 1-2)

WORKDIR=$(pwd)
NPROC=$(sysctl -n hw.ncpu)

set -ex

##############
# Initialize #
##############
echo "::group::Initialize"

mkdir python-build
mkdir python-install
mkdir deps

export MACOSX_DEPLOYMENT_TARGET=11

git clone https://github.com/bjia56/python-cmake-buildsystem.git --branch macos-arm64 --single-branch --depth 1

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
CC=${WORKDIR}/scripts/cc ./Configure enable-rc5 zlib no-asm darwin64-x86_64-cc --prefix=${WORKDIR}/deps/openssl
make -j${NPROC}
make install_sw

file ${WORKDIR}/deps/openssl/lib/libcrypto.a
file ${WORKDIR}/deps/openssl/lib/libssl.a

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
  "-DCMAKE_OSX_ARCHITECTURES=arm64;x86_64" \
  -DCMAKE_INSTALL_PREFIX:PATH=${WORKDIR}/deps/bzip2 \
  ..
make -j${NPROC}
make install

file ${WORKDIR}/deps/bzip2/lib/libbz2.a

echo "::endgroup::"
########
# lzma #
########
echo "::group::lzma"
cd ${WORKDIR}

git clone https://github.com/tukaani-project/xz.git --branch v5.4.4 --single-branch --depth 1
mkdir deps/xz
cd xz
mkdir build
cd build
cmake \
  -G "Unix Makefiles" \
  "-DCMAKE_OSX_ARCHITECTURES=arm64;x86_64" \
  -DCMAKE_INSTALL_PREFIX:PATH=${WORKDIR}/deps/xz \
  ..
make -j${NPROC}
make install

file ${WORKDIR}/deps/xz/lib/liblzma.a

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
CC=clang CFLAGS="-arch x86_64 -arch arm64" ./configure --prefix ${WORKDIR}/deps/sqlite3
make -j${NPROC}
make install

file ${WORKDIR}/deps/sqlite3/lib/libsqlite3.a

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
  "-DCMAKE_OSX_ARCHITECTURES=arm64;x86_64" \
  -DCMAKE_INSTALL_PREFIX:PATH=${WORKDIR}/deps/zlib \
  ..
make -j${NPROC}
make install

file ${WORKDIR}/deps/zlib/lib/libz.a

echo "::endgroup::"
##########
# libffi #
##########
echo "::group::libffi"
cd ${WORKDIR}

wget -q https://github.com/libffi/libffi/releases/download/v3.4.2/libffi-3.4.2.tar.gz
tar -xf libffi-3.4.2.tar.gz
mkdir deps/libffi
cp -r libffi-3.4.2 libffi-3.4.2-arm64
cd libffi-3.4.2
CC="/usr/bin/cc" ./configure --prefix ${WORKDIR}/deps/libffi
make -j${NPROC}
make install
cd ${WORKDIR}
mkdir libffi-arm64-out
cd libffi-3.4.2-arm64
CC="/usr/bin/cc" CFLAGS="-target arm64-apple-macos11" ./configure --prefix ${WORKDIR}/libffi-arm64-out --build=aarch64-apple-darwin --host=aarch64
make -j${NPROC}
make install

cd ${WORKDIR}
lipo -create -output libffi.a ${WORKDIR}/deps/libffi/lib/libffi.a ${WORKDIR}/libffi-arm64-out/lib/libffi.a
mv libffi.a ${WORKDIR}/deps/libffi/lib/libffi.a

file ${WORKDIR}/deps/libffi/lib/libffi.a

echo "::endgroup::"
#########
# Build #
#########
echo "::group::Build"
cd ${WORKDIR}

cd python-build
cmake \
  -G "Unix Makefiles" \
   "-DCMAKE_OSX_ARCHITECTURES=arm64;x86_64" \
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
#########################
# Test and patch python #
#########################
echo "::group::Test and patch python"
cd ${WORKDIR}

./python-install/bin/python --version

otool -L ./python-install/bin/python 
install_name_tool -add_rpath @executable_path/../lib ./python-install/bin/python
install_name_tool -change ${WORKDIR}/python-install/lib/libpython${PYTHON_VER} @rpath/libpython${PYTHON_VER} ./python-install/bin/python
otool -L ./python-install/bin/python 

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
