#!/bin/bash

PLATFORM=darwin
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
source ${SCRIPT_DIR}/utils.sh

NPROC=$(sysctl -n hw.ncpu)

set -ex

##############
# Initialize #
##############
echo "::group::Initialize"
cd ${BUILDDIR}

export MACOSX_DEPLOYMENT_TARGET=10.5

git clone https://github.com/bjia56/portable-python-cmake-buildsystem.git --branch python3.11 --single-branch --depth 1

echo "::endgroup::"
###########
# OpenSSL #
###########
echo "::group::OpenSSL"
cd ${BUILDDIR}

download_verify_extract openssl-1.1.1w.tar.gz

mkdir ${DEPSDIR}/openssl
cd openssl-1.1.1w
CC=${WORKDIR}/scripts/cc ./Configure enable-rc5 zlib no-asm darwin64-x86_64-cc --prefix=${DEPSDIR}/openssl
make -j${NPROC}
make install_sw
install_license

file ${DEPSDIR}/openssl/lib/libcrypto.a
file ${DEPSDIR}/openssl/lib/libssl.a

install_name_tool -change ${DEPSDIR}/openssl/lib/libcrypto.1.1.dylib @loader_path/libcrypto.1.1.dylib ${DEPSDIR}/openssl/lib/libssl.1.1.dylib

otool -l ${DEPSDIR}/openssl/lib/libssl.1.1.dylib
otool -l ${DEPSDIR}/openssl/lib/libcrypto.1.1.dylib

echo "::endgroup::"
#########
# bzip2 #
#########
echo "::group::bzip2"
cd ${BUILDDIR}

git clone https://github.com/commontk/bzip2.git --branch master --single-branch --depth 1
mkdir ${DEPSDIR}/bzip2
cd bzip2
mkdir build
cd build
cmake \
  -G "Unix Makefiles" \
  "-DCMAKE_OSX_ARCHITECTURES=arm64;x86_64" \
  -DCMAKE_OSX_DEPLOYMENT_TARGET=${MACOSX_DEPLOYMENT_TARGET} \
  -DCMAKE_INSTALL_PREFIX:PATH=${DEPSDIR}/bzip2 \
  ..
make -j${NPROC}
make install
cd ..
install_license

file ${DEPSDIR}/bzip2/lib/libbz2.a

echo "::endgroup::"
########
# lzma #
########
echo "::group::lzma"
cd ${BUILDDIR}

git clone https://github.com/tukaani-project/xz.git --branch v5.4.4 --single-branch --depth 1
mkdir ${DEPSDIR}/xz
cd xz
mkdir build
cd build
cmake \
  -G "Unix Makefiles" \
  "-DCMAKE_OSX_ARCHITECTURES=arm64;x86_64" \
  -DCMAKE_OSX_DEPLOYMENT_TARGET=${MACOSX_DEPLOYMENT_TARGET} \
  -DCMAKE_INSTALL_PREFIX:PATH=${DEPSDIR}/xz \
  ..
make -j${NPROC}
make install
cd ..
install_license

file ${DEPSDIR}/xz/lib/liblzma.a

echo "::endgroup::"
###########
# sqlite3 #
###########
echo "::group::sqlite3"
cd ${WORKDIR}

download_verify_extract sqlite-autoconf-3450000.tar.gz
mkdir ${DEPSDIR}/sqlite3
cd sqlite-autoconf-3450000
CC=clang CFLAGS="-arch x86_64 -arch arm64" ./configure --prefix ${DEPSDIR}/sqlite3
make -j${NPROC}
make install

file ${DEPSDIR}/sqlite3/lib/libsqlite3.a

echo "::endgroup::"
########
# zlib #
########
echo "::group::zlib"
cd ${BUILDDIR}

download_verify_extract zlib-1.3.1.tar.gz
mkdir ${DEPSDIR}/zlib
cd zlib-1.3.1
mkdir build
cd build
cmake \
  -G "Unix Makefiles" \
  "-DCMAKE_OSX_ARCHITECTURES=arm64;x86_64" \
  -DCMAKE_OSX_DEPLOYMENT_TARGET=${MACOSX_DEPLOYMENT_TARGET} \
  -DCMAKE_INSTALL_PREFIX:PATH=${DEPSDIR}/zlib \
  ..
