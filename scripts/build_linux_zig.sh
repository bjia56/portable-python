#!/bin/bash

PLATFORM=linux
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
source ${SCRIPT_DIR}/utils.sh

which zig
zig version

########################
# Install dependencies #
########################
echo "::group::Install dependencies"

export DEBIAN_FRONTEND=noninteractive
sudo apt update
sudo apt -y install \
  wget build-essential pkg-config cmake autoconf git \
  python2 python3 python3-pip clang qemu-user-static \
  gettext bison libtool autopoint gperf ncurses-bin xutils-dev
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
  riscv64)
    sudo apt -y install libc6-riscv64-cross
    sudo ln -s /usr/riscv64-linux-gnu/lib/ld-linux-riscv64-lp64d.so.1 /lib/ld-linux-riscv64-lp64d.so.1
    # workaround since the Zig compiler always targets ld-linux-riscv64-lp64.so.1
    sudo ln -s /usr/riscv64-linux-gnu/lib/ld-linux-riscv64-lp64d.so.1 /lib/ld-linux-riscv64-lp64.so.1
    ;;
esac
sudo pip install https://github.com/mesonbuild/meson/archive/2baae24.zip ninja patchelf==0.15.0.0

mkdir ${BUILDDIR}
mkdir ${DEPSDIR}
mkdir ${LICENSEDIR}

export ZIG_FLAGS=""
export CFLAGS="-I${DEPSDIR}/include"
export CPPFLAGS="-I${DEPSDIR}/include"
export CXXFLAGS="${CPPFLAGS}"
export LDFLAGS="-L${DEPSDIR}/lib"
export PKG_CONFIG_PATH="${DEPSDIR}/lib/pkgconfig:${DEPSDIR}/share/pkgconfig"

if [[ "${ARCH}" == "arm" ]]; then
  # Python's sysconfig module will retain references to these compiler values, which cause
  # problems when sysconfig is used to pick a compiler during binary extension builds.
  # Since clang (zig) is a drop-in replacement for gcc, we set these so the final sysconfig
  # will work on other platforms.
  sudo cp ${WORKDIR}/zigshim/zig_ar /usr/bin/${ARCH}-linux-gnueabihf-gcc-ar
  sudo cp ${WORKDIR}/zigshim/zig_cc /usr/bin/${ARCH}-linux-gnueabihf-gcc
  sudo cp ${WORKDIR}/zigshim/zig_cxx /usr/bin/${ARCH}-linux-gnueabihf-g++
  export AR="${ARCH}-linux-gnueabihf-gcc-ar"
  export CC="${ARCH}-linux-gnueabihf-gcc"
  export CXX="${ARCH}-linux-gnueabihf-g++"
  export CHOST=${ARCH}-linux-gnueabihf
  export ZIG_FLAGS="-target ${ARCH}-linux-gnueabihf.2.17 -mfpu=vfp -mfloat-abi=hard -mcpu=arm1176jzf_s"
else
  # See above comment
  sudo cp ${WORKDIR}/zigshim/zig_ar /usr/bin/${ARCH}-linux-gnu-gcc-ar
  sudo cp ${WORKDIR}/zigshim/zig_cc /usr/bin/${ARCH}-linux-gnu-gcc
  sudo cp ${WORKDIR}/zigshim/zig_cxx /usr/bin/${ARCH}-linux-gnu-g++
  export AR="${ARCH}-linux-gnu-gcc-ar"
  export CC="${ARCH}-linux-gnu-gcc"
  export CXX="${ARCH}-linux-gnu-g++"
  if [[ "${ARCH}" == "riscv64" ]]; then
    export ZIG_FLAGS="-target riscv64-linux-gnu.2.34 -mabi=lp64d -march=rv64g"
    export CFLAGS="-Wl,--undefined-version ${CFLAGS}"
  else
    export ZIG_FLAGS="-target ${ARCH}-linux-gnu.2.17"
  fi
  export CHOST=${ARCH}-linux-gnu
fi

# RISC-V hack for zig's glibc
# https://github.com/ziglang/zig/issues/3340
if [[ "${ARCH}" == "riscv64" ]]; then
  cd /tmp
  wget -O glibc.patch https://patch-diff.githubusercontent.com/raw/ziglang/zig/pull/18803.patch
  cd $(dirname $(which zig))
  patch -p1 < /tmp/glibc.patch || true
  cd ${WORKDIR}
fi

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
if [[ "${ARCH}" == "arm" ]]; then
  ./Configure linux-generic32 no-shared --prefix=${DEPSDIR} --openssldir=${DEPSDIR}
elif [[ "${ARCH}" == "riscv64" ]]; then
  CFLAGS="${CFLAGS} -fgnuc-version=0 -D__STDC_NO_ATOMICS__" ./Configure linux-generic64 no-shared --prefix=${DEPSDIR} --openssldir=${DEPSDIR}
else
  ./Configure linux-${ARCH} no-shared --prefix=${DEPSDIR} --openssldir=${DEPSDIR}
fi
make -j4
make install_sw
install_license

echo "::endgroup::"
##########
# libffi #
##########
echo "::group::libffi"
cd ${BUILDDIR}

download_verify_extract libffi-3.4.2.tar.gz
cd libffi*
CFLAGS="${CFLAGS} -Wl,--undefined-version" ./configure --host=${CHOST} --prefix=${DEPSDIR}
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
./configure --host=${CHOST} --prefix=${DEPSDIR}
make -j4
make install

echo "::endgroup::"
#########
# expat #
#########
echo "::group::expat"
cd ${BUILDDIR}

