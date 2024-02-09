# portable-python
This project provides self-contained (hence, "portable") Python distributions to a variety of target platforms and architectures. These Python distributions can be downloaded and extracted to anywhere on the filesystem, making installation trivially easy and configurable.

## Usage

To get started, download archives from [GitHub releases](https://github.com/bjia56/portable-python/releases). Alternatively, use any of the following installers:
- `npm i @bjia56/portable-python-3.8`
- `npm i @bjia56/portable-python-3.9`
- `npm i @bjia56/portable-python-3.10`

For example, on Linux via bash:
```
$ wget -q https://github.com/bjia56/portable-python/releases/download/v3.9.17-build.4/python-3.9
.17-linux-x86_64.zip
$ unzip -qq python-3.9.17-linux-x86_64.zip
$ ./python-3.9.17-linux-x86_64/bin/python --version
Python 3.9.17
```

Or via the node installer:
```
$ npm i --silent @bjia56/portable-python-3.9
$ ./node_modules/@bjia56/portable-python-3.9/python-3.9.17-linux-x86_64/bin/python --version
Python 3.9.17
```

Or via node:
```js
var pythonExe = require("@bjia56/portable-python-3.9");
var child_process = require("child_process");
console.log(child_process.execSync(`${pythonExe} --version`).toString());
```

## Available distributions

Currently, Python 3.8, 3.9, and 3.10 are built for the following targets:
- Linux x86_64, i386, aarch64, arm <sup id="a1">[1](#f1)</sup>, riscv64
- Windows x86_64
- MacOS x86_64, arm64 <sup id="a2">[2](#f2)</sup>

<sub><b id="f1">1</b> The arm builds target armv6, specifically the configuration of the Raspberry Pi 1. Current arm builds do not work properly on old glibc, but a recent version of Raspbian like Debian bullseye should provide a new enough glibc to work. [↩](#a1)</sub>

<sub><b id="f2">2</b> MacOS distributions are provided as universal2, which will work on both x86_64 and arm64. [↩](#a2)</sub> 

## Licensing

The build scripts and code in this repository are available under the Apache-2.0 License. Note that compilation of Python involves linking against other libraries, some of which may include different licensing terms. Copies of the licenses from known dependencies are included under the `licenses` directory of each Python distribution.
