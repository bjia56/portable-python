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

export MACOSX_DEPLOYMENT_TARGET=10.9
export CFLAGS="-I${DEPSDIR}/include"
export CPPFLAGS="-I${DEPSDIR}/include"
export CXXFLAGS="${CPPFLAGS}"
export LDFLAGS="-L${DEPSDIR}/lib"
export PKG_CONFIG_PATH="${DEPSDIR}/lib/pkgconfig:${DEPSDIR}/share/pkgconfig"

git clone https://github.com/bjia56/portable-python-cmake-buildsystem.git --branch ${CMAKE_BUILDSYSTEM_BRANCH} --single-branch --depth 1

echo "::endgroup::"
###########
# ncurses #
###########
echo "::group::ncurses"
cd ${BUILDDIR}

download_verify_extract ncurses-6.4.tar.gz
cd ncurses*
CC=clang CXX=clang++ CFLAGS="${CFLAGS} -arch x86_64 -arch arm64" CXXFLAGS="${CXXFLAGS} -arch x86_64 -arch arm64" ./configure --with-normal --without-progs --enable-overwrite --disable-stripping --prefix=${DEPSDIR}
make -j4
make install.libs
install_license

echo "::endgroup::"
############
# readline #
############
echo "::group::readline"
cd ${BUILDDIR}

download_verify_extract readline-8.2.tar.gz
cd readline*
CC=clang CFLAGS="${CFLAGS} -arch x86_64 -arch arm64" ./configure --with-curses --disable-shared --prefix=${DEPSDIR}
make -j4
make install
install_license

echo "::endgroup::"
#######
# tcl #
#######
echo "::group::tcl"
cd ${BUILDDIR}

download_verify_extract tcl8.6.13-src.tar.gz
cd tcl*/unix
CC=clang CFLAGS="${CFLAGS} -arch x86_64 -arch arm64" ./configure --disable-shared --enable-aqua --prefix=${DEPSDIR}
make -j${NPROC}
make install
cd ..
install_license ./license.terms

echo "::endgroup::"
######
# tk #
######
echo "::group::tk"
cd ${BUILDDIR}

download_verify_extract tk8.6.13-src.tar.gz
cd tk*/unix
CC=clang CFLAGS="${CFLAGS} -arch x86_64 -arch arm64" ./configure --disable-shared --enable-aqua --prefix=${DEPSDIR}
make -j${NPROC}
make install
cd ..
install_license ./license.terms

echo "::endgroup::"
###########
# OpenSSL #
###########
echo "::group::OpenSSL"
cd ${BUILDDIR}

download_verify_extract openssl-1.1.1w.tar.gz
cd openssl-1.1.1w
CC=${WORKDIR}/scripts/cc ./Configure enable-rc5 zlib no-asm no-shared darwin64-x86_64-cc --prefix=${DEPSDIR}
make -j${NPROC}
make install_sw
install_license

file ${DEPSDIR}/lib/libcrypto.a
file ${DEPSDIR}/lib/libssl.a

echo "::endgroup::"
#########
# bzip2 #
#########
echo "::group::bzip2"
cd ${BUILDDIR}

git clone https://github.com/commontk/bzip2.git --branch master --single-branch --depth 1
cd bzip2
mkdir build
cd build
cmake \
  -G "Unix Makefiles" \
  "-DCMAKE_OSX_ARCHITECTURES=arm64;x86_64" \
  -DCMAKE_OSX_DEPLOYMENT_TARGET=${MACOSX_DEPLOYMENT_TARGET} \
  -DCMAKE_INSTALL_PREFIX:PATH=${DEPSDIR} \
  ..
make -j${NPROC}
make install
cd ..
install_license

file ${DEPSDIR}/lib/libbz2.a

echo "::endgroup::"
########
# lzma #
########
echo "::group::lzma"
cd ${BUILDDIR}

