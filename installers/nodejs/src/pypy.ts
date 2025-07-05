import { platform, arch } from "os";
import { chmod, symlink, rename } from "fs/promises";
import { join } from "path";

import { IInstaller, IPortablePython } from './types';

const DL_PLATFORM = (() => {
    if (platform() == "win32") {
        return "windows";
    }
    return platform();
})();

const DL_ARCH = (() => {
    switch (arch()) {
    case "x64":
        return "x86_64";
    case "arm64":
        return "aarch64";
    }
    return arch();
})();

export default class PyPyInstaller implements IInstaller {
    constructor(private parent: IPortablePython) {}

    get pythonMajor(): string {
        if (this.parent.distribution === "auto") {
            return "3";
        }
        return this.parent.distribution.split(".")[0];
    }

    get pythonMinor(): string {
        if (this.parent.distribution === "auto") {
            const parentMajor = parseInt(this.parent.major);
            const parentMinor = parseInt(this.parent.minor);
            const parentPatch = parseInt(this.parent.patch);
            if (parentMajor > 7 ||
                (parentMajor == 7 && parentMinor > 3) ||
                (parentMajor == 7 && parentMinor == 3 && parentPatch >= 18)) {
                return "11";
            }
            return "10";
        }
        return this.parent.distribution.split(".")[1];
    }

    get relativeExecutablePath(): string {
        if (platform() === "win32") {
            return join(this.pythonDistributionName, "python.exe");
        }
        return join(this.pythonDistributionName, "bin", "python");
    }

    get relativePipPath(): string {
        if (platform() === "win32") {
            return join(this.pythonDistributionName, "Scripts", `pip${this.pythonMajor}.exe`);
        }
        return join(this.pythonDistributionName, "bin", `pip${this.pythonMajor}`);
    }

    get pythonDistributionName(): string {
        return `pypy${this.pythonMajor}.${this.pythonMinor}-${this.parent.version}-${DL_PLATFORM}-${DL_ARCH}`;
    }

    validateOptions(): void {
        if (this.parent.implementation !== "pypy") {
            throw Error("expected pypy implementation");
        }

        const parentMajor = parseInt(this.parent.major);
        const parentMinor = parseInt(this.parent.minor);
        const parentPatch = parseInt(this.parent.patch);

        if (parentMajor > 7 ||
            (parentMajor == 7 && parentMinor > 3) ||
            (parentMajor == 7 && parentMinor == 3 && parentPatch >= 20)) {
            if (!["auto", "3.11"].includes(this.parent.distribution)) {
                throw Error("invalid distribution");
            }
        } else if (parentMajor == 7 && parentMinor == 3 && [18, 19].includes(parentPatch)) {
            if (!["auto", "3.10", "3.11"].includes(this.parent.distribution)) {
                throw Error("invalid distribution");
            }
        } else if (parentMajor == 7 && parentMinor == 3 && parentPatch == 17) {
            if (!["auto", "3.10"].includes(this.parent.distribution)) {
                throw Error("invalid distribution");
            }
        } else {
            if (!["auto", "3.9", "3.10"].includes(this.parent.distribution)) {
                throw Error("invalid distribution");
            }
        }
    }

    async postInstall(): Promise<void> {
        if (!this.parent.isInstalled()) {
            throw Error("something went wrong and the installation failed");
        }

        await chmod(this.parent.executablePath, 0o777);
        if (platform() != "win32") {
            // node can't create symlinks over existing files, so we create symlinks with temp names,
            // then rename to overwrite existing files
            await symlink("python", `${this.parent.executablePath}${this.pythonMajor}_`, "file");
            await rename(`${this.parent.executablePath}${this.pythonMajor}_`, `${this.parent.executablePath}${this.pythonMajor}`);
            await symlink("python", `${this.parent.executablePath}${this.pythonMajor}.${this.pythonMinor}_`, "file");
            await rename(`${this.parent.executablePath}${this.pythonMajor}.${this.pythonMinor}_`, `${this.parent.executablePath}${this.pythonMajor}.${this.pythonMinor}`);

            // ensure the pip script is executable
            await chmod(this.parent.pipPath, 0o777);
            await chmod(`${this.parent.pipPath}.${this.pythonMinor}`, 0o777);
        }
    }
}
