#!/bin/bash

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
source ${SCRIPT_DIR}/utils.sh

export CC=gcc
export CXX=g++
export LD=gld
export AR=gar
export AS=gas
export RANLIB=granlib
export NM=gnm
export CFLAGS="-I${DEPSDIR}/include -fPIC"
export CPPFLAGS="-I${DEPSDIR}/include -fPIC"
export CXXFLAGS="${CPPFLAGS}"
export LDFLAGS="-L${DEPSDIR}/lib"
export PKG_CONFIG_PATH="${DEPSDIR}/lib/pkgconfig:${DEPSDIR}/share/pkgconfig"
export AL_OPTS="-I/usr/local/share/aclocal -I${DEPSDIR}/share/aclocal"
mkdir -p ${DEPSDIR}/share/aclocal

# for new autoconf
export PATH="/usr/local/bin:${PATH}"

############
# autoconf #
############
echo "::group::autoconf"
cd ${BUILDDIR}

wget https://ftp.gnu.org/gnu/autoconf/autoconf-2.70.tar.gz
gtar --no-same-permissions --no-same-owner -xf autoconf-2.70.tar.gz
cd autoconf-2.70
./configure
gmake -j4
gmake install

########
# zlib #
########
echo "::group::zlib"
cd ${BUILDDIR}

download_verify_extract zlib-1.3.1.tar.gz
cd zlib*
./configure --prefix=${DEPSDIR} --static
gmake -j4
gmake install
install_license

echo "::endgroup::"
###########
# OpenSSL #
###########
echo "::group::OpenSSL"
cd ${BUILDDIR}

if (( ${PYTHON_MINOR} < 11 )); then
  download_verify_extract openssl-1.1.1w.tar.gz
else
  download_verify_extract openssl-3.0.15.tar.gz
fi
cd openssl*
./Configure solaris64-x86_64-gcc no-shared --prefix=${DEPSDIR} --openssldir=${DEPSDIR}
gmake -j4
gmake install_sw
install_license

echo "::endgroup::"
##########
# libffi #
##########
echo "::group::libffi"
cd ${BUILDDIR}

download_verify_extract libffi-3.4.6.tar.gz
cd libffi*
./configure MAKE=gmake --disable-shared --prefix=${DEPSDIR}
gmake -j4
gmake install
install_license

echo "::endgroup::"
###########
# sqlite3 #
###########
echo "::group::sqlite3"
cd ${BUILDDIR}

download_verify_extract sqlite-autoconf-3450000.tar.gz
cd sqlite*
./configure --disable-shared --prefix=${DEPSDIR}
gmake -j4
gmake install

echo "::endgroup::"
#########
# expat #
#########
echo "::group::expat"
cd ${BUILDDIR}

download_verify_extract expat-2.6.2.tar.gz
cd expat*
./configure --disable-shared --prefix=${DEPSDIR}
gmake -j4
gmake install
install_license

echo "::endgroup::"
###########
# ncurses #
###########
echo "::group::ncurses"
cd ${BUILDDIR}

download_verify_extract ncurses-6.4.tar.gz
cd ncurses*
./configure --with-normal --without-shared --without-progs --enable-overwrite --disable-stripping --prefix=${DEPSDIR}
gmake -j4
gmake install.libs
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
gmake -j4
gmake install
install_license

echo "::endgroup::"
#########
# bzip2 #
#########
echo "::group::bzip2"
cd ${BUILDDIR}

wget --no-verbose -O bzip2.tar.gz https://github.com/commontk/bzip2/tarball/master
gtar --no-same-permissions --no-same-owner -xf bzip2*.tar.gz
rm *.tar.gz
cd commontk-bzip2*
mkdir build
cd build
cmake -DCMAKE_INSTALL_PREFIX:PATH=${DEPSDIR} ..
gmake -j4
gmake install
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
cmake -DCMAKE_INSTALL_PREFIX:PATH=${DEPSDIR} -DBUILD_SHARED_LIBS=OFF ..
gmake -j4
gmake install
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
gmake -j4
gmake install
cd ..
install_license

echo "::endgroup::"
########
# gdbm #
########
echo "::group::gdbm"
cd ${BUILDDIR}

download_verify_extract gdbm-1.23.tar.gz
cd gdbm*
./configure --enable-libgdbm-compat --disable-shared --prefix=${DEPSDIR}
gmake -j4
gmake install
install_license

echo "::endgroup::"
###########
# libxml2 #
###########
echo "::group::libxml2"
cd ${BUILDDIR}

