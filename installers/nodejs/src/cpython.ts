import { platform, arch, release, version } from "os";
import { accessSync } from "fs";
import { chmod, symlink, rename } from "fs/promises";
import { join } from "path";
import { execSync } from "child_process";

import { IInstaller, IPortablePython } from './types';
import { isNixOS } from './util';

const DL_PLATFORM = (() => {
    if (platform() == "win32") {
        return "windows";
    }
    if (platform() == "freebsd") {
        const releaseName = release();
        const releaseMajor = parseInt(releaseName.split(".")[0]);
        return `freebsd${releaseMajor}`;
    }
    if (platform() == "sunos") {
        const versionString = version();
        const versionMajor = parseInt(versionString.split(".")[0]);
        return `solaris${versionMajor}`;
    }
    return platform();
})();

const DL_ARCH = (() => {
    if (DL_PLATFORM == "darwin") {
        return "universal2";
    }

    switch (arch()) {
    case "ia32":
        return "i386";
    case "x64":
        return "x86_64";
    case "arm64":
        return "aarch64";
    case "loong64":
        return "loongarch64";
    case "ppc64":
        return "powerpc64le";
    }

    return arch();
})();

const COSMO_EXES = [
    "python.com",
    "python.x86_64.elf",
    "python.x86_64.macho",
    "python.aarch64.elf"
]

export default class CPythonInstaller implements IInstaller {
    constructor(private parent: IPortablePython) {}

    get relativeExecutablePath(): string {
        if (this.parent.distribution === "cosmo") {
            let exe = "python.com";
            if (platform() == "darwin") {
                if (arch() == "x64") {
                    exe = "python.x86_64.macho";
                }
            } else if (platform() != "win32") {
                if (arch() == "x64") {
                    exe = "python.x86_64.elf";
                } else if (arch() == "arm64") {
                    exe = "python.aarch64.elf";
                }
            }

            try {
                accessSync(join(this.parent.extractPath, "bin", exe));
            } catch {
                exe = "python.com";
            }

            return join(this.pythonDistributionName, "bin", exe);
        }

        return join(this.pythonDistributionName, "bin", "python" + (
            platform() === "win32" ? ".exe" : ""
        ));
    }

    get relativePipPath(): string {
        if (this.parent.distribution != "cosmo" && platform() === "win32") {
            return join(this.pythonDistributionName, "Scripts", `pip${this.parent.major}.exe`);
        }
        return join(this.pythonDistributionName, "bin", `pip${this.parent.major}`);
    }

    get pythonDistributionName(): string {
        if (this.parent.distribution === "cosmo") {
            return `python-${this.parent.version}${this.parent.abiflags}-cosmo-unknown`;
        }
        const distribution = this.parent.distribution === "auto" ? "headless" : this.parent.distribution;
        return `python-${distribution}-${this.parent.version}${this.parent.abiflags}-${DL_PLATFORM}-${DL_ARCH}`;
    }

    validateOptions(): void {
        if (this.parent.implementation !== "cpython") {
            throw Error("expected cpython implementation");
        }

        if (!["auto", "cosmo", "headless", "full"].includes(this.parent.distribution)) {
            throw Error("invalid distribution");
        }

        if (this.parent.abiflags && this.parent.abiflags != "t") {
            throw Error("invalid abiflags");
        }

        if (this.parent.abiflags == "t" && this.parent.minor != "13") {
            throw Error("abiflags 't' is only supported for Python 3.13");
        }
    }

    async postInstall(): Promise<void> {
        if (!this.parent.isInstalled()) {
            throw Error("something went wrong and the installation failed");
        }

        await chmod(this.parent.executablePath, 0o777);
        if (this.parent.distribution != "cosmo" && platform() != "win32") {
            // node can't create symlinks over existing files, so we create symlinks with temp names,
            // then rename to overwrite existing files
            await symlink("python", `${this.parent.executablePath}${this.parent.major}_`, "file");
            await rename(`${this.parent.executablePath}${this.parent.major}_`, `${this.parent.executablePath}${this.parent.major}`);
            await symlink("python", `${this.parent.executablePath}${this.parent.major}.${this.parent.minor}_`, "file");
            await rename(`${this.parent.executablePath}${this.parent.major}.${this.parent.minor}_`, `${this.parent.executablePath}${this.parent.major}.${this.parent.minor}`);

            // ensure the pip script is executable
            await chmod(this.parent.pipPath, 0o777);
            await chmod(`${this.parent.pipPath}.${this.parent.minor}`, 0o777);
        }

        if (this.parent.distribution === "cosmo" && platform() != "win32") {
            for (const exe of COSMO_EXES) {
                try {
                    await chmod(join(this.parent.extractPath, "bin", exe), 0o777);
                } catch(e) {
                    // ignore
                }
            }

            // ensure the pip script is executable
            await chmod(this.parent.pipPath, 0o777);
            await chmod(`${this.parent.pipPath}.${this.parent.minor}`, 0o777);
        }

        if (this.parent.distribution !== "cosmo" && isNixOS()) {
            // Get glibc path
            const glibcOut = execSync('nix --extra-experimental-features "nix-command flakes" path-info nixpkgs#glibc.out');
            const glibcPath = glibcOut.toString().trim();
            const glibcInterpreter = (() => {
                switch (arch()) {
                case "x64":
                    return "ld-linux-x86-64.so.2";
                case "arm64":
                    return "ld-linux-aarch64.so.1";
                };
                throw new Error("Unsupported architecture");
            })();
            const glibcInterpreterPath = join(glibcPath, "lib", glibcInterpreter);

            // Run patchelf to set the interpreter
            execSync(`nix-shell -p patchelf --run 'patchelf --set-interpreter ${glibcInterpreterPath} ${this.parent.executablePath}'`);
        }
    }
}