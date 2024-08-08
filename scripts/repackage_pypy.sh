#!/bin/bash

set -e

ARCH=$1
PYPY_VERSION=$2
PLATFORM=$3

if [[ "${PLATFORM}" == "linux" ]]; then
  echo "::group::Install tools"
  apt update && apt -y install zip python3-pip curl
  echo "::endgroup::"
fi

if [[ "${PLATFORM}" == "darwin" ]]; then
  python3 -m venv venv
  source venv/bin/activate
fi

python3 -m pip install pyclean

WORKDIR=$(pwd)

function repackage_pypy () {
  DISTRIBUTION=$1
  echo "::group::PyPy ${DISTRIBUTION}"

  if [[ "${PLATFORM}" == "linux" ]]; then
    if [[ "${ARCH}" == "x86_64" ]]; then
      DL_LINK=https://downloads.python.org/pypy/pypy${DISTRIBUTION}-v${PYPY_VERSION}-linux64.tar.bz2
      DL_FILENAME=pypy${DISTRIBUTION}-v${PYPY_VERSION}-linux64
    else
      DL_LINK=https://downloads.python.org/pypy/pypy${DISTRIBUTION}-v${PYPY_VERSION}-aarch64.tar.bz2
      DL_FILENAME=pypy${DISTRIBUTION}-v${PYPY_VERSION}-aarch64
    fi
  elif [[ "${PLATFORM}" == "darwin" ]]; then
    if [[ "${ARCH}" == "x86_64" ]]; then
      DL_LINK=https://downloads.python.org/pypy/pypy${DISTRIBUTION}-v${PYPY_VERSION}-macos_x86_64.tar.bz2
      DL_FILENAME=pypy${DISTRIBUTION}-v${PYPY_VERSION}-macos_x86_64
    else
      DL_LINK=https://downloads.python.org/pypy/pypy${DISTRIBUTION}-v${PYPY_VERSION}-macos_arm64.tar.bz2
      DL_FILENAME=pypy${DISTRIBUTION}-v${PYPY_VERSION}-macos_arm64
    fi
  elif [[ "${PLATFORM}" == "windows" ]]; then
    DL_LINK=https://downloads.python.org/pypy/pypy${DISTRIBUTION}-v${PYPY_VERSION}-win64.zip
    DL_FILENAME=pypy${DISTRIBUTION}-v${PYPY_VERSION}-win64
  fi
  UPLOAD_FILENAME=pypy${DISTRIBUTION}-${PYPY_VERSION}-${PLATFORM}-${ARCH}

  if [[ "${PLATFORM}" == "windows" ]]; then
    curl -L ${DL_LINK} --output ${DL_FILENAME}.zip
    7z.exe x ${DL_FILENAME}.zip
    rm ${DL_FILENAME}.zip
  else
    curl -L ${DL_LINK} --output ${DL_FILENAME}.tar.bz2
    tar -xf ${DL_FILENAME}.tar.bz2
    rm ${DL_FILENAME}.tar.bz2
  fi

  cd ${DL_FILENAME}
  if [[ "${PLATFORM}" == "windows" ]]; then
    ./python -m ensurepip
  else
    ./bin/python -m ensurepip
  fi

  if [[ "${PLATFORM}" != "windows" ]]; then
    python3 ${WORKDIR}/scripts/patch_pip_script.py ./bin/pip3
    python3 ${WORKDIR}/scripts/patch_pip_script.py ./bin/pip${DISTRIBUTION}
  fi

  cd ${WORKDIR}
  mv ${DL_FILENAME} ${UPLOAD_FILENAME}

  python3 -m pyclean -v ${UPLOAD_FILENAME}
  tar -czf ${WORKDIR}/${UPLOAD_FILENAME}.tar.gz ${UPLOAD_FILENAME}
  if [[ "${PLATFORM}" == "windows" ]]; then
    7z.exe a ${WORKDIR}/${UPLOAD_FILENAME}.zip ${UPLOAD_FILENAME}
  else
    zip ${WORKDIR}/${UPLOAD_FILENAME}.zip $(tar tf ${WORKDIR}/${UPLOAD_FILENAME}.tar.gz)
  fi

  echo "::endgroup::"
}

repackage_pypy 3.10
repackage_pypy 3.9