make -j${NPROC}
make install
cd ..
install_license

file ${DEPSDIR}/zlib/lib/libz.a

echo "::endgroup::"
#########
# expat #
#########
echo "::group::expat"
cd ${BUILDDIR}

download_verify_extract expat-2.5.0.tar.gz
mkdir ${DEPSDIR}/expat
cd expat*
CC=clang CFLAGS="-arch x86_64 -arch arm64" ./configure --disable-shared --prefix=${DEPSDIR}/expat
make -j${NPROC}
make install
install_license

file ${DEPSDIR}/expat/lib/libexpat.a

echo "::endgroup::"
########
# gdbm #
########
echo "::group::gdbm"
cd ${BUILDDIR}

download_verify_extract gdbm-1.23.tar.gz
mkdir ${DEPSDIR}/gdbm
cd gdbm*
CC=clang CFLAGS="-arch x86_64 -arch arm64" ./configure --enable-libgdbm-compat --prefix=${DEPSDIR}/gdbm
make -j${NPROC}
make install
install_license

echo "::endgroup::"
##########
# libffi #
##########
echo "::group::libffi"
cd ${BUILDDIR}

wget -q https://github.com/libffi/libffi/releases/download/v3.4.2/libffi-3.4.2.tar.gz
tar -xf libffi-3.4.2.tar.gz
mkdir ${DEPSDIR}/libffi
cp -r libffi-3.4.2 libffi-3.4.2-arm64
cd libffi-3.4.2
CC="/usr/bin/cc" ./configure --prefix ${DEPSDIR}/libffi
make -j${NPROC}
make install
cd ${BUILDDIR}
mkdir libffi-arm64-out
cd libffi-3.4.2-arm64
CC="/usr/bin/cc" CFLAGS="-target arm64-apple-macos11" ./configure --prefix ${BUILDDIR}/libffi-arm64-out --build=aarch64-apple-darwin --host=aarch64
make -j${NPROC}
make install
install_license

cd ${BUILDDIR}
lipo -create -output libffi.a ${DEPSDIR}/libffi/lib/libffi.a ${BUILDDIR}/libffi-arm64-out/lib/libffi.a
mv libffi.a ${DEPSDIR}/libffi/lib/libffi.a

file ${DEPSDIR}/libffi/lib/libffi.a

echo "::endgroup::"
#########
# Build #
#########
echo "::group::Build"
cd ${BUILDDIR}

# TODO: build TCL

mkdir python-build
mkdir python-install
cd python-build
cmake \
  "${cmake_verbose_flags[@]}" \
  -G "Unix Makefiles" \
  "-DCMAKE_OSX_ARCHITECTURES=arm64;x86_64" \
  -DCMAKE_OSX_DEPLOYMENT_TARGET=${MACOSX_DEPLOYMENT_TARGET} \
  -DPYTHON_VERSION=${PYTHON_FULL_VER} \
  -DCMAKE_BUILD_TYPE:STRING=Release \
  -DCMAKE_INSTALL_PREFIX:PATH=${BUILDDIR}/python-install \
  -DBUILD_EXTENSIONS_AS_BUILTIN=OFF \
  -DBUILD_LIBPYTHON_SHARED=ON \
  -DBUILD_TESTING=${INSTALL_TEST} \
  -DINSTALL_TEST=${INSTALL_TEST} \
  -DINSTALL_MANUAL=OFF \
  -DOPENSSL_ROOT_DIR:PATH=${DEPSDIR}/openssl \
  -DUSE_SYSTEM_EXPAT=OFF \
  -DUSE_SYSTEM_TCL=OFF \
  -DEXPAT_INCLUDE_DIRS:PATH=${DEPSDIR}/expat/include \
  -DEXPAT_LIBRARIES:FILEPATH=${DEPSDIR}/expat/lib/libexpat.a \
  -DSQLite3_INCLUDE_DIR:PATH=${DEPSDIR}/sqlite3/include \
  -DSQLite3_LIBRARY:FILEPATH=${DEPSDIR}/sqlite3/lib/libsqlite3.a \
  -DZLIB_INCLUDE_DIR:PATH=${DEPSDIR}/zlib/include \
  -DZLIB_LIBRARY:FILEPATH=${DEPSDIR}/zlib/lib/libz.a \
  -DLZMA_INCLUDE_PATH:PATH=${DEPSDIR}/xz/include \
  -DLZMA_LIBRARY:FILEPATH=${DEPSDIR}/xz/lib/liblzma.a \
  -DBZIP2_INCLUDE_DIR:PATH=${DEPSDIR}/bzip2/include \
  -DBZIP2_LIBRARIES:FILEPATH=${DEPSDIR}/bzip2/lib/libbz2.a \
  -DLibFFI_INCLUDE_DIR:PATH=${DEPSDIR}/libffi/include \
  -DLibFFI_LIBRARY:FILEPATH=${DEPSDIR}/libffi/lib/libffi.a \
  -DGDBM_INCLUDE_PATH:FILEPATH=${DEPSDIR}/gdbm/include/gdbm.h \
  -DGDBM_LIBRARY:FILEPATH=${DEPSDIR}/gdbm/lib/libgdbm.a \
  -DGDBM_COMPAT_LIBRARY:FILEPATH=${DEPSDIR}/gdbm/lib/libgdbm_compat.a \
  -DNDBM_TAG=NDBM \
  -DNDBM_USE=NDBM \
  ../portable-python-cmake-buildsystem
