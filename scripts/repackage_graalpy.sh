#!/bin/bash

ARCH=$1
GRAALPY_VERSION=$2
PLATFORM=$3

DL_ARCH=${ARCH}
if [[ "${ARCH}" == "x86_64" ]]; then
  DL_ARCH=amd64
fi

WORKDIR=$(pwd)

if [[ "${PLATFORM}" == "windows" ]]; then
  curl -L https://github.com/oracle/graalpython/releases/download/graal-${GRAALPY_VERSION}/graalpy-community-${GRAALPY_VERSION}-${PLATFORM}-${DL_ARCH}.zip --output graalpy-community-${GRAALPY_VERSION}-${PLATFORM}-${DL_ARCH}.zip
  7z.exe x graalpy-community-${GRAALPY_VERSION}-${PLATFORM}-${DL_ARCH}.zip
else
  curl -L https://github.com/oracle/graalpython/releases/download/graal-${GRAALPY_VERSION}/graalpy-community-${GRAALPY_VERSION}-${PLATFORM}-${DL_ARCH}.tar.gz --output graalpy-community-${GRAALPY_VERSION}-${PLATFORM}-${DL_ARCH}.tar.gz
  tar -xf graalpy-community-${GRAALPY_VERSION}-${PLATFORM}-${DL_ARCH}.tar.gz
fi

cd graalpy-community-${GRAALPY_VERSION}-${PLATFORM}-${DL_ARCH}
./bin/python -m ensurepip

tar -czf ${WORKDIR}/graalpy-community-${GRAALPY_VERSION}-${PLATFORM}-${ARCH}.tar.gz graalpy-community-${GRAALPY_VERSION}-${PLATFORM}-${ARCH}
if [[ "${PLATFORM}" == "windows" ]]; then
  7z.exe a ${WORKDIR}/graalpy-community-${GRAALPY_VERSION}-${PLATFORM}-${ARCH}.zip graalpy-community-${GRAALPY_VERSION}-${PLATFORM}-${ARCH}
else
  zip ${WORKDIR}/graalpy-community-${GRAALPY_VERSION}-${PLATFORM}-${ARCH}.zip $(tar tf ${WORKDIR}/graalpy-community-${GRAALPY_VERSION}-${PLATFORM}-${ARCH}.tar.gz)
fi
