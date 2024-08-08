import { platform, arch } from "os";
import { chmod, symlink, rename } from "fs/promises";
import { join } from "path";

import { IInstaller, IPortablePython, IPortablePythonOptions } from './types';

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

export default class GraalPyInstaller implements IInstaller {
    private pythonMajor: number = 3;
    private pythonMinor: number = 10;

    constructor(private parent: IPortablePython) {}

    get relativeExecutablePath(): string {
        return join(this.pythonDistributionName, "bin", "python" + (platform() === "win32" ? ".exe" : ""));
    }

    get relativePipPath(): string {
        if (platform() === "win32") {
            return join(this.pythonDistributionName, "Scripts", `pip${this.pythonMajor}.exe`);
        }
        return join(this.pythonDistributionName, "bin", `pip${this.pythonMajor}`);
    }

    get pythonDistributionName(): string {
        if (this.parent.distribution === "auto" || this.parent.distribution === "standard") {
            return `graalpy-${this.parent.version}-${DL_PLATFORM}-${DL_ARCH}`;
        }
        return `graalpy-${this.parent.distribution}-${this.parent.version}-${DL_PLATFORM}-${DL_ARCH}`;
    }

    validateOptions(): void {
        if (this.parent.implementation !== "graalpy") {
            throw Error("expected graalpy implementation");
        }

        if (!["auto", "standard", "community", "jvm", "community-jvm"].includes(this.parent.distribution)) {
            throw Error("invalid distribution");
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