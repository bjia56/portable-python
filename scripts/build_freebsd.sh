#!/bin/bash

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
source ${SCRIPT_DIR}/utils.sh

########
# zlib #
########
echo "::group::zlib"
cd ${BUILDDIR}

download_verify_extract zlib-1.3.1.tar.gz
cd zlib*
./configure --prefix=${DEPSDIR}
make -j4
make install
install_license

echo "::endgroup::"
###########
# OpenSSL #
###########
echo "::group::OpenSSL"
cd ${BUILDDIR}

download_verify_extract openssl-1.1.1w.tar.gz
cd openssl*
./Configure BSD-${ARCH} no-shared --prefix=${DEPSDIR} --openssldir=${DEPSDIR}
make -j4
make install_sw
install_license

echo "::endgroup::"
##########
# libffi #
##########
echo "::group::libffi"
cd ${BUILDDIR}

download_verify_extract libffi-3.4.6.tar.gz
cd libffi*
./configure --prefix=${DEPSDIR}
make -j4
make install
install_license

echo "::endgroup::"
###########
# sqlite3 #
###########
echo "::group::sqlite3"
cd ${BUILDDIR}

download_verify_extract sqlite-autoconf-3450000.tar.gz
cd sqlite*
./configure --prefix=${DEPSDIR}
make -j4
make install

echo "::endgroup::"
#########
# expat #
#########
echo "::group::expat"
cd ${BUILDDIR}

download_verify_extract expat-2.6.2.tar.gz
cd expat*
./configure --disable-shared --prefix=${DEPSDIR}
make -j4
make install
install_license

echo "::endgroup::"
###########
# ncurses #
###########
echo "::group::ncurses"
cd ${BUILDDIR}

download_verify_extract ncurses-6.4.tar.gz
cd ncurses*
./configure --with-normal --without-progs --enable-overwrite --disable-stripping --prefix=${DEPSDIR}
make -j4
make install
install_license

echo "::endgroup::"
############
# readline #
############
echo "::group::readline"
cd ${BUILDDIR}

download_verify_extract readline-8.2.tar.gz
cd readline*
./configure --with-curses --disable-shared --host=${CHOST} --prefix=${DEPSDIR}
make -j4
make install
install_license

echo "::endgroup::"
#########
# bzip2 #
#########
echo "::group::bzip2"
cd ${BUILDDIR}

wget --no-verbose -O bzip2.tar.gz https://github.com/commontk/bzip2/tarball/master
tar -xf bzip2*.tar.gz
rm *.tar.gz
cd commontk-bzip2*
mkdir build
cd build
cmake -DCMAKE_INSTALL_PREFIX:PATH=${DEPSDIR} ..
make -j4
make install
cd ..
install_license ./LICENSE bzip2-1.0.8

echo "::endgroup::"
######
# xz #
######
echo "::group::xz"
cd ${BUILDDIR}

download_verify_extract xz-5.4.5.tar.gz
cd xz*
mkdir build
cd build
cmake -DCMAKE_INSTALL_PREFIX:PATH=${DEPSDIR} ..
make -j4
make install
cd ..
install_license

echo "::endgroup::"
##########
# Brotli #
##########
echo "::group::Brotli"
cd ${BUILDDIR}

download_verify_extract brotli-1.1.0.tar.gz
cd brotli*
mkdir build
cd build
cmake -DCMAKE_INSTALL_PREFIX:PATH=${DEPSDIR} ..
make -j4
make install
cd ..
install_license

echo "::endgroup::"
########
# uuid #
########
echo "::group::uuid"
cd ${BUILDDIR}

download_verify_extract util-linux-2.39.3.tar.gz
cd util-linux*
./autogen.sh
./configure --disable-all-programs --enable-libuuid --prefix=${DEPSDIR}
make -j4
make install
install_license ./Documentation/licenses/COPYING.BSD-3-Clause libuuid-2.39.3

echo "::endgroup::"
########
# gdbm #
########
echo "::group::gdbm"
cd ${BUILDDIR}

