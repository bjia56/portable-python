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

cd $(dirname $(dirname $(which cosmocc)))
install_license

echo "::endgroup::"
########
# zlib #
########
echo "::group::zlib"
cd ${BUILDDIR}

download_verify_extract zlib-1.3.1.tar.gz
cd zlib*
maybe_patch
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

if (( ${PYTHON_MINOR} < 11 )); then
  download_verify_extract openssl-1.1.1w.tar.gz
else
  download_verify_extract openssl-3.0.15.tar.gz
fi
cd openssl*
maybe_patch
./Configure linux-generic64 no-asm no-shared no-dso no-engine --prefix=${DEPSDIR} --openssldir=${DEPSDIR}
make -j4
make install_sw
cp .aarch64/lib*.a ${DEPSDIR}/lib/.aarch64
install_license

echo "::endgroup::"
###########
# sqlite3 #
###########
echo "::group::sqlite3"
cd ${BUILDDIR}

download_verify_extract sqlite-autoconf-3450000.tar.gz
cd sqlite*
maybe_patch
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
maybe_patch
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
maybe_patch
CFLAGS="${CFLAGS} -std=c89" ./configure --with-normal --without-progs --enable-overwrite --disable-stripping --enable-widec --with-termlib --disable-database --with-fallbacks=xterm,xterm-256color,screen-256color,linux,vt100 --prefix=${DEPSDIR}
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
maybe_patch
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
maybe_patch bzip2-1.0.8
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
maybe_patch
mkdir build
cd build
cmake .. -DCMAKE_INSTALL_PREFIX:PATH=${DEPSDIR} -DCMAKE_C_COMPILER=${CC} -DCMAKE_CXX_COMPILER=${CXX} -DCMAKE_CXX_FLAGS="${CXXFLAGS}" -DCMAKE_AR=${AR}
make -j4
make install
cp .aarch64/liblzma.a ${DEPSDIR}/lib/.aarch64
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
maybe_patch
./configure --enable-libgdbm-compat --disable-shared --prefix=${DEPSDIR}
make -j4
make install
cp src/.libs/.aarch64/libgdbm.a ${DEPSDIR}/lib/.aarch64
cp compat/.libs/.aarch64/libgdbm_compat.a ${DEPSDIR}/lib/.aarch64
install_license

echo "::endgroup::"
##########
# Python #
##########
echo "::group::Build setup"
cd ${BUILDDIR}

wget --no-verbose -O portable-python-cmake-buildsystem.tar.gz https://github.com/bjia56/portable-python-cmake-buildsystem/tarball/${CMAKE_BUILDSYSTEM_BRANCH}
tar -xf portable-python-cmake-buildsystem.tar.gz
rm *.tar.gz
mv *portable-python-cmake-buildsystem* portable-python-cmake-buildsystem