download_verify_extract expat-2.5.0.tar.gz
cd expat*
./configure --host=${CHOST} --disable-shared --prefix=${DEPSDIR}
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
./configure --host=${CHOST} --with-normal --without-progs --enable-overwrite --disable-stripping --prefix=${DEPSDIR}
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
cmake -DCMAKE_SYSTEM_PROCESSOR=${ARCH} -DCMAKE_INSTALL_PREFIX:PATH=${DEPSDIR} ..
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
cmake -DCMAKE_SYSTEM_PROCESSOR=${ARCH} -DCMAKE_INSTALL_PREFIX:PATH=${DEPSDIR} ..
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
cmake -DCMAKE_SYSTEM_PROCESSOR=${ARCH} -DCMAKE_INSTALL_PREFIX:PATH=${DEPSDIR} ..
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
./configure --host=${CHOST} --disable-all-programs --enable-libuuid --prefix=${DEPSDIR}
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
./configure --host=${CHOST} --enable-libgdbm-compat --prefix=${DEPSDIR}
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
./configure --host=${CHOST} --enable-static --disable-shared --without-python --prefix=${DEPSDIR}
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
./configure --host=${CHOST} --with-zlib-prefix=${DEPSDIR} --disable-tools --prefix=${DEPSDIR}
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
./configure --host=${CHOST} --prefix=${DEPSDIR}
make -j4
make install
install_license ./COPYING.LIB

cd ${BUILDDIR}

download_verify_extract libgcrypt-1.10.3.tar.bz2
cd libgcrypt*
LDFLAGS="${LDFLAGS} -Wl,--undefined-version" ./configure --disable-asm --host=${CHOST} --prefix=${DEPSDIR}
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
CFLAGS="${CFLAGS} -I${DEPSDIR}/include/libxml2" ./configure --host=${CHOST} --with-libxml-prefix=${DEPSDIR} --without-python --prefix=${DEPSDIR}
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
./configure --host=${CHOST} --prefix=${DEPSDIR}
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
LDFLAGS="${LDFLAGS} -lxml2" ./configure --host=${CHOST} --enable-static --disable-shared --enable-libxml2 --disable-cache-build --prefix=${DEPSDIR}
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
LDFLAGS="${LDFLAGS} -lxml2" ./configure --disable-shared --host=${CHOST} --prefix=${DEPSDIR}
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
LDFLAGS="${LDFLAGS} -lxml2" ./configure --disable-shared --host=${CHOST} --prefix=${DEPSDIR}
make -j4
make install
cd .. 
install_license ./license.terms

echo "::endgroup::"
#############
# mpdecimal #
#############
if [[ "${ARCH}" == "arm" ]]; then
  echo "::group::mpdecimal"
  cd ${BUILDDIR}

  download_verify_extract mpdecimal-2.5.0.tar.gz
  cd mpdecimal*
  ./configure --disable-cxx --host=${CHOST} --prefix=${DEPSDIR}
  make -j4
  make install
  install_license ./LICENSE.txt

  echo "::endgroup::"
fi
##########
# Python #
##########
echo "::group::Python"
cd ${BUILDDIR}

additionalparams=()
if [[ "${ARCH}" == "arm" ]]; then
  additionalparams+=(-DUSE_SYSTEM_LIBMPDEC=ON)
  export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:${DEPSDIR}/lib
fi

wget --no-verbose -O python-cmake-buildsystem.tar.gz https://github.com/bjia56/python-cmake-buildsystem/tarball/portable-python-riscv
tar -xf python-cmake-buildsystem.tar.gz
rm *.tar.gz
mv *python-cmake-buildsystem* python-cmake-buildsystem
mkdir python-build
mkdir python-install
cd python-build
LDFLAGS="${LDFLAGS} -lfontconfig -lfreetype" cmake \
  -DCMAKE_SYSTEM_PROCESSOR=${ARCH} \
  -DCMAKE_CROSSCOMPILING_EMULATOR=${WORKDIR}/scripts/qemu_${ARCH}_interpreter \
  -DCMAKE_IGNORE_PATH=/usr/include \
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
  "${additionalparams[@]}" \
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
  -DX11_LIBRARIES="${DEPSDIR}/lib/libXau.a;${DEPSDIR}/lib/libXdmcp.a;${DEPSDIR}/lib/libX11.a;${DEPSDIR}/lib/libXext.a;${DEPSDIR}/lib/libICE.a;${DEPSDIR}/lib/libSM.a;${DEPSDIR}/lib/libXrender.a;${DEPSDIR}/lib/libXft.a;${DEPSDIR}/lib/libXss.a;${DEPSDIR}/lib/libxcb.a" \
  ../python-cmake-buildsystem
make -j4
make install

cd ${BUILDDIR}
cp -r ${DEPSDIR}/lib/tcl8.6 ./python-install/lib
cp -r ${DEPSDIR}/lib/tk8.6 ./python-install/lib
cp -r ${LICENSEDIR} ./python-install

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
if [[ "${ARCH}" == "riscv64" ]]; then
  patchelf --set-interpreter /lib/ld-linux-riscv64-lp64d.so.1 ./bin/python
fi
${WORKDIR}/scripts/patch_libpython.sh ./lib/libpython${PYTHON_VER}.so ./bin/python
patchelf --replace-needed libpython${PYTHON_VER}.so "\$ORIGIN/../lib/libpython${PYTHON_VER}.so" ./bin/python

echo "::endgroup::"
##############################################
# Check executable dependencies (post-patch) #
##############################################
echo "::group::Check executable dependencies (post-patch)"
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