download_verify_extract libxml2-2.12.4.tar.xz
cd libxml2*
./configure --without-python --enable-static --disable-shared --prefix=${DEPSDIR}
gmake -j4
gmake install
install_license ./Copyright

echo "::endgroup::"
############
# libpng16 #
############
echo "::group::libpng16"
cd ${BUILDDIR}

download_verify_extract libpng-1.6.41.tar.gz
cd libpng*
./configure --with-zlib-prefix=${DEPSDIR} --enable-static --disable-shared --disable-tools --prefix=${DEPSDIR}
gmake -j4
gmake install

echo "::endgroup::"
#############
# libgcrypt #
#############
echo "::group::libgcrypt"
cd ${BUILDDIR}

download_verify_extract libgpg-error-1.47.tar.bz2
cd libgpg-error*
./configure --enable-static --disable-shared --prefix=${DEPSDIR}
gmake -j4
gmake install
install_license ./COPYING.LIB

cd ${BUILDDIR}

download_verify_extract libgcrypt-1.10.3.tar.bz2
cd libgcrypt*
./configure --enable-static --disable-shared --disable-asm --prefix=${DEPSDIR}
gmake -j4
gmake install
install_license ./COPYING.LIB

echo "::endgroup::"
###########
# libxslt #
###########
echo "::group::libxslt"
cd ${BUILDDIR}

download_verify_extract libxslt-1.1.39.tar.xz
cd libxslt*
CFLAGS="${CFLAGS} -I${DEPSDIR}/include/libxml2" LDFLAGS="${LDFLAGS} -Wl,-z,gnu-version-script-compat" ./configure --enable-static --disable-shared --with-libxml-prefix=${DEPSDIR} --without-python --prefix=${DEPSDIR}
gmake -j4
gmake install
install_license

echo "::endgroup::"
############
# freetype #
############
echo "::group::freetype"
cd ${BUILDDIR}

download_verify_extract freetype-2.13.2.tar.gz
cd freetype*
./configure --enable-static --disable-shared --prefix=${DEPSDIR}
gmake -j4
gmake install
install_license ./docs/FTL.TXT

echo "::endgroup::"
##############
# fontconfig #
##############
echo "::group::fontconfig"
cd ${BUILDDIR}

download_verify_extract fontconfig-2.15.0.tar.gz
cd fontconfig*
./configure MAKE="gmake" --enable-libxml2 --disable-cache-build --enable-static --disable-shared --prefix=${DEPSDIR}
gmake -j4
gmake install
install_license

echo "::endgroup::"

if [[ "${DISTRIBUTION}" != "headless" ]]; then
  #######
  # X11 #
  #######

  function build_x11_lib_core() {
    echo "::group::$1"
    cd ${BUILDDIR}

    pkg=$1
    ext_flags="$2"
    file=$pkg.tar.gz
    download_verify_extract $file
    cd $pkg
    autoreconf -vfi ${AL_OPTS}
    ./configure --enable-static --disable-shared $ext_flags --prefix=${DEPSDIR}
    gmake -j4
    gmake install

    echo "::endgroup::"
  }

  function build_x11_lib () {
    build_x11_lib_core "$1" "$2"
    install_license
  }

  build_x11_lib_core util-macros-1.20.1
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
  ./configure --enable-static --disable-shared --prefix=${DEPSDIR}
  gmake -j4
  gmake install
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
  LDFLAGS="${LDFLAGS} -lX11 -lxml2 -lxcb -lXau" ./configure --enable-static --disable-shared --prefix=${DEPSDIR}
  gmake -j4 X11_LIB_SWITCHES="-lX11 -lxcb -lXau -lXdmcp"
  gmake install
  cd ..
  install_license ./license.terms

  echo "::endgroup::"
fi

##########
# Python #
##########
echo "::group::Python"
cd ${BUILDDIR}

additionalparams=()
if [[ "${DISTRIBUTION}" != "headless" ]]; then
  additionalparams+=(
    -DTK_INCLUDE_PATH:FILEPATH=${DEPSDIR}/include \
    -DTK_LIBRARY:FILEPATH=${DEPSDIR}/lib/libtk8.6.a \
    -DTCL_INCLUDE_PATH:FILEPATH=${DEPSDIR}/include \
    -DTCL_LIBRARY:FILEPATH=${DEPSDIR}/lib/libtcl8.6.a \
    -DX11_INCLUDE_DIR:PATH=${DEPSDIR}/include/X11 \
    -DX11_LIBRARIES="${DEPSDIR}/lib/libXau.a;${DEPSDIR}/lib/libXdmcp.a;${DEPSDIR}/lib/libX11.a;${DEPSDIR}/lib/libXext.a;${DEPSDIR}/lib/libICE.a;${DEPSDIR}/lib/libSM.a;${DEPSDIR}/lib/libXrender.a;${DEPSDIR}/lib/libXft.a;${DEPSDIR}/lib/libXss.a;${DEPSDIR}/lib/libxcb.a"
  )
