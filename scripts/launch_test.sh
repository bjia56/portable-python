#!/bin/bash

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"

# Download and setup gnu-getopt-multiplatform
function setup_getopt() {
    local getopt_dir="${SCRIPT_DIR}/../.getopt"
    local getopt_binary="${getopt_dir}/getopt"

    # Check if getopt is already downloaded
    if [ -f "$getopt_binary" ]; then
        return 0
    fi

    # Create directory for getopt
    mkdir -p "$getopt_dir"

    # Download getopt binary
    echo "Downloading gnu-getopt-multiplatform..."
    curl -s -S -f -L --retry 15 --retry-delay 0 \
        -o "$getopt_binary" \
        "https://github.com/bjia56/gnu-getopt-multiplatform/releases/download/v2.41.2.1/getopt"

    # Make it executable
    chmod +x "$getopt_binary"

    echo "Downloaded getopt to $getopt_binary"
}

# Setup getopt before using it
setup_getopt
GETOPT_BINARY="${SCRIPT_DIR}/../.getopt/getopt"

# Parse command line arguments for launch_test.sh
function parse_test_arguments() {
    OS=""
    RUN_TESTS=""

    # Use getopt for argument parsing
    PARSED_ARGS=$("$GETOPT_BINARY" -o a:v:d:o:r:h --long arch:,version:,distribution:,os:,run-tests:,help -n "$0" -- "$@")
    if [ $? != 0 ]; then
        echo "Failed to parse arguments" >&2
        exit 1
    fi

    eval set -- "$PARSED_ARGS"

    while true; do
        case "$1" in
            -a|--arch)
                ARCH="$2"
                shift 2
                ;;
            -v|--version)
                PYTHON_FULL_VER="$2"
                shift 2
                ;;
            -d|--distribution)
                DISTRIBUTION="$2"
                shift 2
                ;;
            -o|--os)
                OS="$2"
                shift 2
                ;;
            -r|--run-tests)
                RUN_TESTS="$2"
                shift 2
                ;;
            -h|--help)
                echo "Usage: $0 -a|--arch ARCH -v|--version VERSION -d|--distribution DIST -o|--os OS -r|--run-tests BOOL"
                echo ""
                echo "Options:"
                echo "  -a, --arch ARCH              Target architecture (e.g., x86_64, aarch64, universal2, unknown)"
                echo "  -v, --version VERSION        Python version (e.g., 3.11.10)"
                echo "  -d, --distribution DIST      Distribution type: full, headless, or - for cosmo builds"
                echo "  -o, --os OS                  Target OS (linux, windows, darwin, freebsd*, solaris*, cosmo)"
                echo "  -r, --run-tests BOOL         Whether to run tests (true/false)"
                echo "  -h, --help                   Show this help message"
                exit 0
                ;;
            --)
                shift
                break
                ;;
            *)
                echo "Internal error parsing arguments" >&2
                exit 1
                ;;
        esac
    done

    # Validate required arguments
    if [ -z "$ARCH" ]; then
        echo "Error: Architecture (-a|--arch) is required" >&2
        exit 1
    fi

    if [ -z "$PYTHON_FULL_VER" ]; then
        echo "Error: Python version (-v|--version) is required" >&2
        exit 1
    fi

    if [ -z "$DISTRIBUTION" ]; then
        echo "Error: Distribution (-d|--distribution) is required" >&2
        exit 1
    fi

    if [ -z "$OS" ]; then
        echo "Error: OS (-o|--os) is required" >&2
        exit 1
    fi

    if [ -z "$RUN_TESTS" ]; then
        echo "Error: Run tests flag (-r|--run-tests) is required" >&2
        exit 1
    fi
}

# Parse the arguments
parse_test_arguments "$@"

# Set up derived variables like utils.sh does
PYTHON_VER=$(echo ${PYTHON_FULL_VER} | cut -d "." -f 1-2)
PYTHON_MAJOR=$(echo ${PYTHON_VER} | cut -d "." -f 1)
PYTHON_MINOR=$(echo ${PYTHON_VER} | cut -d "." -f 2)
export PORTABLE_PYTHON_PY_VER=${PYTHON_VER}

WORKDIR=$(pwd)

function run_test () {
  python_suffix=$1
  python_distro_ver=${PYTHON_FULL_VER}${python_suffix}

  echo "::group::Python ${python_distro_ver}"

  cd ${WORKDIR}

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
