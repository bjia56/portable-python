#!/bin/bash

export ARCH=$1
export GRAALPY_VERSION=$2
export PLATFORM=$3

export DL_ARCH=${ARCH}
if [[ "${ARCH}" == "x86_64" ]]; then
  export DL_ARCH=amd64
fi

if [[ "${PLATFORM}" == "linux" ]]; then
  echo "::group::Install tools"
  apt update && apt -y install zip python3-pip curl parallel
  echo "::endgroup::"
fi

export DL_PLATFORM="${PLATFORM}"
if [[ "${PLATFORM}" == "darwin" ]]; then
  export DL_PLATFORM=macos
fi

python3 -m pip install pyclean
export WORKDIR=$(pwd)

function repackage_graal () {
  DISTRIBUTION=$1
  echo "::group::GraalPy ${DISTRIBUTION}"

  cd ${WORKDIR}
  mkdir -p workdir-graalpy${DISTRIBUTION}
  cd workdir-graalpy${DISTRIBUTION}

  DISTRO_MODIFIER="-"
  if [[ "${DISTRIBUTION}" == *"community"* ]]; then
    DISTRO_MODIFIER="${DISTRO_MODIFIER}community-"
  fi

  if [[ "${DISTRIBUTION}" == *"jvm"* ]]; then
    DISTRO_MODIFIER="${DISTRO_MODIFIER}jvm-"
  fi

  DL_FILENAME=graalpy${DISTRO_MODIFIER}${GRAALPY_VERSION}-${DL_PLATFORM}-${DL_ARCH}
  if [[ "${DISTRIBUTION}" == *"community"* ]]; then
    EXTRACTED_FILENAME=graalpy-community-${GRAALPY_VERSION}-${DL_PLATFORM}-${DL_ARCH}
  else
    EXTRACTED_FILENAME=graalpy-${GRAALPY_VERSION}-${DL_PLATFORM}-${DL_ARCH}
  fi
  UPLOAD_FILENAME=graalpy${DISTRO_MODIFIER}${GRAALPY_VERSION}-${PLATFORM}-${ARCH}

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
  if [[ "${DISTRIBUTION}" == *"jvm"* ]]; then
    if [[ "${DISTRIBUTION}" == *"community"* ]]; then
      if [[ "${PLATFORM}" == "linux" ]]; then
        docker run it -v .:/ws --workdir /ws --user $(id -u):$(id -g) ${DOCKER_IMAGE} ./libexec/graalpy-polyglot-get js-community
      else
        ./libexec/graalpy-polyglot-get js-community
      fi
    else
      if [[ "${PLATFORM}" == "linux" ]]; then
        docker run it -v .:/ws --workdir /ws --user $(id -u):$(id -g) ${DOCKER_IMAGE} ./libexec/graalpy-polyglot-get js
      else
        ./libexec/graalpy-polyglot-get js
      fi
    fi
  fi
  if [[ "${PLATFORM}" == "linux" ]]; then
    docker run it -v .:/ws --workdir /ws --user $(id -u):$(id -g) ${DOCKER_IMAGE} ./bin/python -m ensurepip
  else
    ./bin/python -m ensurepip
  fi

  cd ${WORKDIR}/workdir-graalpy${DISTRIBUTION}
  mv ${EXTRACTED_FILENAME} ${UPLOAD_FILENAME}

  python3 -m pyclean -v ${UPLOAD_FILENAME}
  tar -czf ${WORKDIR}/${UPLOAD_FILENAME}.tar.gz ${UPLOAD_FILENAME}
  if [[ "${PLATFORM}" == "windows" ]]; then
    7z.exe a ${WORKDIR}/${UPLOAD_FILENAME}.zip ${UPLOAD_FILENAME}
  else
    zip ${WORKDIR}/${UPLOAD_FILENAME}.zip $(tar tf ${WORKDIR}/${UPLOAD_FILENAME}.tar.gz)
  fi

  echo "::endgroup::"
}

function plain () {
  repackage_graal
}

function jvm () {
  repackage_graal jvm
}

function community () {
  repackage_graal community
}

function community_jvm () {
  repackage_graal community-jvm
}

export -f repackage_graal plain jvm community community_jvm

if [[ "${PLATFORM}" == "linux" ]]; then
  parallel ::: plain jvm community community_jvm
else
  plain
  jvm
  community
  community_jvm
fi