fi

opensslparams=(-DOPENSSL_INCLUDE_DIR:PATH=${DEPSDIR}/include)
if [[ "${ARCH}" == "x86_64" && ${PYTHON_MINOR} -ge 11 ]]; then
  # openssl 3 appears to install to lib/64
  opensslparams+=(
    -DOPENSSL_LIBRARIES="${DEPSDIR}/lib/64/libssl.a;${DEPSDIR}/lib/64/libcrypto.a"
  )
else
  opensslparams+=(
    -DOPENSSL_LIBRARIES="${DEPSDIR}/lib/libssl.a;${DEPSDIR}/lib/libcrypto.a"
  )
fi

wget --no-verbose -O portable-python-cmake-buildsystem.tar.gz https://github.com/bjia56/portable-python-cmake-buildsystem/tarball/${CMAKE_BUILDSYSTEM_BRANCH}
gtar --no-same-permissions --no-same-owner -xf portable-python-cmake-buildsystem.tar.gz
rm *.tar.gz
mv *portable-python-cmake-buildsystem* portable-python-cmake-buildsystem
mkdir python-build
mkdir python-install
cd python-build
# https://stackoverflow.com/a/52240320
CFLAGS="${CFLAGS} -D_XOPEN_SOURCE=500 -D__EXTENSIONS__" LDFLAGS="${LDFLAGS} -lsocket -lnsl" cmake \
  "${cmake_verbose_flags[@]}" \
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
  "${opensslparams[@]}" \
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
  -DREADLINE_INCLUDE_PATH:PATH=${DEPSDIR}/include \
  -DREADLINE_LIBRARY:FILEPATH=${DEPSDIR}/lib/libreadline.a \
  -DCURSES_LIBRARIES:FILEPATH=${DEPSDIR}/lib/libncurses.a \
  -DPANEL_LIBRARIES:FILEPATH=${DEPSDIR}/lib/libpanel.a \
  -DGDBM_INCLUDE_PATH:PATH=${DEPSDIR}/include \
  -DGDBM_LIBRARY:FILEPATH=${DEPSDIR}/lib/libgdbm.a \
  -DGDBM_COMPAT_LIBRARY:FILEPATH=${DEPSDIR}/lib/libgdbm_compat.a \
  -DNDBM_TAG=NDBM \
  -DNDBM_USE=NDBM \
  "${additionalparams[@]}" \
  ../portable-python-cmake-buildsystem
gmake -j4
gmake install

cd ${BUILDDIR}
cp -r ${LICENSEDIR} ./python-install

echo "::endgroup::"
#################################
# Check executable dependencies #
#################################
echo "::group::Check executable dependencies"
cd ${BUILDDIR}

cd python-install
echo "python dependencies"
greadelf -d ./bin/python
echo
echo "libpython dependencies"
greadelf -d ./lib/libpython${PYTHON_VER}.so

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

python3 ${WORKDIR}/scripts/patch_pip_script.py ./bin/pip3
python3 ${WORKDIR}/scripts/patch_pip_script.py ./bin/pip${PYTHON_VER}

echo "::endgroup::"
###################
# Compress output #
###################
echo "::group::Compress output"
cd ${BUILDDIR}

python3 -m ensurepip
python3 -m pip install pyclean
python3 -m pyclean -v python-install
mv python-install python-${DISTRIBUTION}-${PYTHON_FULL_VER}-${PLATFORM}-${ARCH}
tar -czf ${WORKDIR}/python-${DISTRIBUTION}-${PYTHON_FULL_VER}-${PLATFORM}-${ARCH}.tar.gz python-${DISTRIBUTION}-${PYTHON_FULL_VER}-${PLATFORM}-${ARCH}
zip ${WORKDIR}/python-${DISTRIBUTION}-${PYTHON_FULL_VER}-${PLATFORM}-${ARCH}.zip $(tar tf ${WORKDIR}/python-${DISTRIBUTION}-${PYTHON_FULL_VER}-${PLATFORM}-${ARCH}.tar.gz)

echo "::endgroup::"
