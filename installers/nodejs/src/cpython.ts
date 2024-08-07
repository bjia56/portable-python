import { platform, arch, release } from "os";
import { chmod, symlink, rename } from "fs/promises";
import { join } from "path";

import { IInstaller, IPortablePython, IPortablePythonOptions } from './types';

const DL_PLATFORM = (() => {
    if (platform() == "win32") {
        return "windows";
    }
    if (platform() == "freebsd") {
        const releaseName = release();
        const releaseMajor = parseInt(releaseName.split(".")[0]);
        return `freebsd${releaseMajor}`;
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
    }

    return arch();
})();

export default class CPythonInstaller implements IInstaller {
    constructor(private parent: IPortablePython, private options: IPortablePythonOptions) {}

    get relativeExecutablePath(): string {
        return join(this.pythonDistributionName, "bin", "python" + (
            this.options.distribution === "cosmo" ? ".com" :
            (platform() === "win32" ? ".exe" : "")
        ));
    }

    get relativePipPath(): string {
        if (this.options.distribution != "cosmo" && platform() === "win32") {
            return join(this.pythonDistributionName, "Scripts", `pip${this.parent.major}.exe`);
        }
        return join(this.pythonDistributionName, "bin", `pip${this.parent.major}`);
    }

    get pythonDistributionName(): string {
        if (this.parent.distribution === "cosmo") {
            return `python-${this.parent.version}-cosmo-unknown`;
        }
        const distribution = this.parent.distribution === "auto" ? "headless" : this.parent.distribution;
        return `python-${distribution}-${this.parent.version}-${DL_PLATFORM}-${DL_ARCH}`;
    }

    validateOptions(): void {
        if (this.options.implementation !== "cpython") {
            throw Error("expected cpython implementation");
        }

        if (!["auto", "cosmo", "headless", "full"].includes(this.options.distribution)) {
            throw Error("invalid distribution");
        }
    }

    async postInstall(): Promise<void> {
        if (!this.parent.isInstalled()) {
            throw Error("something went wrong and the installation failed");
        }

        await chmod(this.parent.executablePath, 0o777);
        if (this.options.distribution != "cosmo" && platform() != "win32") {
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
    }
}