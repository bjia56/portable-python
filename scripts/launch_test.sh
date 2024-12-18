#!/bin/bash

OS=$4
RUN_TESTS=$5

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
source ${SCRIPT_DIR}/utils.sh

function run_test () {
  python_suffix=$1
  python_distro_ver=${PYTHON_FULL_VER}${python_suffix}

  echo "::group::Python ${python_distro_ver}"

  if [[ "${DISTRIBUTION}" == "-" ]]; then
    FULL_DISTRO=python-${PYTHON_FULL_VER}${python_suffix}-${OS}-${ARCH}
  else
    FULL_DISTRO=python-${DISTRIBUTION}-${PYTHON_FULL_VER}${python_suffix}-${OS}-${ARCH}
  fi
  PYTHON_EXE=python

  case "$OS" in
    linux)
      uname -a
      apt update
      apt -y install unzip
      unzip ${FULL_DISTRO}.zip
      cd ${FULL_DISTRO}
      chmod +x ./bin/python
      ;;
    windows)
      7z.exe x ${FULL_DISTRO}.zip
      ;;
    darwin)
      unzip ${FULL_DISTRO}.zip
      cd ${FULL_DISTRO}
      chmod +x ./bin/python
      ;;
    freebsd*)
      unzip ${FULL_DISTRO}.zip
      cd ${FULL_DISTRO}
      chmod +x ./bin/python
      ;;
    solaris*)
      unzip ${FULL_DISTRO}.zip
      cd ${FULL_DISTRO}
      chmod +x ./bin/python
      ;;
    cosmo)
      if [[ "${HOST_OS}" == "Windows" ]]; then
        7z.exe x ${FULL_DISTRO}.zip
      else
        unzip ${FULL_DISTRO}.zip
        cd ${FULL_DISTRO}
        chmod +x ./bin/python.com
      fi
      PYTHON_EXE=python.com
      ;;
  esac

  cd ${WORKDIR}/${FULL_DISTRO}
  ./bin/${PYTHON_EXE} --version
  ./bin/${PYTHON_EXE} -m sysconfig
  ./bin/${PYTHON_EXE} ${WORKDIR}/scripts/test.py
  ./bin/${PYTHON_EXE} -m pip

  if [[ "${RUN_TESTS}" == "true" ]]; then
    ./bin/${PYTHON_EXE} -m test -v -ulargefile,network,decimal,cpu,subprocess,urlfetch,tzdata --timeout 60
  fi

  echo "::endgroup::"
}

run_test
if [[ "${PYTHON_MINOR}" == "13" ]]; then
  run_test t
fi
