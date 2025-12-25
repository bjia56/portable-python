#!/bin/bash

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
source ${SCRIPT_DIR}/utils.sh

export CFLAGS="-I${DEPSDIR}/include -fPIC"
export CPPFLAGS="-I${DEPSDIR}/include -fPIC"
export CXXFLAGS="${CPPFLAGS}"
export LDFLAGS="-L${DEPSDIR}/lib"
export PKG_CONFIG_PATH="${DEPSDIR}/lib/pkgconfig:${DEPSDIR}/share/pkgconfig"
export AL_OPTS="-I/usr/local/share/aclocal -I${DEPSDIR}/share/aclocal"

function build_deps () {
  mkdir -p ${DEPSDIR}/share/aclocal

  ########
  # zlib #
  ########
  echo "::group::zlib"
  cd ${BUILDDIR}

  download_verify_extract zlib-1.3.1.tar.gz
  cd zlib*
  maybe_patch
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
  maybe_patch
  ./Configure BSD-${ARCH} no-shared --prefix=${DEPSDIR} --openssldir=${DEPSDIR}
  gmake -j4
  gmake install_sw
  install_license

  echo "::endgroup::"
  ##########
  # libffi #
  ##########
  echo "::group::libffi"
  cd ${BUILDDIR}

  download_verify_extract libffi-3.5.2.tar.gz
  cd libffi*
  maybe_patch
  ./configure --disable-shared --prefix=${DEPSDIR}
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
  maybe_patch
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
  maybe_patch
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
  maybe_patch
  ./configure --with-normal --without-shared --without-progs --enable-overwrite --disable-stripping --enable-widec --with-termlib --disable-database --with-fallbacks=xterm,xterm-256color,screen-256color,linux,vt100 --prefix=${DEPSDIR}
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
  maybe_patch
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

  wget --no-verbose -O bzip2.tar.gz https://github.com/commontk/bzip2/archive/391dddabd24aee4a06e10ab6636f26dd93c21308.tar.gz
  tar --no-same-permissions --no-same-owner -xf bzip2*.tar.gz
  rm *.tar.gz
  cd bzip2-*
  maybe_patch bzip2-1.0.8
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
  maybe_patch
  mkdir build
  cd build
  cmake -DCMAKE_INSTALL_PREFIX:PATH=${DEPSDIR} -DBUILD_SHARED_LIBS=OFF ..
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
  maybe_patch
  mkdir build
  cd build
  cmake -DCMAKE_INSTALL_PREFIX:PATH=${DEPSDIR} ..
  make -j4
  make install
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
  maybe_patch
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
  maybe_patch
  ./configure --with-zlib-prefix=${DEPSDIR}  --enable-static --disable-shared --disable-tools --prefix=${DEPSDIR}
  gmake -j4
  gmake install
  install_license

  echo "::endgroup::"
  #############
  # libgcrypt #
  #############
  echo "::group::libgcrypt"
  cd ${BUILDDIR}

  download_verify_extract libgpg-error-1.47.tar.bz2
  cd libgpg-error*
  maybe_patch
  ./configure --enable-static --disable-shared --prefix=${DEPSDIR}
  gmake -j4
  gmake install
  install_license ./COPYING.LIB

  cd ${BUILDDIR}

  download_verify_extract libgcrypt-1.10.3.tar.bz2
  cd libgcrypt*
  maybe_patch
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
  maybe_patch
  CFLAGS="${CFLAGS} -I${DEPSDIR}/include/libxml2" ./configure --enable-static --disable-shared --with-libxml-prefix=${DEPSDIR} --without-python --prefix=${DEPSDIR}
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
  maybe_patch
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
  maybe_patch
  ./configure --enable-libxml2 --disable-cache-build --enable-static --disable-shared --prefix=${DEPSDIR}
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
      maybe_patch
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
    cd tcl*
    maybe_patch
    cd unix
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
    cd tk*
    maybe_patch
    cd unix
    LDFLAGS="${LDFLAGS} -lxml2 -lxcb -lXau" ./configure --enable-static --disable-shared --prefix=${DEPSDIR}
    gmake -j4
    gmake install
    cd ..
    install_license ./license.terms

    echo "::endgroup::"
  fi
}

if [[ "${PYTHON_ONLY}" == "false" ]]; then
  build_deps
fi
if [[ "${DEPS_ONLY}" == "true" ]]; then
  exit 0
fi

##########
# Python #
##########
echo "::group::Build setup"
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

