import { createWriteStream, existsSync, rm, rmSync, mkdirSync, chmodSync } from "fs";
import { join, dirname } from "path";
import { platform, arch } from "os";
import { Readable } from 'stream';
import { finished } from 'stream/promises';
import { ReadableStream } from 'stream/web';
import AdmZip from "adm-zip";

const packageJson = require("../package.json");

const DL_PLATFORM = (() => {
    if (platform() == "win32") {
        return "windows";
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
    return VERSIONS[0]
}

// https://stackoverflow.com/a/32134846
async function download(url: string, dest: string) {
    const res = await fetch(url);
    const file = createWriteStream(dest);
    await finished(Readable.fromWeb(res.body as ReadableStream).pipe(file));
}

export class PortablePython {
    _version: string
    installDir = dirname(__dirname);

    constructor(version: string, installDir: string | null = null) {
        if (!version) {
            throw Error("version must not be empty");
        }

        if (installDir) {
            this.installDir = installDir;
        }

        this._version = pickVersion(version);
        if (!this.releaseTag) {
            throw Error("no releases available for this version");
        }
    }

    /**
     * Contains the path to the Python executable.
     */
    get executablePath() {
        return join(this.installDir, this.pythonDistributionName, "bin", "python" + (platform() === "win32" ? ".exe" : ""));
    }

    /**
     * Contains the selected Python version.
     */
    get version() {
        return this._version;
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
     */
    async install() {
        if (this.isInstalled()) {
            return;
        }

        const url = `https://github.com/bjia56/portable-python/releases/download/${this.releaseTag}/${this.pythonDistributionName}.zip`
        const downloadPath = join(this.installDir, `${this.pythonDistributionName}.zip`);

        mkdirSync(this.installDir, { recursive: true });

        const installDir = this.installDir;
        await download(url, downloadPath);

        const zip = new AdmZip(downloadPath);
        zip.extractAllTo(installDir, true)

        rmSync(downloadPath);
        if (!this.isInstalled()) {
            throw Error("something went wrong and the installation failed");
        }

        chmodSync(this.executablePath, 0o777);
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

