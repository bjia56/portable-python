#!/bin/bash

ARCH=$1
GRAALPY_VERSION=$2
PLATFORM=$3

DL_ARCH=${ARCH}
if [[ "${ARCH}" == "x86_64" ]]; then
  DL_ARCH=amd64
fi

if [[ "${PLATFORM}" == "linux" ]]; then
  apt update && apt -y install zip python3-pip curl
fi

WORKDIR=$(pwd)

DL_FILENAME=graalpy-community-jvm-${GRAALPY_VERSION}-${PLATFORM}-${DL_ARCH}
EXTRACTED_FILENAME=graalpy-community-${GRAALPY_VERSION}-${PLATFORM}-${DL_ARCH}
UPLOAD_FILENAME=graalpy-community-jvm-${GRAALPY_VERSION}-${PLATFORM}-${ARCH}

if [[ "${PLATFORM}" == "windows" ]]; then
  curl -L https://github.com/oracle/graalpython/releases/download/graal-${GRAALPY_VERSION}/${DL_FILENAME}.zip --output ${DL_FILENAME}.zip
  7z.exe x ${DL_FILENAME}.zip
  rm ${DL_FILENAME}.zip
else
  curl -L https://github.com/oracle/graalpython/releases/download/graal-${GRAALPY_VERSION}/${DL_FILENAME}.tar.gz --output ${DL_FILENAME}.tar.gz
  tar -xf ${DL_FILENAME}.tar.gz
  rm ${DL_FILENAME}.tar.gz
fi

cd ${EXTRACTED_FILENAME}
./libexec/graalpy-polyglot-get js-community
./bin/python -m ensurepip

cd ${WORKDIR}
mv ${EXTRACTED_FILENAME} ${UPLOAD_FILENAME}

python3 -m pip install pyclean
python3 -m pyclean -v ${UPLOAD_FILENAME}
tar -czf ${WORKDIR}/${UPLOAD_FILENAME}.tar.gz ${UPLOAD_FILENAME}
if [[ "${PLATFORM}" == "windows" ]]; then
  7z.exe a ${WORKDIR}/${UPLOAD_FILENAME}.zip ${UPLOAD_FILENAME}
else
  zip ${WORKDIR}/${UPLOAD_FILENAME}.zip $(tar tf ${WORKDIR}/${UPLOAD_FILENAME}.tar.gz)
fi