ldconfig -i -m -v ${DEPSDIR}/lib

wget --no-verbose -O portable-python-cmake-buildsystem.tar.gz https://github.com/bjia56/portable-python-cmake-buildsystem/tarball/${CMAKE_BUILDSYSTEM_BRANCH}
tar --no-same-permissions --no-same-owner -xf portable-python-cmake-buildsystem.tar.gz
rm *.tar.gz
mv *portable-python-cmake-buildsystem* portable-python-cmake-buildsystem

wget -O ${WORKDIR}/pyclean https://github.com/bjia56/pyclean-standalone/releases/download/v3.4.0.0/pyclean
chmod +x ${WORKDIR}/pyclean

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
    -DCMAKE_IGNORE_PATH=/usr/include \
    -DPYTHON_VERSION=${PYTHON_FULL_VER} \
    -DPORTABLE_PYTHON_BUILD=ON \
    -DCMAKE_BUILD_TYPE:STRING=${BUILD_TYPE} \
    -DCMAKE_INSTALL_PREFIX:PATH=${BUILDDIR}/${python_install_dir} \
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
    -DREADLINE_INCLUDE_PATH:PATH=${DEPSDIR}/include \
    -DREADLINE_LIBRARY:FILEPATH=${DEPSDIR}/lib/libreadline.a \
    -DCURSES_LIBRARIES="${DEPSDIR}/lib/libncursesw.a;${DEPSDIR}/lib/libtinfow.a" \
    -DPANEL_LIBRARIES:FILEPATH=${DEPSDIR}/lib/libpanelw.a \
    -DGDBM_INCLUDE_PATH:PATH=${DEPSDIR}/include \
    -DGDBM_LIBRARY:FILEPATH=${DEPSDIR}/lib/libgdbm.a \
    -DGDBM_COMPAT_LIBRARY:FILEPATH=${DEPSDIR}/lib/libgdbm_compat.a \
    -DNDBM_TAG=NDBM \
    -DNDBM_USE=NDBM \
    "${additionalparams[@]}" \
    ../portable-python-cmake-buildsystem
  make -j4
  make install

  cd ${BUILDDIR}
  cp -r ${LICENSEDIR} ./${python_install_dir}

  echo "::endgroup::"
  #################################
  # Check executable dependencies #
  #################################
  echo "::group::Check executable dependencies ${python_distro_ver}"
  cd ${BUILDDIR}

  cd ${python_install_dir}
  echo "python dependencies"
  readelf -d ./bin/python
  echo
  echo "libpython dependencies"
  readelf -d ./lib/libpython${PYTHON_VER}${python_suffix}.so

  echo "::endgroup::"
  ###############
  # Test python #
  ###############
  echo "::group::Test python ${python_distro_ver}"
  cd ${BUILDDIR}

  cd ${python_install_dir}
  ./bin/python --version

  echo "::endgroup::"
  ###############
  # Preload pip #
  ###############
  echo "::group::Preload pip ${python_distro_ver}"
  cd ${BUILDDIR}

  cd ${python_install_dir}
  ./bin/python -m ensurepip
  ./bin/python -m pip install -r ${WORKDIR}/baseline/requirements.txt

  python3 ${WORKDIR}/scripts/patch_pip_script.py ./bin/pip3
  python3 ${WORKDIR}/scripts/patch_pip_script.py ./bin/pip${PYTHON_VER}

  echo "::endgroup::"
  ###################
  # Compress output #
  ###################
  echo "::group::Compress output ${python_distro_ver}"
  cd ${BUILDDIR}

  ${WORKDIR}/pyclean -v ${python_install_dir}
  mv ${python_install_dir} python-${DISTRIBUTION}-${python_distro_ver}-${PLATFORM}-${ARCH}
  tar -czf ${WORKDIR}/python-${DISTRIBUTION}-${python_distro_ver}-${PLATFORM}-${ARCH}.tar.gz python-${DISTRIBUTION}-${python_distro_ver}-${PLATFORM}-${ARCH}
  zip ${WORKDIR}/python-${DISTRIBUTION}-${python_distro_ver}-${PLATFORM}-${ARCH}.zip $(tar tf ${WORKDIR}/python-${DISTRIBUTION}-${python_distro_ver}-${PLATFORM}-${ARCH}.tar.gz)

  echo "::endgroup::"
}

build_python
if [[ "${PYTHON_MINOR}" == "13" ]]; then
  build_python t "-DWITH_FREE_THREADING=ON"
fi
