#!/bin/bash

PLATFORM=windows
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
source ${SCRIPT_DIR}/utils.sh

if [ "${ARCH}" = "x86_64" ]; then
  CMAKE_ARCH=x64
  BINDEPS_ARCH=amd64
else
  CMAKE_ARCH=ARM64
  BINDEPS_ARCH=arm64
fi

function build_deps () {
  ###########
  # OpenSSL #
  ###########
  echo "::group::OpenSSL"
  cd ${BUILDDIR}

  if (( ${PYTHON_MINOR} < 11 )); then
    OPENSSL_VER=1.1.1u
    OPENSSL_LICENSE=LICENSE
  else
    OPENSSL_VER=3.0.15
    OPENSSL_LICENSE=LICENSE.txt
  fi
  curl -L https://github.com/python/cpython-bin-deps/archive/refs/tags/openssl-bin-${OPENSSL_VER}.tar.gz --output cpython-bin-deps-openssl-bin-${OPENSSL_VER}.tar.gz
  tar -xf cpython-bin-deps-openssl-bin-${OPENSSL_VER}.tar.gz
  cd cpython-bin-deps-openssl-bin-${OPENSSL_VER}
  mkdir ${DEPSDIR}/openssl
  cp -r ${BINDEPS_ARCH}/include ${DEPSDIR}/openssl/include
  # cmake apparently wants this here?
  cp ${DEPSDIR}/openssl/include/applink.c ${DEPSDIR}/openssl/include/openssl/applink.c

  # required by cmake
  mkdir ${DEPSDIR}/openssl/lib
  cp ${BINDEPS_ARCH}/lib* ${DEPSDIR}/openssl/lib/

  # for compatibility with old openssl so we don't need to conditionally copy
  mkdir ${DEPSDIR}/openssl/bin
  cp ${BINDEPS_ARCH}/lib* ${DEPSDIR}/openssl/bin/

  cd ${BINDEPS_ARCH}
  install_license ${OPENSSL_LICENSE} openssl-${OPENSSL_VER}

  echo "::endgroup::"
  #########
  # bzip2 #
  #########
  echo "::group::bzip2"
  cd ${BUILDDIR}

  git clone https://github.com/commontk/bzip2.git
  git -C bzip2 checkout 391dddabd24aee4a06e10ab6636f26dd93c21308
  mkdir ${DEPSDIR}/bzip2
  cd bzip2
  maybe_patch bzip2-1.0.8
  mkdir build
  cd build
  cmake \
    -G "Visual Studio 17 2022" -A ${CMAKE_ARCH} \
    -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
    -DCMAKE_INSTALL_PREFIX:PATH=${DEPSDIR}/bzip2 \
    ..
  cmake --build . --config Release -- /property:Configuration=Release
  cmake --build . --target INSTALL -- /property:Configuration=Release
  cd ..
  install_license ./LICENSE bzip2-1.0.8

  echo "::endgroup::"
  ########
  # lzma #
  ########
  echo "::group::lzma"
  cd ${BUILDDIR}

  download_verify_extract xz-5.4.5.tar.gz
  mkdir ${DEPSDIR}/xz
  cd xz-5.4.5
  maybe_patch
  mkdir build
  cd build
  cmake \
    -G "Visual Studio 17 2022" -A ${CMAKE_ARCH} \
    -DCMAKE_INSTALL_PREFIX:PATH=${DEPSDIR}/xz \
    ..
  cmake --build . --config Release -- /property:Configuration=Release
  cmake --build . --target INSTALL -- /property:Configuration=Release
  cd ..
  install_license

  echo "::endgroup::"
  ###########
  # sqlite3 #
  ###########
  echo "::group::sqlite3"
  cd ${BUILDDIR}

  download_and_verify sqlite-amalgamation-3430100.zip
  unzip -qq sqlite-amalgamation-3430100.zip
  cd sqlite-amalgamation-3430100
  maybe_patch
  cd ..
  mv sqlite-amalgamation-3430100 ${DEPSDIR}/sqlite3
  cd ${DEPSDIR}/sqlite3
  cl //c sqlite3.c
  lib sqlite3.obj

  echo "::endgroup::"
  ########
  # zlib #
  ########
  echo "::group::zlib"
  cd ${BUILDDIR}

  download_verify_extract zlib-1.3.1.tar.gz
  mkdir ${DEPSDIR}/zlib
  cd zlib-1.3.1
  maybe_patch
  mkdir build
  cd build
  cmake \
    -G "Visual Studio 17 2022" -A ${CMAKE_ARCH} \
    -DCMAKE_INSTALL_PREFIX:PATH=${DEPSDIR}/zlib \
    ..
  cmake --build . --config Release -- /property:Configuration=Release
  cmake --build . --target INSTALL -- /property:Configuration=Release
  cd ..
  install_license

  echo "::endgroup::"
  ##########
  # libffi #
  ##########
  echo "::group::libffi"
  cd ${BUILDDIR}

  curl -L https://github.com/python/cpython-bin-deps/archive/refs/tags/libffi-3.4.4.tar.gz --output cpython-bin-deps-libffi-3.4.4.tar.gz
  tar -xf cpython-bin-deps-libffi-3.4.4.tar.gz
  cd cpython-bin-deps-libffi-3.4.4
  mkdir ${DEPSDIR}/libffi
  cp -r ${BINDEPS_ARCH}/include ${DEPSDIR}/libffi/include
  mkdir ${DEPSDIR}/libffi/lib
  cp ${BINDEPS_ARCH}/libffi* ${DEPSDIR}/libffi/lib/
  install_license LICENSE libffi-3.4.4

  echo "::endgroup::"

  if [[ "${DISTRIBUTION}" != "headless" ]]; then
    #########
    # tcltk #
    #########
    echo "::group::tcltk"
    cd ${BUILDDIR}

    curl -L https://github.com/python/cpython-bin-deps/archive/refs/tags/tcltk-8.6.14.0.tar.gz --output cpython-bin-deps-tcltk-8.6.14.0.tar.gz
    tar -xf cpython-bin-deps-tcltk-8.6.14.0.tar.gz
    cd cpython-bin-deps-tcltk-8.6.14.0
    mkdir ${DEPSDIR}/tcltk
    cp -r ${BINDEPS_ARCH}/include ${DEPSDIR}/tcltk/include
    mkdir ${DEPSDIR}/tcltk/lib
    cp -r ${BINDEPS_ARCH}/lib/* ${DEPSDIR}/tcltk/lib/
    mkdir ${DEPSDIR}/tcltk/bin
    cp ${BINDEPS_ARCH}/bin/*.dll ${DEPSDIR}/tcltk/bin
    install_license ${BINDEPS_ARCH}/tcllicense.terms tcl-8.6.14.0
    install_license ${BINDEPS_ARCH}/tklicense.terms tk-8.6.14.0

    echo "::endgroup::"
  fi
}

if [[ "${PYTHON_ONLY}" == "false" ]]; then
  build_deps
fi
if [[ "${DEPS_ONLY}" == "true" ]]; then
  exit 0
fi

#########
# Build #
#########
echo "::group::Build setup"
cd ${BUILDDIR}

additionalparams=()
if [[ "${DISTRIBUTION}" != "headless" ]]; then
  additionalparams+=(
    -DTK_INCLUDE_PATH:FILEPATH=${DEPSDIR}/tcltk/include \
    -DTK_LIBRARY:FILEPATH=${DEPSDIR}/tcltk/lib/tk86t.lib \
    -DTCL_INCLUDE_PATH:FILEPATH=${DEPSDIR}/tcltk/include \
    -DTCL_LIBRARY:FILEPATH=${DEPSDIR}/tcltk/lib/tcl86t.lib
  )
fi

git clone https://github.com/bjia56/portable-python-cmake-buildsystem.git --branch ${CMAKE_BUILDSYSTEM_BRANCH} --single-branch --depth 1

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
    -G "Visual Studio 17 2022" -A ${CMAKE_ARCH} \
    -DPYTHON_VERSION=${PYTHON_FULL_VER} \
    -DPORTABLE_PYTHON_BUILD=ON \
    -DCMAKE_BUILD_TYPE:STRING=${BUILD_TYPE} \
    -DCMAKE_INSTALL_PREFIX:PATH=${BUILDDIR}/${python_install_dir} \
    -DBUILD_EXTENSIONS_AS_BUILTIN=OFF \
    -DBUILD_LIBPYTHON_SHARED=ON \
    -DBUILD_TESTING=${INSTALL_TEST} \
    -DINSTALL_TEST=${INSTALL_TEST} \
    -DINSTALL_MANUAL=OFF \
    -DBUILD_WININST=OFF \
    -DINSTALL_WINDOWS_TRADITIONAL:BOOL=OFF \
    -DOPENSSL_ROOT_DIR:PATH=${DEPSDIR}/openssl \
    -DSQLite3_INCLUDE_DIR:PATH=${DEPSDIR}/sqlite3 \
    -DSQLite3_LIBRARY:FILEPATH=${DEPSDIR}/sqlite3/sqlite3.lib \
    -DZLIB_INCLUDE_DIR:PATH=${DEPSDIR}/zlib/include \
    -DZLIB_LIBRARY:FILEPATH=${DEPSDIR}/zlib/lib/zlibstatic.lib \
    -DLZMA_INCLUDE_PATH:PATH=${DEPSDIR}/xz/include \
    -DLZMA_LIBRARY:FILEPATH=${DEPSDIR}/xz/lib/liblzma.lib \
    -DBZIP2_INCLUDE_DIR:PATH=${DEPSDIR}/bzip2/include \
    -DBZIP2_LIBRARIES:FILEPATH=${DEPSDIR}/bzip2/lib/libbz2.lib \
    -DLibFFI_INCLUDE_DIR:PATH=${DEPSDIR}/libffi/include \
    -DLibFFI_LIBRARY:FILEPATH=${DEPSDIR}/libffi/lib/libffi-8.lib \
    "${additionalparams[@]}" \
    ../portable-python-cmake-buildsystem
  cmake --build . --config ${BUILD_TYPE} -- /property:Configuration=${BUILD_TYPE}
  cmake --build . --target INSTALL -- /property:Configuration=${BUILD_TYPE}
  cp -r ${LICENSEDIR} ${BUILDDIR}/${python_install_dir}
  cd ${BUILDDIR}

  # Need to bundle openssl with the executable
  cp ${DEPSDIR}/openssl/bin/*.dll ${python_install_dir}/bin

  # Need to bundle libffi with the executable
  cp ${DEPSDIR}/libffi/lib/*.dll ${python_install_dir}/bin

  if [[ "${DISTRIBUTION}" != "headless" ]]; then
    # Need to bundle tcl/tk with the executable
    cp ${DEPSDIR}/tcltk/bin/*.dll ${python_install_dir}/bin
    cp -r ${DEPSDIR}/tcltk/lib/tcl8.6 ${python_install_dir}/lib
    cp -r ${DEPSDIR}/tcltk/lib/tk8.6 ${python_install_dir}/lib
  fi

  # Need to bundle vcredist
  #cp /c/WINDOWS/SYSTEM32/VCRUNTIME140.dll ${python_install_dir}/bin

  echo "::endgroup::"
  ###############
  # Test python #
  ###############
  echo "::group::Test python ${python_distro_ver}"
  cd ${BUILDDIR}

  ./${python_install_dir}/bin/python --version

  echo "::endgroup::"
  ###############
  # Preload pip #
  ###############
  echo "::group::Preload pip ${python_distro_ver}"
  cd ${BUILDDIR}

  ./${python_install_dir}/bin/python -m ensurepip
  ./${python_install_dir}/bin/python -m pip install -r ${WORKDIR}/baseline/requirements.txt

  ###################
  # Compress output #
  ###################
  echo "::group::Compress output ${python_distro_ver}"
  cd ${BUILDDIR}

  python3 -m pip install pyclean
  python3 -m pyclean -v ${python_install_dir}
  mv ${python_install_dir} python-${DISTRIBUTION}-${python_distro_ver}-${PLATFORM}-${ARCH}
  tar -czf ${WORKDIR}/python-${DISTRIBUTION}-${python_distro_ver}-${PLATFORM}-${ARCH}.tar.gz python-${DISTRIBUTION}-${python_distro_ver}-${PLATFORM}-${ARCH}
  7z.exe a ${WORKDIR}/python-${DISTRIBUTION}-${python_distro_ver}-${PLATFORM}-${ARCH}.zip python-${DISTRIBUTION}-${python_distro_ver}-${PLATFORM}-${ARCH}

  echo "::endgroup::"
}

build_python
if [[ "${PYTHON_MINOR}" == "13" ]]; then
  build_python t "-DWITH_FREE_THREADING=ON"
fi
