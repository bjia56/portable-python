#!/bin/bash

PLATFORM=windows
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
source ${SCRIPT_DIR}/utils.sh

##############
# Initialize #
##############
echo "::group::Initialize"
cd ${BUILDDIR}

git clone https://github.com/bjia56/portable-python-cmake-buildsystem.git --branch ${CMAKE_BUILDSYSTEM_BRANCH} --single-branch --depth 1

echo "::endgroup::"
###########
# OpenSSL #
###########
echo "::group::OpenSSL"
cd ${BUILDDIR}

curl -L https://github.com/Slicer/Slicer-OpenSSL/releases/download/1.1.1g/OpenSSL_1_1_1g-install-msvc1900-64-Release.tar.gz --output openssl.tar.gz
tar -xf openssl.tar.gz
mv OpenSSL_1_1_1g-install-msvc1900-64-Release ${DEPSDIR}/openssl
mkdir openssl-1.1.1g
cd openssl-1.1.1g
curl -L https://www.openssl.org/source/license-openssl-ssleay.txt --output LICENSE
install_license

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
  -G "Visual Studio 17 2022" -A x64 \
  -DCMAKE_INSTALL_PREFIX:PATH=${DEPSDIR}/bzip2 \
  ..
cmake --build . --config Release -- /property:Configuration=Release
cmake --build . --target INSTALL -- /property:Configuration=Release
cd ..
install_license

echo "::endgroup::"
########
# lzma #
########
echo "::group::lzma"
cd ${BUILDDIR}

download_verify_extract xz-5.4.5.tar.gz
mkdir ${DEPSDIR}/xz
cd xz-5.4.5
mkdir build
cd build
cmake \
  -G "Visual Studio 17 2022" -A x64 \
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
mkdir build
cd build
cmake \
  -G "Visual Studio 17 2022" -A x64 \
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

git clone https://github.com/python-cmake-buildsystem/libffi.git --branch libffi-cmake-buildsystem-v3.4.2-2021-06-28-f9ea416 --single-branch --depth 1
mkdir ${DEPSDIR}/libffi
cd libffi
mkdir build
cd build
cmake \
  -G "Visual Studio 17 2022" -A x64 \
  -DCMAKE_INSTALL_PREFIX:PATH=${DEPSDIR}/libffi \
  ..
cmake --build . --config Release -- /property:Configuration=Release
cmake --build . --target INSTALL -- /property:Configuration=Release
cd ..
install_license

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
  -G "Visual Studio 17 2022" -A x64 \
  -DPYTHON_VERSION=${PYTHON_FULL_VER} \
  -DPORTABLE_PYTHON_BUILD=ON \
  -DCMAKE_BUILD_TYPE:STRING=Debug \
  -DCMAKE_INSTALL_PREFIX:PATH=${BUILDDIR}/python-install \
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
  -DLibFFI_LIBRARY:FILEPATH=${DEPSDIR}/libffi/lib/ffi_static.lib \
  ../portable-python-cmake-buildsystem
cmake --build . --config Debug -- /property:Configuration=Debug
cmake --build . --target INSTALL -- /property:Configuration=Debug
cp -r ${LICENSEDIR} ${BUILDDIR}/python-install
cd ${BUILDDIR}

# Need to bundle openssl with the executable
cp ${DEPSDIR}/openssl/bin/*.dll python-install/bin

# Need to bundle vcredist
#cp /c/WINDOWS/SYSTEM32/VCRUNTIME140.dll python-install/bin

echo "::endgroup::"
###############
# Test python #
###############
echo "::group::Test python"
cd ${BUILDDIR}

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
mv python-install python-${PYTHON_FULL_VER}-windows-${ARCH}
tar -czf ${WORKDIR}/python-${PYTHON_FULL_VER}-windows-${ARCH}.tar.gz python-${PYTHON_FULL_VER}-windows-${ARCH}
7z.exe a ${WORKDIR}/python-${PYTHON_FULL_VER}-windows-${ARCH}.zip python-${PYTHON_FULL_VER}-windows-${ARCH}

echo "::endgroup::"
