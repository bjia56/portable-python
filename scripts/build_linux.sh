#!/bin/bash

ARCH=$1
PYTHON_FULL_VER=$2
PYTHON_VER=$(echo ${PYTHON_FULL_VER} | cut -d "." -f 1-2)

set -ex

########################
# Install dependencies #
########################
echo "::group::Install dependencies"

export DEBIAN_FRONTEND=noninteractive
apt update
apt -y upgrade
apt -y install build-essential python3 python3-pip git wget

# dependencies for enabled python extensions
apt -y install zlib1g-dev libssl-dev libffi-dev libsqlite3-dev
apt -y install libreadline-dev libncurses-dev libbz2-dev liblzma-dev
apt -y install uuid-dev libgdbm-dev tk-dev libxcb1-dev

# cmake
# we are pulling the precompiled cmake available as a python package
# unfortunately, python and pip in this old ubuntu distro can't install
# the latest pip, and can't understand what manylinux2014 is, so this
# is a hack to rename the wheel for pip to install it
case "$ARCH" in
  x86_64)
    wget -q https://files.pythonhosted.org/packages/b5/3a/0d5889762ec82d3c556cfab075e6cdbca06dc5cff55436950152d63bb194/cmake-3.26.4-py2.py3-none-manylinux2014_x86_64.manylinux_2_17_x86_64.whl
    ;;
  aarch64)
    wget -q https://files.pythonhosted.org/packages/0d/41/85549e9645097cddc7279886eafeafc7462215f309133ea2eae4941f9c35/cmake-3.26.4-py2.py3-none-manylinux2014_aarch64.manylinux_2_17_aarch64.whl
    ;;
  armv7l)
    wget -q https://www.piwheels.org/simple/cmake/cmake-3.26.4-cp37-cp37m-linux_armv7l.whl
    ;;
esac
mv cmake*.whl cmake-3.26.4-py2.py3-none-any.whl
python3 -m pip install cmake-3.26.4-py2.py3-none-any.whl

# patchelf
patchelf_ver=0.17.2
wget -q https://github.com/NixOS/patchelf/releases/download/${patchelf_ver}/patchelf-${patchelf_ver}-${ARCH}.tar.gz
tar -xzf patchelf*.tar.gz
mv ./bin/patchelf /usr/local/bin/patchelf

# copy build scripts from our workspace to build directory
mkdir -p /build
cp -r /work/scripts /build

echo "::endgroup::"
###############
# Setup build #
###############
echo "::group::Setup build"

cd /build
mkdir python-build
mkdir python-install

#git clone https://github.com/python-cmake-buildsystem/python-cmake-buildsystem.git
git clone https://github.com/bjia56/python-cmake-buildsystem.git --branch linux-static-libs --single-branch --depth 1

echo "::endgroup::"
#############
# Run build #
#############
echo "::group::Run build"

if [[ "${ARCH}" == "armv7l" ]]; then
  cd /tmp
  wget -q https://www.bytereef.org/software/mpdecimal/releases/mpdecimal-2.5.0.tar.gz
  tar -xzf mpdecimal*.tar.gz
  cd mpdecimal-2.5.0
  ./configure
  make
  make install
  cd /build
fi

cd /build/python-build
additionalparams=()
if [[ "${ARCH}" == "armv7l" ]]; then
  additionalparams+=(-DUSE_SYSTEM_LIBMPDEC=ON)
  export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib
fi
cmake --trace \
  -DPYTHON_VERSION=${PYTHON_FULL_VER} \
  -DCMAKE_BUILD_TYPE:STRING=Release \
  -DWITH_STATIC_DEPENDENCIES=ON \
  -DCMAKE_INSTALL_PREFIX:PATH=${PWD}/../python-install \
  -DBUILD_EXTENSIONS_AS_BUILTIN=ON \
  -DBUILD_LIBPYTHON_SHARED=ON \
  "${additionalparams[@]}" \
  -DBUILD_TESTING=ON \
  ../python-cmake-buildsystem
make VERBOSE=1 -j8
make install

tar -czf /work/build-python-${PYTHON_FULL_VER}-linux-${ARCH}.tar.gz .

echo "::endgroup::"
#############################################
# Check executable dependencies (pre-patch) #
#############################################
echo "::group::Check executable dependencies (pre-patch)"

cd /build/python-install
echo "python dependencies"
ldd -v -r ./bin/python
echo
echo "libpython dependencies"
ldd -v -r ./lib/libpython${PYTHON_VER}.so

echo "::endgroup::"
################
# Patch python #
################
echo "::group::Patch python"

/build/scripts/patch_libpython.sh ./lib/libpython${PYTHON_VER}.so ./bin/python
patchelf --replace-needed libpython${PYTHON_VER}.so "\$ORIGIN/../lib/libpython${PYTHON_VER}.so" ./bin/python

echo "::endgroup::"
##############################################
# Check executable dependencies (post-patch) #
##############################################
echo "::group::Check executable dependencies (post-patch)"

# we don't make ldd errors fatal here since sometimes ldd can
# crash but the patched binaries still work
echo "python dependencies"
ldd -v -r ./bin/python || true
echo
echo "libpython dependencies"
ldd -v -r ./lib/libpython${PYTHON_VER}.so || true

echo "::endgroup::"
###############
# Test python #
###############
echo "::group::Test python"

./bin/python --version

echo "::endgroup::"
###############
# Preload pip #
###############
echo "::group::Preload pip"

./bin/python -m ensurepip

echo "::endgroup::"
###################
# Compress output #
###################
echo "::group::Compress output"

cd ..
mv python-install python-${PYTHON_FULL_VER}-linux-${ARCH}
tar -czf /work/python-${PYTHON_FULL_VER}-linux-${ARCH}.tar.gz python-${PYTHON_FULL_VER}-linux-${ARCH}

echo "::endgroup::"
