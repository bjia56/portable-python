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

mkdir -p ${DEPSDIR}/lib/.aarch64

echo "::endgroup::"
########
# zlib #
########
echo "::group::zlib"
cd ${BUILDDIR}

download_verify_extract zlib-1.3.1.tar.gz
cd zlib*
./configure --prefix=${DEPSDIR} --static
make -j4
make install
cp .aarch64/libz.a ${DEPSDIR}/lib/.aarch64
install_license

echo "::endgroup::"
###########
# OpenSSL #
###########
echo "::group::OpenSSL"
cd ${BUILDDIR}

download_verify_extract openssl-1.1.1w.tar.gz
cd openssl*
./Configure linux-generic64 no-asm no-shared no-dso no-engine --prefix=${DEPSDIR} --openssldir=${DEPSDIR}
make -j4
make install_sw
cp .aarch64/lib*.a ${DEPSDIR}/lib/.aarch64
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
CC="x86_64-unknown-cosmo-cc" AR="x86_64-unknown-cosmo-ar" ./configure --prefix ${DEPSDIR} --disable-shared --enable-static --disable-exec-static-tramp
make -j4
make install
cd ${BUILDDIR}
mkdir libffi-arm64-out
cd libffi-3.4.6-arm64
CC="aarch64-unknown-cosmo-cc" AR="aarch64-unknown-cosmo-ar" ./configure --prefix ${BUILDDIR}/libffi-arm64-out --disable-shared --enable-static --disable-exec-static-tramp --host=aarch64
make -j4
make install
install_license

cd ${BUILDDIR}
cp ${BUILDDIR}/libffi-arm64-out/lib/libffi.a ${DEPSDIR}/lib/.aarch64/libffi.a

echo "::endgroup::"
###########
# sqlite3 #
###########
echo "::group::sqlite3"
cd ${BUILDDIR}

download_verify_extract sqlite-autoconf-3450000.tar.gz
cd sqlite*
sed -i "s/PACKAGE_STRING='sqlite 3.45.0'/PACKAGE_STRING='sqlite\\\\\\\\x203.45.0'/g" configure
./configure --prefix=${DEPSDIR} --disable-shared
make -j4
make install
cp .libs/.aarch64/libsqlite3.a ${DEPSDIR}/lib/.aarch64

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
cp lib/.libs/.aarch64/libexpat.a ${DEPSDIR}/lib/.aarch64
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
cp lib/.aarch64/lib*.a ${DEPSDIR}/lib/.aarch64
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
cp .aarch64/lib*.a ${DEPSDIR}/lib/.aarch64
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
cmake .. -DCMAKE_INSTALL_PREFIX:PATH=${DEPSDIR} -DCMAKE_C_COMPILER=${CC} -DCMAKE_CXX_COMPILER=${CXX} -DCMAKE_CXX_FLAGS="${CXXFLAGS}" -DCMAKE_AR=${AR}
make -j4
make install
cp .aarch64/libbz2.a ${DEPSDIR}/lib/.aarch64
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
sed -i "s/PACKAGE_NAME \"XZ Utils\"/PACKAGE_NAME \"XZ\\\\\\\\x20Utils\"/g" CMakeLists.txt
mkdir build
cd build
cmake .. -DCMAKE_INSTALL_PREFIX:PATH=${DEPSDIR} -DCMAKE_C_COMPILER=${CC} -DCMAKE_CXX_COMPILER=${CXX} -DCMAKE_CXX_FLAGS="${CXXFLAGS}" -DCMAKE_AR=${AR}
make -j4
make install
cp .aarch64/liblzma.a ${DEPSDIR}/lib/.aarch64
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
cmake .. -DCMAKE_INSTALL_PREFIX:PATH=${DEPSDIR} -DBUILD_SHARED_LIBS=OFF -DCMAKE_C_COMPILER=${CC} -DCMAKE_CXX_COMPILER=${CXX} -DCMAKE_CXX_FLAGS="${CXXFLAGS}" -DCMAKE_AR=${AR}
make -j4
make install
cp .aarch64/lib*.a ${DEPSDIR}/lib/.aarch64
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
make -j4
make install
cp src/.libs/.aarch64/libgdbm.a ${DEPSDIR}/lib/.aarch64
cp compat/.libs/.aarch64/libgdbm_compat.a ${DEPSDIR}/lib/.aarch64
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
cp .libs/.aarch64/libxml2.a ${DEPSDIR}/lib/.aarch64
install_license ./Copyright

echo "::endgroup::"
############
# libpng16 #
############
echo "::group::libpng16"
cd ${BUILDDIR}