download_verify_extract gdbm-1.23.tar.gz
cd gdbm*
./configure --enable-libgdbm-compat --prefix=${DEPSDIR}
make -j4
make install
install_license

echo "::endgroup::"
###########
# libxml2 #
###########
echo "::group::libxml2"
cd ${BUILDDIR}

download_verify_extract libxml2-2.12.4.tar.xz
cd libxml2*
./configure --enable-static --disable-shared --without-python --prefix=${DEPSDIR}
make -j4
make install
install_license ./Copyright

echo "::endgroup::"
############
# libpng16 #
############
echo "::group::libpng16"
cd ${BUILDDIR}

download_verify_extract libpng-1.6.41.tar.gz
cd libpng*
./configure --with-zlib-prefix=${DEPSDIR} --disable-tools --prefix=${DEPSDIR}
make -j4
make install

echo "::endgroup::"
#############
# libgcrypt #
#############
echo "::group::libgcrypt"
cd ${BUILDDIR}

download_verify_extract libgpg-error-1.47.tar.bz2
cd libgpg-error*
./configure --prefix=${DEPSDIR}
make -j4
make install
install_license ./COPYING.LIB

cd ${BUILDDIR}

download_verify_extract libgcrypt-1.10.3.tar.bz2
cd libgcrypt*
./configure --disable-asm --prefix=${DEPSDIR}
make -j4
make install
install_license ./COPYING.LIB

echo "::endgroup::"
###########
# libxslt #
###########
echo "::group::libxslt"
cd ${BUILDDIR}

download_verify_extract libxslt-1.1.39.tar.xz
cd libxslt*
CFLAGS="-I${DEPSDIR}/include/libxml2" ./configure --with-libxml-prefix=${DEPSDIR} --without-python --prefix=${DEPSDIR}
make -j4
make install
install_license

echo "::endgroup::"
############
# freetype #
############
echo "::group::freetype"
cd ${BUILDDIR}

download_verify_extract freetype-2.13.2.tar.gz
cd freetype*
./configure --prefix=${DEPSDIR}
make -j4
make install
install_license ./docs/FTL.TXT

echo "::endgroup::"
##############
# fontconfig #
##############
echo "::group::fontconfig"
cd ${BUILDDIR}

download_verify_extract fontconfig-2.15.0.tar.gz
cd fontconfig*
./configure --enable-static --disable-shared --enable-libxml2 --disable-cache-build --prefix=${DEPSDIR}
make -j4
make install
install_license

echo "::endgroup::"
#######
# X11 #
#######
#echo "::group::X11"
#cd ${BUILDDIR}

function build_x11_lib_core() {
  echo "::group::$1"
  cd ${BUILDDIR}

  pkg=$1
  ext_flags="$2"
  file=$pkg.tar.gz
  download_verify_extract $file
  cd $pkg
  autoreconf -vfi
  ./configure $ext_flags --host=${CHOST} --prefix=${DEPSDIR}
  make -j4
  make install

  echo "::endgroup::"
}

function build_x11_lib () {
  build_x11_lib_core "$1" "$2"
  install_license
}

build_x11_lib_core xorgproto-2023.2
build_x11_lib xproto-7.0.31
build_x11_lib xextproto-7.3.0
build_x11_lib kbproto-1.0.7
build_x11_lib inputproto-2.3.2
build_x11_lib renderproto-0.11.1
build_x11_lib scrnsaverproto-1.2.2
build_x11_lib xcb-proto-1.16.0
build_x11_lib libpthread-stubs-0.5
build_x11_lib xtrans-1.5.0
build_x11_lib libXau-1.0.11
build_x11_lib libxcb-1.16
build_x11_lib libXdmcp-1.1.2
build_x11_lib libX11-1.8.7
build_x11_lib libXext-1.3.5
build_x11_lib libICE-1.0.7
build_x11_lib libSM-1.2.2
build_x11_lib libXrender-0.9.11
build_x11_lib libXft-2.3.8
build_x11_lib libXScrnSaver-1.2.4