download_verify_extract xz-5.4.5.tar.gz
cd xz*
mkdir build
cd build
cmake \
  -G "Unix Makefiles" \
  "-DCMAKE_OSX_ARCHITECTURES=arm64;x86_64" \
  -DCMAKE_OSX_DEPLOYMENT_TARGET=${MACOSX_DEPLOYMENT_TARGET} \
  -DCMAKE_INSTALL_PREFIX:PATH=${DEPSDIR} \
  ..
make -j${NPROC}
make install
cd ..
install_license

file ${DEPSDIR}/lib/liblzma.a

echo "::endgroup::"
###########
# sqlite3 #
###########
echo "::group::sqlite3"
cd ${WORKDIR}

download_verify_extract sqlite-autoconf-3450000.tar.gz
cd sqlite-autoconf-3450000
CC=clang CFLAGS="${CFLAGS} -arch x86_64 -arch arm64"  ./configure --prefix ${DEPSDIR}
make -j${NPROC}
make install

file ${DEPSDIR}/lib/libsqlite3.a

echo "::endgroup::"
########
# zlib #
########
echo "::group::zlib"
cd ${BUILDDIR}

download_verify_extract zlib-1.3.1.tar.gz
cd zlib-1.3.1
mkdir build
cd build
cmake \
  -G "Unix Makefiles" \
  "-DCMAKE_OSX_ARCHITECTURES=arm64;x86_64" \
  -DCMAKE_OSX_DEPLOYMENT_TARGET=${MACOSX_DEPLOYMENT_TARGET} \
  -DCMAKE_INSTALL_PREFIX:PATH=${DEPSDIR} \
  ..
make -j${NPROC}
make install
cd ..
install_license

file ${DEPSDIR}/lib/libz.a

echo "::endgroup::"
#########
# expat #
#########
echo "::group::expat"
cd ${BUILDDIR}

download_verify_extract expat-2.6.2.tar.gz
cd expat*
CC=clang CFLAGS="${CFLAGS} -arch x86_64 -arch arm64"  ./configure --disable-shared --prefix=${DEPSDIR}
make -j${NPROC}
make install
install_license

file ${DEPSDIR}/lib/libexpat.a

echo "::endgroup::"
########
# gdbm #
########
echo "::group::gdbm"
cd ${BUILDDIR}

download_verify_extract gdbm-1.23.tar.gz
cd gdbm*
CC=clang CFLAGS="${CFLAGS} -arch x86_64 -arch arm64" ./configure --enable-libgdbm-compat --without-readline --prefix=${DEPSDIR}
make -j${NPROC}
make install
install_license

echo "::endgroup::"
##########
# libffi #
##########
echo "::group::libffi"
cd ${BUILDDIR}

download_verify_extract libffi-3.4.6.tar.gz
cp -r libffi-3.4.6 libffi-3.4.6-arm64
cd libffi-3.4.6
CC="/usr/bin/cc" ./configure --prefix ${DEPSDIR}
make -j${NPROC}
make install
cd ${BUILDDIR}
mkdir libffi-arm64-out
cd libffi-3.4.6-arm64
CC="/usr/bin/cc" CFLAGS="${CFLAGS} -target arm64-apple-macos11" ./configure --prefix ${BUILDDIR}/libffi-arm64-out --build=aarch64-apple-darwin --host=aarch64
make -j${NPROC}
make install
install_license

cd ${BUILDDIR}
lipo -create -output libffi.a ${DEPSDIR}/lib/libffi.a ${BUILDDIR}/libffi-arm64-out/lib/libffi.a
mv libffi.a ${DEPSDIR}/lib/libffi.a

file ${DEPSDIR}/lib/libffi.a

echo "::endgroup::"
########
# uuid #
########
echo "::group::uuid"
cd ${BUILDDIR}

download_verify_extract util-linux-2.39.3.tar.gz
cd util-linux*
./autogen.sh
CC=clang CFLAGS="${CFLAGS} -arch x86_64 -arch arm64" ./configure --disable-all-programs --enable-libuuid --prefix=${DEPSDIR}
make -j${NPROC}
make install
install_license ./Documentation/licenses/COPYING.BSD-3-Clause libuuid-2.39.3

