#!/bin/bash

set -e

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"

function verify_checksum () {
  file="$1"
  filename=$(basename $file)
  sha256sum -c ${SCRIPT_DIR}/../checksums/$file.sha256
}

function download_and_verify () {
  file="$1"
  curl -s -S -f -L -o $file https://github.com/bjia56/portable-python/releases/download/build-dependencies/$file
  verify_checksum $file
}

function download_verify_extract () {
  file="$1"
  download_and_verify $file
  tar -xf $file
  rm $file
}

ARCH=$1
PYTHON_FULL_VER=$2
PYTHON_VER=$(echo ${PYTHON_FULL_VER} | cut -d "." -f 1-2)

WORKDIR=$(pwd)
BUILDDIR=${WORKDIR}/build
DEPSDIR=${WORKDIR}/deps
LICENSEDIR=${WORKDIR}/licenses

license_files=$(cat <<-END
LICENSE
COPYING
END
)
function install_license () {
  project=$(basename $(pwd))
  if [[ "$1" != "" ]]; then
    if test -f $1; do
      cp $1 ${DEPSDIR}/$project
      return 0
    fi
  else
    while read license_file; do
      if test -f $license_file; then
        cp $license_file ${DEPSDIR}/$project
        return 0
      fi
    done <<< "$license_files"
  fi
  >&2 echo "could not find a license file"
  return 1
}

if [[ "${RUN_TESTS}" == "true" ]]; then
  INSTALL_TEST="ON"
else
  INSTALL_TEST="OFF"
fi

if [[ "${DEBUG_CI}" == "true" ]]; then
  trap "cd ${BUILDDIR} && tar -czf ${WORKDIR}/build-python-${PYTHON_FULL_VER}-${PLATFORM}-${ARCH}.tar.gz ." EXIT
fi
