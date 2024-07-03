import { createWriteStream, existsSync, rm, rmSync, mkdirSync, chmodSync, symlinkSync, renameSync } from "fs";
import { join, dirname } from "path";
import { platform, arch, release } from "os";
import { Readable } from 'stream';
import { finished } from 'stream/promises';
import { ReadableStream } from 'stream/web';
import AdmZip from "adm-zip";

const packageJson = require("../package.json");

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

const VERSIONS = packageJson.portablePython.versions;
const VERSION_BUILDS = packageJson.portablePython.versionBuilds;

function pickVersion(version: string) {
    for (let i = 0; i < VERSIONS.length; ++i) {
        // TODO: This doesn't handle semver correctly, e.g. 3.8.17 will match 3.8.1
        if (VERSIONS[i].startsWith(version)) {
            return VERSIONS[i];
        }
    }
    return null;
}

async function download(url: string, dest: string) {
    const res = await fetch(url);
    const file = createWriteStream(dest);
    await finished(Readable.fromWeb(res.body as ReadableStream).pipe(file));
}

export class PortablePython {
    _version: string
    distribution: string = "standard"
    installDir = dirname(__dirname);

    constructor(version: string, installDir: string | null = null, options: any = {}) {
        if (!version) {
            throw Error("version must not be empty");
        }

        if (options.distribution) {
            this.distribution = options.distribution;
        }
        if (!["standard", "cosmo"].includes(this.distribution)) {
            throw Error("invalid distribution");
        }

        if (installDir) {
            this.installDir = installDir;
        }

        this._version = pickVersion(version);
        if (!this._version) {
            throw Error(`unknown version: ${version}`);
        }
        if (!this.releaseTag) {
            throw Error("no releases available for this version");
        }
    }

    /**
     * Contains the path to the Python executable.
     */
    get executablePath() {
        return join(this.installDir, this.pythonDistributionName, "bin", "python" + (
            this.distribution === "cosmo" ? ".com" :
            (platform() === "win32" ? ".exe" : "")
        ));
    }

    /**
     * Contains the path to the bundled pip executable.
     */
    get pipPath() {
        if (this.distribution != "cosmo" && platform() === "win32") {
            return join(this.installDir, this.pythonDistributionName, "Scripts", `pip${this.major}.exe`);
        }
        return join(this.installDir, this.pythonDistributionName, "bin", `pip${this.major}`);
    }

    /**
     * Contains the selected Python version.
     */
    get version() {
        return this._version;
    }

    /**
     * Contains the major version number.
     */
    get major() {
        return this.version.split(".")[0];
    }

    /**
     * Contains the minor version number.
     */
    get minor() {
        return this.version.split(".")[1];
    }

    /**
     * Contains the patch version number.
     */
    get patch() {
        return this.version.split(".")[2];
    }

    /**
     * Contains the release tag that will be downloaded.
     */
    get releaseTag() {
        return VERSION_BUILDS[this.version] as string;
    }

    /**
     * Contains the full name of the Python distribution.
     */
    get pythonDistributionName() {
        if (this.distribution === "cosmo") {
            return `python-${this.version}-cosmo-unknown`;
        }
        return `python-${this.version}-${DL_PLATFORM}-${DL_ARCH}`;
    }

    /**
     * Contains the path to the extracted Python distribution folder.
     */
    get extractPath() {
        return join(this.installDir, this.pythonDistributionName);
    }

    /**
     * Checks if the selected Python version has been installed on the host platform.
     * @returns True if the installation exists, false otherwise.
     */
    isInstalled() {
        return existsSync(this.extractPath);
    }

    /**
     * Will download the compressed Python installation and extract it to
     * the installation directory.
     * @param [zipFile=null] - Install from an existing zip file on the filesystem, instead of downloading.
     */
    async install(zipFile: string | null = null) {
        if (this.isInstalled()) {
            return;
        }

        const postProcess = () => {
            if (!this.isInstalled()) {
                throw Error("something went wrong and the installation failed");
            }

            chmodSync(this.executablePath, 0o777);
            if (this.distribution != "cosmo" && platform() != "win32") {
                // node can't create symlinks over existing files, so we create symlinks with temp names,
                // then rename to overwrite existing files
                symlinkSync("python", `${this.executablePath}${this.major}_`, "file");
                renameSync(`${this.executablePath}${this.major}_`, `${this.executablePath}${this.major}`);
                symlinkSync("python", `${this.executablePath}${this.major}.${this.minor}_`, "file");
                renameSync(`${this.executablePath}${this.major}.${this.minor}_`, `${this.executablePath}${this.major}.${this.minor}`);

                // ensure the pip script is executable
                chmodSync(this.pipPath, 0o777);
                chmodSync(`${this.pipPath}.${this.minor}`, 0o777);
            }
        }

        mkdirSync(this.installDir, { recursive: true });

        if (zipFile) {
            const zip = new AdmZip(zipFile);
            zip.extractAllTo(this.installDir, true)
            postProcess();
            return;
        }

        const url = `https://github.com/bjia56/portable-python/releases/download/${this.releaseTag}/${this.pythonDistributionName}.zip`
        const downloadPath = join(this.installDir, `${this.pythonDistributionName}.zip`);

        const installDir = this.installDir;
        await download(url, downloadPath);

        const zip = new AdmZip(downloadPath);
        zip.extractAllTo(installDir, true)

        rmSync(downloadPath);
        postProcess();
    }

    /**
     * Uninstalls the Python distribution.
     */
    async uninstall() {
        if (!this.isInstalled()) {
            return;
        }
        await new Promise<void>((resolve, reject) => rm(this.extractPath, { force: true, recursive: true }, (e) => {
            if (e) {
                reject(e);
            } else {
                resolve();
            }
        }));
    }

}