echo "::endgroup::"
#########
# Build #
#########
echo "::group::Build"
cd ${BUILDDIR}

mkdir python-build
mkdir python-install
cd python-build
cmake \
  "${cmake_verbose_flags[@]}" \
  -G "Unix Makefiles" \
  "-DCMAKE_OSX_ARCHITECTURES=arm64;x86_64" \
  -DCMAKE_OSX_DEPLOYMENT_TARGET=${MACOSX_DEPLOYMENT_TARGET} \
  -DCMAKE_IGNORE_PREFIX_PATH=/Applications \
  -DPYTHON_VERSION=${PYTHON_FULL_VER} \
  -DPORTABLE_PYTHON_BUILD=ON \
  -DCMAKE_BUILD_TYPE:STRING=${BUILD_TYPE} \
  -DCMAKE_INSTALL_PREFIX:PATH=${BUILDDIR}/python-install \
  -DBUILD_EXTENSIONS_AS_BUILTIN=OFF \
  -DBUILD_LIBPYTHON_SHARED=ON \
  -DUSE_SYSTEM_LIBRARIES=OFF \
  -DBUILD_TESTING=${INSTALL_TEST} \
  -DINSTALL_TEST=${INSTALL_TEST} \
  -DINSTALL_MANUAL=OFF \
  -DOPENSSL_INCLUDE_DIR:PATH=${DEPSDIR}/include \
  -DOPENSSL_LIBRARIES="${DEPSDIR}/lib/libssl.a;${DEPSDIR}/lib/libcrypto.a;${DEPSDIR}/lib/libz.a" \
  -DEXPAT_INCLUDE_DIRS:PATH=${DEPSDIR}/include \
  -DEXPAT_LIBRARIES:FILEPATH=${DEPSDIR}/lib/libexpat.a \
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
  -DNDBM_USE=NDBM \
  -DTK_INCLUDE_PATH:FILEPATH=${DEPSDIR}/include/tk.h \
  -DTK_LIBRARY:FILEPATH=${DEPSDIR}/lib/libtk8.6.a \
  -DTCL_INCLUDE_PATH:FILEPATH=${DEPSDIR}/include/tcl.h \
  -DTCL_LIBRARY:FILEPATH=${DEPSDIR}/lib/libtcl8.6.a \
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

otool -l ./python-install/bin/python
install_name_tool -add_rpath @executable_path/../lib ./python-install/bin/python
install_name_tool -change ${BUILDDIR}/python-install/lib/libpython${PYTHON_VER}.dylib @rpath/libpython${PYTHON_VER}.dylib ./python-install/bin/python
otool -l ./python-install/bin/python

./python-install/bin/python --version

echo "::endgroup::"
###############
# Preload pip #
###############
echo "::group::Preload pip"
cd ${BUILDDIR}

./python-install/bin/python -m ensurepip
./python-install/bin/python -m pip install -r ${WORKDIR}/baseline/requirements.txt

python3 ${WORKDIR}/scripts/patch_pip_script.py ./python-install/bin/pip3
python3 ${WORKDIR}/scripts/patch_pip_script.py ./python-install/bin/pip${PYTHON_VER}

###################
# Compress output #
###################
echo "::group::Compress output"
cd ${BUILDDIR}

python3 -m pip install pyclean
python3 -m pyclean -v python-install
mv python-install python-${PYTHON_FULL_VER}-${PLATFORM}-${ARCH}
tar -czf ${WORKDIR}/python-${PYTHON_FULL_VER}-${PLATFORM}-${ARCH}.tar.gz python-${PYTHON_FULL_VER}-${PLATFORM}-${ARCH}
zip ${WORKDIR}/python-${PYTHON_FULL_VER}-${PLATFORM}-${ARCH}.zip $(tar tf ${WORKDIR}/python-${PYTHON_FULL_VER}-${PLATFORM}-${ARCH}.tar.gz)

echo "::endgroup::"
