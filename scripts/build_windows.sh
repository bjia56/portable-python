#!/bin/bash

ARCH=$1
PYTHON_FULL_VER=$2

WORKDIR=$(pwd)

set -ex

##############
# Initialize #
##############
echo "::group::Initialize"

mkdir python-build
mkdir python-install
mkdir deps

git clone https://github.com/bjia56/python-cmake-buildsystem.git --branch python3.10 --single-branch --depth 1
#git clone https://github.com/python-cmake-buildsystem/python-cmake-buildsystem.git

echo "::endgroup::"
###########
# OpenSSL #
###########
echo "::group::OpenSSL"
cd ${WORKDIR}

curl -L https://github.com/Slicer/Slicer-OpenSSL/releases/download/1.1.1g/OpenSSL_1_1_1g-install-msvc1900-64-Release.tar.gz --output openssl.tar.gz
tar -xf openssl.tar.gz
mv OpenSSL_1_1_1g-install-msvc1900-64-Release deps/openssl

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
  -G "Visual Studio 17 2022" -A x64 \
  -DCMAKE_INSTALL_PREFIX:PATH=${WORKDIR}/deps/bzip2 \
  ..
cmake --build . --config Release -- /property:Configuration=Release
cmake --build . --target INSTALL -- /property:Configuration=Release

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
  -G "Visual Studio 17 2022" -A x64 \
  -DCMAKE_INSTALL_PREFIX:PATH=${WORKDIR}/deps/xz \
  ..
cmake --build . --config Release -- /property:Configuration=Release
cmake --build . --target INSTALL -- /property:Configuration=Release

echo "::endgroup::"
###########
# sqlite3 #
###########
echo "::group::sqlite3"
cd ${WORKDIR}

curl -L https://www.sqlite.org/2023/sqlite-amalgamation-3430100.zip --output sqlite3-src.zip
unzip sqlite3-src.zip
mv sqlite-amalgamation-3430100 deps/sqlite3
cd deps/sqlite3
cl //c sqlite3.c
lib sqlite3.obj

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
  -G "Visual Studio 17 2022" -A x64 \
  -DCMAKE_INSTALL_PREFIX:PATH=${WORKDIR}/deps/zlib \
  ..
cmake --build . --config Release -- /property:Configuration=Release
cmake --build . --target INSTALL -- /property:Configuration=Release

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
  -G "Visual Studio 17 2022" -A x64 \
  -DCMAKE_INSTALL_PREFIX:PATH=${WORKDIR}/deps/libffi \
  ..
cmake --build . --config Release -- /property:Configuration=Release
cmake --build . --target INSTALL -- /property:Configuration=Release

echo "::endgroup::"
#########
# Build #
#########
echo "::group::Build"
cd ${WORKDIR}

cd python-build
cmake \
  -G "Visual Studio 17 2022" -A x64 \
  -DCMAKE_C_STANDARD=99 \
  -DPYTHON_VERSION=${PYTHON_FULL_VER} \
  -DCMAKE_BUILD_TYPE:STRING=Release \
  -DCMAKE_INSTALL_PREFIX:PATH=${WORKDIR}/python-install \
  -DBUILD_EXTENSIONS_AS_BUILTIN=OFF \
  -DBUILD_LIBPYTHON_SHARED=ON \
  -DBUILD_TESTING=ON \
  -DINSTALL_TEST=OFF \
  -DINSTALL_MANUAL=OFF \
  -DBUILD_WININST=OFF \
  -DINSTALL_WINDOWS_TRADITIONAL:BOOL=OFF \
  -DOPENSSL_ROOT_DIR:PATH=${WORKDIR}/deps/openssl \
  -DSQLite3_INCLUDE_DIR:PATH=${WORKDIR}/deps/sqlite3 \
  -DSQLite3_LIBRARY:FILEPATH=${WORKDIR}/deps/sqlite3/sqlite3.lib \
  -DZLIB_INCLUDE_DIR:PATH=${WORKDIR}/deps/zlib/include \
  -DZLIB_LIBRARY:FILEPATH=${WORKDIR}/deps/zlib/lib/zlibstatic.lib \
  -DLZMA_INCLUDE_PATH:PATH=${WORKDIR}/deps/xz/include \
  -DLZMA_LIBRARY:FILEPATH=${WORKDIR}/deps/xz/lib/liblzma.lib \
  -DBZIP2_INCLUDE_DIR:PATH=${WORKDIR}/deps/bzip2/include \
  -DBZIP2_LIBRARIES:FILEPATH=${WORKDIR}/deps/bzip2/lib/libbz2.lib \
  -DLibFFI_INCLUDE_DIR:PATH=${WORKDIR}/deps/libffi/include \
  -DLibFFI_LIBRARY:FILEPATH=${WORKDIR}/deps/libffi/lib/ffi_static.lib \
  ../python-cmake-buildsystem
cmake --build . --config Release -- /property:Configuration=Release
cmake --build . --target INSTALL -- /property:Configuration=Release
cd ${WORKDIR}

# Need to bundle openssl with the executable
cp deps/openssl/bin/*.dll python-install/bin

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
tar -czf ../build-python-${PYTHON_FULL_VER}-windows-${ARCH}.tar.gz .
cd ${WORKDIR}
python3 -m pip install pyclean
python3 -m pyclean -v python-install
mv python-install python-${PYTHON_FULL_VER}-windows-${ARCH}
tar -czf python-${PYTHON_FULL_VER}-windows-${ARCH}.tar.gz python-${PYTHON_FULL_VER}-windows-${ARCH}

echo "::endgroup::"