function build_python () {
  python_suffix=$1
  cmake_python_features=$2
  python_distro_ver=${PYTHON_FULL_VER}${python_suffix}

  python_build_dir=python-build-${python_distro_ver}
  python_install_dir=python-install-${python_distro_ver}

  echo "::group::Python ${python_distro_ver}"
  cd ${BUILDDIR}

  mkdir ${python_build_dir}
  mkdir ${python_install_dir}
  cd ${python_build_dir}
  cmake \
    "${cmake_verbose_flags[@]}" \
    ${cmake_python_features} \
    -DCMAKE_C_COMPILER=${CC} \
    -DCMAKE_CXX_COMPILER=${CXX} \
    -DCMAKE_CXX_FLAGS="${CXXFLAGS}" \
    -DCMAKE_AR=${AR} \
    -DCMAKE_IGNORE_PATH=/usr/include \
    -DPYTHON_VERSION=${PYTHON_FULL_VER} \
    -DPORTABLE_PYTHON_BUILD=ON \
    -DCMAKE_BUILD_TYPE:STRING=${BUILD_TYPE} \
    -DCMAKE_INSTALL_PREFIX:PATH=${BUILDDIR}/${python_install_dir} \
    -DBUILD_EXTENSIONS_AS_BUILTIN=ON \
    -DWITH_STATIC_DEPENDENCIES=ON \
    -DBUILD_LIBPYTHON_SHARED=OFF \
    -DUSE_SYSTEM_LIBRARIES=OFF \
    -DBUILD_TESTING=${INSTALL_TEST} \
    -DINSTALL_TEST=${INSTALL_TEST} \
    -DINSTALL_MANUAL=OFF \
    -DENABLE_CTYPES=OFF \
    -DOPENSSL_INCLUDE_DIR:PATH=${DEPSDIR}/include \
    -DOPENSSL_LIBRARIES="${DEPSDIR}/lib/libssl.a;${DEPSDIR}/lib/libcrypto.a" \
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
    -DREADLINE_INCLUDE_PATH:PATH=${DEPSDIR}/include \
    -DREADLINE_LIBRARY:FILEPATH=${DEPSDIR}/lib/libreadline.a \
    -DCURSES_LIBRARIES:FILEPATH=${DEPSDIR}/lib/libncursesw.a \
    -DTINFO_LIBRARY:FILEPATH=${DEPSDIR}/lib/libtinfow.a \
    -DPANEL_LIBRARIES:FILEPATH=${DEPSDIR}/lib/libpanelw.a \
    -DGDBM_INCLUDE_PATH:PATH=${DEPSDIR}/include \
    -DGDBM_LIBRARY:FILEPATH=${DEPSDIR}/lib/libgdbm.a \
    -DGDBM_COMPAT_LIBRARY:FILEPATH=${DEPSDIR}/lib/libgdbm_compat.a \
    -DNDBM_TAG=NDBM \
    -DNDBM_USE=NDBM \
    ../portable-python-cmake-buildsystem
  make -j4
  make install

  cd ${BUILDDIR}
  cp ./${python_install_dir}/bin/python ./${python_install_dir}/bin/python.com
  rm ./${python_install_dir}/bin/python
  rm ./${python_install_dir}/bin/python3
  rm ./${python_install_dir}/bin/python${PYTHON_VER}
  if [[ "${DEBUG_CI}" == "true" ]]; then
    cp ./${python_build_dir}/bin/python.com.dbg ./${python_install_dir}/bin/
  fi
  cp -r ./${python_build_dir}/lib/.aarch64 ./${python_install_dir}/lib/
  cp -r ${LICENSEDIR} ./${python_install_dir}

  echo "::endgroup::"
  ###############
  # Test python #
  ###############
  echo "::group::Test python ${python_distro_ver}"
  cd ${BUILDDIR}

  cd ${python_install_dir}
  ./bin/python.com --version

  echo "::endgroup::"
  ###############
  # Preload pip #
  ###############
  echo "::group::Preload pip ${python_distro_ver}"
  cd ${BUILDDIR}

  cd ${python_install_dir}
  ./bin/python.com -m ensurepip
  ./bin/python.com -m pip install -r ${WORKDIR}/baseline/requirements.txt

  python3 ${WORKDIR}/scripts/patch_pip_script.py ./bin/pip3 .com
  python3 ${WORKDIR}/scripts/patch_pip_script.py ./bin/pip${PYTHON_VER} .com

  echo "::endgroup::"
  ##############
  # Assimilate #
  ##############
  echo "::group::Assimilate python.com"
  cd ${BUILDDIR}

  cd ${python_install_dir}
  $(which assimilate) -e -x -o ./bin/python.x86_64.elf ./bin/python.com
  $(which assimilate) -e -a -o ./bin/python.aarch64.elf ./bin/python.com
  $(which assimilate) -m -x -o ./bin/python.x86_64.macho ./bin/python.com

  # M1 macs should rely on xcode to compile the launcher from the embedded ape-m1.c
  #$(which assimilate) -m -a -o ./bin/python.aarch64.macho ./bin/python.com

  echo "::endgroup::"
  ###################
  # Compress output #
  ###################
  echo "::group::Compress output ${python_distro_ver}"
  cd ${BUILDDIR}

  python3 -m pip install pyclean
  python3 -m pyclean -v ${python_install_dir}
  mv ${python_install_dir} python-${python_distro_ver}-${PLATFORM}-${ARCH}
  tar -czf ${WORKDIR}/python-${python_distro_ver}-${PLATFORM}-${ARCH}.tar.gz python-${python_distro_ver}-${PLATFORM}-${ARCH}
  zip ${WORKDIR}/python-${python_distro_ver}-${PLATFORM}-${ARCH}.zip $(tar tf ${WORKDIR}/python-${python_distro_ver}-${PLATFORM}-${ARCH}.tar.gz)

  echo "::endgroup::"
}

build_python
if [[ "${PYTHON_MINOR}" == "13" ]]; then
  build_python t "-DWITH_FREE_THREADING=ON"
fi
