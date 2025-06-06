#!/bin/bash

set -e

CMAKE_BUILDSYSTEM_BRANCH=${PORTABLE_PYTHON_BUILDSYSTEM_BRANCH}
echo "Selected portable-python-cmake-buildsystem branch: ${CMAKE_BUILDSYSTEM_BRANCH}"

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"

ARCH=$1
PYTHON_FULL_VER=$2

DISTRIBUTION=$3
PYTHON_VER=$(echo ${PYTHON_FULL_VER} | cut -d "." -f 1-2)
PYTHON_MAJOR=$(echo ${PYTHON_VER} | cut -d "." -f 1)
PYTHON_MINOR=$(echo ${PYTHON_VER} | cut -d "." -f 2)
export PORTABLE_PYTHON_PY_VER=${PYTHON_VER}

if [[ "${PLATFORM}" == "freebsd"* ]]; then
  function verify_checksum () {
    file="$1"
    filename=$(basename $file)
    sum=$(cat ${SCRIPT_DIR}/../checksums/$file.sha256 | awk '{print $1}')
    sha256 -c $sum $file
  }
else
  function verify_checksum () {
    file="$1"
    filename=$(basename $file)
    echo "$(cat ${SCRIPT_DIR}/../checksums/$file.sha256)" | sha256sum -c
  }
fi

function download_and_verify () {
  file="$1"
  curl -s -S -f -L --retry 15 --retry-delay 0 --retry-all-errors -o $file https://github.com/bjia56/build-dependencies/releases/download/portable-python/$file
  verify_checksum $file
}

if [[ "${PLATFORM}" == "solaris"* ]]; then
  function download_verify_extract () {
    #set -x
    file="$1"
    download_and_verify $file
    gtar --no-same-permissions --no-same-owner -xf $file
    rm $file
    #set +x
  }
else
  function download_verify_extract () {
    #set -x
    file="$1"
    download_and_verify $file
    tar --no-same-permissions --no-same-owner -xf $file
    rm $file
    #set +x
  }
fi

function maybe_patch () {
  project=$(basename $(pwd))
  if [[ "$1" != "" ]]; then
    project=$1
  fi
  patch_dir="${SCRIPT_DIR}/../patches/${PLATFORM}/${ARCH}/${project}"
  if [ -d "$patch_dir" ]; then
    for patch_file in "$patch_dir"/*.patch; do
      [ -e "$patch_file" ] || continue  # Skip if no .patch files
      echo "Applying patch: $patch_file"
      patch -p1 < "$patch_file"
    done
  fi
}

WORKDIR=$(pwd)
BUILDDIR=${WORKDIR}/build
DEPSDIR=${WORKDIR}/deps
LICENSEDIR=${WORKDIR}/licenses

license_files=$(cat <<-END
LICENSE
LICENSE.txt
COPYING
END
)
function install_license () {
  #set -x
  project=$(basename $(pwd))
  file=$1
  if [[ "$2" != "" ]]; then
    project=$2
  fi
  if [[ "$file" != "" ]]; then
    if test -f $file; then
      cp $1 ${LICENSEDIR}/$project.txt
      #set +x
      return 0
    fi
  else
    while read license_file; do
      if test -f $license_file; then
        cp $license_file ${LICENSEDIR}/$project.txt
        #set +x
        return 0
      fi
    done <<< "$license_files"
  fi
  >&2 echo "could not find a license file"
  #set +x
  return 1
}

if [[ "${RUN_TESTS}" == "true" ]]; then
  INSTALL_TEST="ON"
else
  INSTALL_TEST="OFF"
fi

if [[ "${DEBUG_CI}" == "true" ]]; then
  BUILD_TYPE=Debug
  trap "cd ${BUILDDIR} && tar -czf ${WORKDIR}/build-python-${PYTHON_FULL_VER}-${PLATFORM}-${ARCH}.tar.gz ." EXIT
else
  BUILD_TYPE=Release
fi

cmake_verbose_flags=()
if [[ "${VERBOSE_CI}" == "true" ]]; then
  cmake_verbose_flags+=(--trace-expand --debug-find)
fi

mkdir ${BUILDDIR}
mkdir ${DEPSDIR}
mkdir ${LICENSEDIR}