make -j${NPROC}
make install
cp -r ${LICENSEDIR} ${BUILDDIR}/python-install
cd ${BUILDDIR}

echo "::endgroup::"
#########################
# Test and patch python #
#########################
echo "::group::Test and patch python"
cd ${BUILDDIR}

./python-install/bin/python --version
cp ${DEPSDIR}/openssl/lib/libssl.1.1.dylib ${BUILDDIR}/python-install/lib/python${PYTHON_VER}/lib-dynload/
cp ${DEPSDIR}/openssl/lib/libcrypto.1.1.dylib ${BUILDDIR}/python-install/lib/python${PYTHON_VER}/lib-dynload/

otool -l ./python-install/bin/python
install_name_tool -add_rpath @executable_path/../lib ./python-install/bin/python
install_name_tool -change ${BUILDDIR}/python-install/lib/libpython${PYTHON_VER}.dylib @rpath/libpython${PYTHON_VER}.dylib ./python-install/bin/python
install_name_tool -change ${DEPSDIR}/openssl/lib/libssl.1.1.dylib @loader_path/libssl.1.1.dylib ${BUILDDIR}/python-install/lib/python${PYTHON_VER}/lib-dynload/_ssl.so
install_name_tool -change ${DEPSDIR}/openssl/lib/libcrypto.1.1.dylib @loader_path/libcrypto.1.1.dylib ${BUILDDIR}/python-install/lib/python${PYTHON_VER}/lib-dynload/_ssl.so
otool -l ./python-install/bin/python
otool -l ./python-install/lib/python${PYTHON_VER}/lib-dynload/_ssl.so

./python-install/bin/python --version

echo "::endgroup::"
###############
# Preload pip #
###############
echo "::group::Preload pip"
cd ${BUILDDIR}

./python-install/bin/python -m ensurepip
./python-install/bin/python -m pip install -r ${WORKDIR}/baseline/requirements.txt

###################
# Compress output #
###################
echo "::group::Compress output"
cd ${BUILDDIR}

python3 -m pip install pyclean
python3 -m pyclean -v python-install
mv python-install python-${PYTHON_FULL_VER}-darwin-${ARCH}
tar -czf ${WORKDIR}/python-${PYTHON_FULL_VER}-darwin-${ARCH}.tar.gz python-${PYTHON_FULL_VER}-darwin-${ARCH}
zip ${WORKDIR}/python-${PYTHON_FULL_VER}-darwin-${ARCH}.zip $(tar tf ${WORKDIR}/python-${PYTHON_FULL_VER}-darwin-${ARCH}.tar.gz)

echo "::endgroup::"
