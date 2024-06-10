#!/bin/bash

ARCH=$1
GRAALPY_VERSION=$2
PLATFORM=$3

WORKDIR=$(pwd)

curl -L https://github.com/oracle/graalpython/releases/download/graal-${GRAALPY_VERSION}/graalpy-community-${GRAALPY_VERSION}-${PLATFORM}-${ARCH}.tar.gz --output graalpy-community-${GRAALPY_VERSION}-${PLATFORM}-${ARCH}.tar.gz
tar -xf graalpy-community-${GRAALPY_VERSION}-${PLATFORM}-${ARCH}.tar.gz
cd graalpy-community-${GRAALPY_VERSION}-${PLATFORM}-${ARCH}
./bin/python -m ensurepip

tar -czf ${WORKDIR}/graalpy-community-${GRAALPY_VERSION}-${PLATFORM}-${ARCH}.tar.gz graalpy-community-${GRAALPY_VERSION}-${PLATFORM}-${ARCH}
if [[ "${PLATFORM}" == "windows" ]]; then
  7z.exe a ${WORKDIR}/graalpy-community-${GRAALPY_VERSION}-${PLATFORM}-${ARCH}.zip graalpy-community-${GRAALPY_VERSION}-${PLATFORM}-${ARCH}
else
  tar -czf ${WORKDIR}/graalpy-community-${GRAALPY_VERSION}-${PLATFORM}-${ARCH}.tar.gz graalpy-community-${GRAALPY_VERSION}-${PLATFORM}-${ARCH}
  zip ${WORKDIR}/graalpy-community-${GRAALPY_VERSION}-${PLATFORM}-${ARCH}.zip $(tar tf ${WORKDIR}/graalpy-community-${GRAALPY_VERSION}-${PLATFORM}-${ARCH}.tar.gz)
fi