download_verify_extract libpng-1.6.41.tar.gz
cd libpng*
./configure --with-zlib-prefix=${DEPSDIR} --disable-tools --disable-arm-neon --disable-shared --prefix=${DEPSDIR}
make -j4
make install
cp .libs/.aarch64/libpng16.a ${DEPSDIR}/lib/.aarch64

echo "::endgroup::"
#############
# libgcrypt #
#############
echo "::group::libgcrypt"
cd ${BUILDDIR}

download_verify_extract libgpg-error-1.47.tar.bz2
cd libgpg-error*
sed -i '1i #include <errno.h>' src/mkerrcodes.c 
./configure --disable-shared --prefix=${DEPSDIR}
make -j4
make install
cp src/.libs/.aarch64/libgpg-error.a ${DEPSDIR}/lib/.aarch64
install_license ./COPYING.LIB

cd ${BUILDDIR}

download_verify_extract libgcrypt-1.10.3.tar.bz2
cp -r libgcrypt-1.10.3 libgcrypt-1.10.3-arm64
cd libgcrypt-1.10.3
CC="x86_64-unknown-cosmo-cc" AR="x86_64-unknown-cosmo-ar" ./configure --disable-asm --disable-shared --disable-doc --prefix=${DEPSDIR}
make -j4
make install
cd ${BUILDDIR}
mkdir libgcrypt-arm64-out
cd libgcrypt-1.10.3-arm64
CC="aarch64-unknown-cosmo-cc" AR="aarch64-unknown-cosmo-ar" LDFLAGS="-L${DEPSDIR}/lib/.aarch64" ./configure --disable-asm --disable-shared --disable-doc --host=aarch64 --prefix=${BUILDDIR}/libgcrypt-arm64-out
make -j4
make install
install_license ./COPYING.LIB

cd ${BUILDDIR}
cp ${BUILDDIR}/libgcrypt-arm64-out/lib/libgcrypt.a ${DEPSDIR}/lib/.aarch64/libgcrypt.a

echo "::endgroup::"
###########
# libxslt #
###########
echo "::group::libxslt"
cd ${BUILDDIR}

download_verify_extract libxslt-1.1.39.tar.xz
cd libxslt*
CFLAGS="${CFLAGS} -I${DEPSDIR}/include/libxml2" ./configure --with-libxml-prefix=${DEPSDIR} --without-python --disable-shared --prefix=${DEPSDIR}
make -j4
make install
cp libxslt/.libs/.aarch64/libxslt.a ${DEPSDIR}/lib/.aarch64
install_license

echo "::endgroup::"
############
# freetype #
############
echo "::group::freetype"
cd ${BUILDDIR}

download_verify_extract freetype-2.13.2.tar.gz
cd freetype*
./configure --disable-shared --prefix=${DEPSDIR}
make -j4
make install
cp objs/.libs/.aarch64/libfreetype.a ${DEPSDIR}/lib/.aarch64
sed -i "s/libbrotlidec/libbrotlidec, libbrotlicommon/g" ${DEPSDIR}/lib/pkgconfig/freetype2.pc
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
cp src/.libs/.aarch64/libfontconfig.a ${DEPSDIR}/lib/.aarch64
install_license

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
  -DCMAKE_C_COMPILER=${CC} \
  -DCMAKE_CXX_COMPILER=${CXX} \
  -DCMAKE_CXX_FLAGS="${CXXFLAGS}" \
  -DCMAKE_AR=${AR} \
  -DCMAKE_IGNORE_PATH=/usr/include \
  -DPYTHON_VERSION=${PYTHON_FULL_VER} \
  -DPORTABLE_PYTHON_BUILD=ON \
  -DCMAKE_BUILD_TYPE:STRING=${BUILD_TYPE} \
  -DCMAKE_INSTALL_PREFIX:PATH=${BUILDDIR}/python-install \
  -DBUILD_EXTENSIONS_AS_BUILTIN=ON \
  -DWITH_STATIC_DEPENDENCIES=ON \
  -DBUILD_LIBPYTHON_SHARED=OFF \
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
  -DCURSES_LIBRARIES:FILEPATH=${DEPSDIR}/lib/libncurses.a \
  -DPANEL_LIBRARIES:FILEPATH=${DEPSDIR}/lib/libpanel.a \
  -DGDBM_INCLUDE_PATH:FILEPATH=${DEPSDIR}/include/gdbm.h \
  -DGDBM_LIBRARY:FILEPATH=${DEPSDIR}/lib/libgdbm.a \
  -DGDBM_COMPAT_LIBRARY:FILEPATH=${DEPSDIR}/lib/libgdbm_compat.a \
  -DNDBM_TAG=NDBM \
  -DNDBM_USE=NDBM \
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