#echo "::endgroup::"
#######
# tcl #
#######
echo "::group::tcl"
cd ${BUILDDIR}

download_verify_extract tcl8.6.13-src.tar.gz
cd tcl*/unix
LDFLAGS="-lxml2" ./configure --disable-shared --prefix=${DEPSDIR}
make -j4
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
LDFLAGS="-lxml2" ./configure --disable-shared --prefix=${DEPSDIR}
make -j4
make install
cd ..
install_license ./license.terms

echo "::endgroup::"
##########
# Python #
##########
echo "::group::Python"
cd ${BUILDDIR}

wget --no-verbose -O portable-python-cmake-buildsystem.tar.gz https://github.com/bjia56/portable-python-cmake-buildsystem/tarball/${CMAKE_BUILDSYSTEM_BRANCH}
tar -xf portable-python-cmake-buildsystem.tar.gz
rm *.tar.gz
mv *portable-python-cmake-buildsystem* portable-python-cmake-buildsystem
mkdir python-build
mkdir python-install
cd python-build
cmake \
  "${cmake_verbose_flags[@]}" \
  -DCMAKE_SYSTEM_PROCESSOR=${ARCH} \
  -DPYTHON_VERSION=${PYTHON_FULL_VER} \
  -DPORTABLE_PYTHON_BUILD=ON \
  -DCMAKE_BUILD_TYPE:STRING=${BUILD_TYPE} \
  -DCMAKE_INSTALL_PREFIX:PATH=${BUILDDIR}/python-install \
  -DBUILD_EXTENSIONS_AS_BUILTIN=ON \
  -DBUILD_LIBPYTHON_SHARED=ON \
  -DUSE_SYSTEM_LIBRARIES=OFF \
  -DBUILD_TESTING=${INSTALL_TEST} \
  -DINSTALL_TEST=${INSTALL_TEST} \
  -DINSTALL_MANUAL=OFF \
  -DOPENSSL_INCLUDE_DIR:PATH=${DEPSDIR}/include \
  -DOPENSSL_LIBRARIES="${DEPSDIR}/lib/libssl.a;${DEPSDIR}/lib/libcrypto.a" \
  -DZLIB_INCLUDE_DIR:PATH=${DEPSDIR}/include \
  -DZLIB_LIBRARY:FILEPATH=${DEPSDIR}/lib/libz.so \
  -DLibFFI_INCLUDE_DIR:PATH=${DEPSDIR}/include \
  -DLibFFI_LIBRARY:FILEPATH=${DEPSDIR}/lib/libffi.so \
  ../portable-python-cmake-buildsystem
make -j4
make install

cd ${BUILDDIR}
cp ${DEPSDIR}/lib/libz.so.* ./python-install/lib
cp ${DEPSDIR}/lib/libffi.so.* ./python-install/lib
cp -r ${LICENSEDIR} ./python-install

echo "::endgroup::"
#################################
# Check executable dependencies #
#################################
echo "::group::Check executable dependencies"
cd ${BUILDDIR}

cd python-install
echo "python dependencies"
readelf -d ./bin/python
echo
echo "libpython dependencies"
readelf -d ./lib/libpython${PYTHON_VER}.so

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
./bin/python -m pip install -r ${WORKDIR}/baseline/requirements.txt

echo "::endgroup::"
###################
# Compress output #
###################
echo "::group::Compress output"
cd ${BUILDDIR}

python3 -m ensurepip
python3 -m pip install pyclean
python3 -m pyclean -v python-install
mv python-install python-${PYTHON_FULL_VER}-${PLATFORM}-${ARCH}
tar -czf ${WORKDIR}/python-${PYTHON_FULL_VER}-${PLATFORM}-${ARCH}.tar.gz python-${PYTHON_FULL_VER}-${PLATFORM}-${ARCH}
zip ${WORKDIR}/python-${PYTHON_FULL_VER}-${PLATFORM}-${ARCH}.zip $(tar tf ${WORKDIR}/python-${PYTHON_FULL_VER}-${PLATFORM}-${ARCH}.tar.gz)

echo "::endgroup::"