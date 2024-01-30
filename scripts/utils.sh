#!/bin/bash

set -e

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"

function verify_checksum () {
  file=$1
  filename=$(basename $file)
  sha256sum -c ${SCRIPT_DIR}/../checksums/$file.sha256
}

function download_and_verify () {
  file=$1
  curl -s -o $file https://github.com/bjia56/portable-python/releases/download/build-dependencies/$file
  verify_checksum $file
}

function download_verify_extract () {
  file=$1
  download_and_verify $1
  tar -xf $file
  rm $file
}

ARCH=$1
PYTHON_FULL_VER=$2
PYTHON_VER=$(echo ${PYTHON_FULL_VER} | cut -d "." -f 1-2)

WORKDIR=$(pwd)
BUILDDIR=${WORKDIR}/build
DEPSDIR=${WORKDIR}/deps

trap "cd ${BUILDDIR} && tar -czf ${WORKDIR}/build-python-${PYTHON_FULL_VER}-${PLATFORM}-${ARCH}.tar.gz ." EXIT
