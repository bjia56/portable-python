#!/bin/bash

PLATFORM=cosmo
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
source ${SCRIPT_DIR}/utils.sh

########################
# Install dependencies #
########################
echo "::group::Install dependencies"

export DEBIAN_FRONTEND=noninteractive
sudo apt update
sudo apt -y install \
  wget pkg-config autoconf git patch \
  gettext bison libtool autopoint gperf ncurses-bin xutils-dev

export AR=$(command -v cosmoar)
export CC=cosmocc
export CXX=cosmoc++
export CFLAGS="-I${DEPSDIR}/include"
export CPPFLAGS="-I${DEPSDIR}/include"
export CXXFLAGS="${CPPFLAGS} -fexceptions"
export LDFLAGS="-L${DEPSDIR}/lib"
export PKG_CONFIG_PATH="${DEPSDIR}/lib/pkgconfig:${DEPSDIR}/share/pkgconfig"

echo "::endgroup::"
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
./Configure no-shared --prefix=${DEPSDIR} --openssldir=${DEPSDIR}
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
./configure --with-curses --disable-shared --prefix=${DEPSDIR}
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
CFLAGS="${CFLAGS} -I${DEPSDIR}/include/libxml2" ./configure --with-libxml-prefix=${DEPSDIR} --without-python --prefix=${DEPSDIR}
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
LDFLAGS="${LDFLAGS} -lxml2" ./configure --enable-static --disable-shared --enable-libxml2 --disable-cache-build --prefix=${DEPSDIR}
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
  ./configure $ext_flags --prefix=${DEPSDIR}
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
build_x11_lib libX11-1.8.7 --enable-malloc0returnsnull
build_x11_lib libXext-1.3.5 --enable-malloc0returnsnull
build_x11_lib libICE-1.0.7
build_x11_lib libSM-1.2.2
build_x11_lib libXrender-0.9.11 --enable-malloc0returnsnull
build_x11_lib libXft-2.3.8
build_x11_lib libXScrnSaver-1.2.4 --enable-malloc0returnsnull

#echo "::endgroup::"
#######
# tcl #
#######
echo "::group::tcl"
cd ${BUILDDIR}

download_verify_extract tcl8.6.13-src.tar.gz
cd tcl*/unix
LDFLAGS="${LDFLAGS} -lxml2" ./configure --disable-shared --prefix=${DEPSDIR}
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
LDFLAGS="${LDFLAGS} -lxml2" ./configure --disable-shared --prefix=${DEPSDIR}
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
LDFLAGS="${LDFLAGS} -lfontconfig -lfreetype" cmake \
  "${cmake_verbose_flags[@]}" \
  -DCMAKE_SYSTEM_PROCESSOR=${ARCH} \
  -DCMAKE_CROSSCOMPILING_EMULATOR=${WORKDIR}/scripts/qemu_${ARCH}_interpreter \
  -DCMAKE_IGNORE_PATH=/usr/include \
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
  -DX11_INCLUDE_DIR:PATH=${DEPSDIR}/include/X11 \
  -DX11_LIBRARIES="${DEPSDIR}/lib/libXau.a;${DEPSDIR}/lib/libXdmcp.a;${DEPSDIR}/lib/libX11.a;${DEPSDIR}/lib/libXext.a;${DEPSDIR}/lib/libICE.a;${DEPSDIR}/lib/libSM.a;${DEPSDIR}/lib/libXrender.a;${DEPSDIR}/lib/libXft.a;${DEPSDIR}/lib/libXss.a;${DEPSDIR}/lib/libxcb.a" \
  ../portable-python-cmake-buildsystem
make -j4
make install

cd ${BUILDDIR}
cp -r ${DEPSDIR}/lib/tcl8.6 ./python-install/lib
cp -r ${DEPSDIR}/lib/tk8.6 ./python-install/lib
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
${WORKDIR}/scripts/qemu_${ARCH}_interpreter ./bin/python --version

echo "::endgroup::"
###############
# Preload pip #
###############
echo "::group::Preload pip"
cd ${BUILDDIR}

cd python-install
${WORKDIR}/scripts/qemu_${ARCH}_interpreter ./bin/python -m ensurepip
${WORKDIR}/scripts/qemu_${ARCH}_interpreter ./bin/python -m pip install -r ${WORKDIR}/baseline/requirements.txt

python3 ${WORKDIR}/scripts/patch_pip_script.py ./bin/pip3
python3 ${WORKDIR}/scripts/patch_pip_script.py ./bin/pip${PYTHON_VER}

echo "::endgroup::"
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
