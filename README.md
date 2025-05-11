# portable-python
[![GitHub Downloads (all assets, all releases)](https://bjia56.github.io/stats/bjia56/portable-python/downloads_badge.svg)](https://bjia56.github.io/portable-python/)
[![NPM Version](https://img.shields.io/npm/v/%40bjia56%2Fportable-python)](https://www.npmjs.com/package/@bjia56/portable-python)


This project provides self-contained (hence, "portable") Python distributions to a variety of target platforms and architectures. These Python distributions can be downloaded and extracted to anywhere on the filesystem, making installation trivially easy and configurable.

## Usage

To get started, download archives from [GitHub releases](https://github.com/bjia56/portable-python/releases). Alternatively, use any of the following installers:
- `npm i @bjia56/portable-python-3.9`
- `npm i @bjia56/portable-python-3.10`
- `npm i @bjia56/portable-python-3.11`
- `npm i @bjia56/portable-python-3.12`
- `npm i @bjia56/portable-python-3.13`

For example, on Linux via bash:
```
$ wget -q https://github.com/bjia56/portable-python/releases/download/cpython-v3.12.6-build.5/python-headless-3.12.6-linux-x86_64.zip
$ unzip -qq python-headless-3.12.6-linux-x86_64.zip
$ ./python-headless-3.12.6-linux-x86_64/bin/python --version
Python 3.12.6
```

Or via the node installer:
```
$ npm i --silent @bjia56/portable-python-3.12
$ ./node_modules/@bjia56/portable-python-3.12/python-headless-3.12.6-linux-x86_64/bin/python --version
Python 3.12.6
```

Or via node:
```js
var pythonExe = require("@bjia56/portable-python-3.12");
var child_process = require("child_process");
console.log(child_process.execSync(`${pythonExe} --version`).toString());
```

## Available distributions

Currently, CPython 3.9, 3.10, 3.11, 3.12, and 3.13 are built for the following targets:
- Linux x86_64, i386, aarch64, arm <sup id="a1">[1](#f1)</sup>, riscv64, s390x, loongarch64, powerpc64le (glibc)
- Windows x86_64 <sup id="a2">[2](#f2)</sup>
- MacOS x86_64, arm64 <sup id="a3">[3](#f3)</sup>
- FreeBSD 13, 14, 15 x86_64
- Solaris 11 x86_64
- Cosmopolitan Libc <sup id="a4">[4](#f4)</sup>

For Linux CPython builds, the minimum glibc required is as follows:

| Hardware Architecture | Minimum glibc Version |
|-|-|
| x86_64      | 2.17 |
| i386        | 2.17 |
| aarch64     | 2.17 |
| arm         | 2.17 |
| riscv64     | 2.27 |
| s390x       | 2.19 |
| loongarch64 | 2.36 |
| powerpc64le | 2.19 |


For all CPython distributions except for the Cosmopolitan libc build, there are two available variants: `full` and `headless`. The distinction is that `headless` builds do not include any UI libraries (i.e. `tkinter` and its dependencies), so are better suited for non-graphical server installations.

PyPy and GraalPy distributions are also available as repackaged versions of official upstream releases. Though they are already portable, the distributions have been made available through the node installers for convenience and flexibility.

<sub><b id="f1">1</b> The arm builds target armv6, specifically the configuration of the Raspberry Pi 1. Current arm builds do not work properly on old glibc (despite the glibc 2.17 target), but a recent version of Raspbian like Debian bullseye should provide a new enough glibc to work. [↩](#a1)</sub>

<sub><b id="f2">2</b> Windows distributions require a minimum of Windows 10. [↩](#a2)</sub>

<sub><b id="f3">3</b> MacOS distributions are provided as universal2, which will work on both x86_64 and arm64. The minimum MacOS version is 10.9 on x86_64 and 11.0 on arm64. [↩](#a3)</sub>

<sub><b id="f4">4</b> [Cosmopolitan Libc](https://justine.lol/cosmopolitan/index.html) builds are statically linked and may not support all Python features. See the Cosmopolitan Libc project's documentation for minimum operating system requirements. [↩](#a4)</sub>

## Licensing

The build scripts and code in this repository are available under the Apache-2.0 License. Note that compilation of Python involves linking against other libraries, some of which may include different licensing terms. Copies of the licenses from known dependencies are included under the `licenses` directory of each Python distribution.
