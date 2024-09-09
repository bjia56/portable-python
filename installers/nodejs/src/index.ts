import { createWriteStream, existsSync } from "fs";
import { mkdir, rm } from "fs/promises";
import { join, dirname } from "path";
import { Readable } from 'stream';
import { finished } from 'stream/promises';
import { ReadableStream } from 'stream/web';
import AdmZip from "adm-zip";

import { IInstaller, IPortablePython, IPortablePythonOptions } from "./types";
import { getVersionBuilds, pickVersion } from "./versions";
import CPythonInstaller from "./cpython";
import GraalPyInstaller from "./graalpy";
import PyPyInstaller from "./pypy";

const INSTALLERS = new Map<string, new (parent: IPortablePython) => IInstaller>([
    ["cpython", CPythonInstaller],
    ["graalpy", GraalPyInstaller],
    ["pypy", PyPyInstaller],
]);

async function download(url: string, dest: string) {
    const res = await fetch(url);
    const file = createWriteStream(dest);
    await finished(Readable.fromWeb(res.body as ReadableStream).pipe(file));
}

export class PortablePython implements IPortablePython {
    private _version: string
    private _installer: IInstaller
    private _experimentalTag: string
    implementation: string = "cpython"
    distribution: string = "auto"
    installDir = dirname(__dirname);

    constructor(version: string, installDir: string | null = null, options: IPortablePythonOptions = {}) {
        if (!version) {
            throw Error("version must not be empty");
        }

        if (options.implementation) {
            this.implementation = options.implementation;
        }
        if (options.distribution) {
            this.distribution = options.distribution;
        }

        if (!INSTALLERS.has(this.implementation)) {
            throw Error("invalid implementation");
        }

        const ctor = INSTALLERS.get(this.implementation)!;
        this._installer = new ctor(this);
        this._installer.validateOptions();

        if (installDir) {
            this.installDir = installDir;
        }

        if (options._tagOverride) {
            this._experimentalTag = options._tagOverride;
        }

        if (options._versionOverride) {
            this._version = options._versionOverride;
        } else {
            this._version = pickVersion(this.implementation, version);
        }
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
        return join(this.installDir, this._installer.relativeExecutablePath);
    }

    /**
     * Contains the path to the bundled pip executable.
     */
    get pipPath() {
        return join(this.installDir, this._installer.relativePipPath);
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
        if (this._experimentalTag) {
            return this._experimentalTag;
        }
        return getVersionBuilds(this.implementation)[this.version] as string;
    }

    /**
     * Contains the full name of the Python distribution.
     */
    get pythonDistributionName() {
        return this._installer.pythonDistributionName;
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

        await mkdir(this.installDir, { recursive: true });

        if (zipFile) {
            const zip = new AdmZip(zipFile);
            zip.extractAllTo(this.installDir, true)
            await this._installer.postInstall()
            return;
        }

        const url = `https://github.com/bjia56/portable-python/releases/download/${this.releaseTag}/${this.pythonDistributionName}.zip`
        const downloadPath = join(this.installDir, `${this.pythonDistributionName}.zip`);

        const installDir = this.installDir;
        await download(url, downloadPath);

        const zip = new AdmZip(downloadPath);
        zip.extractAllTo(installDir, true)

        await rm(downloadPath);
        await this._installer.postInstall();
    }

    /**
     * Uninstalls the Python distribution.
     */
    async uninstall() {
        if (!this.isInstalled()) {
            return;
        }
        await rm(this.extractPath, { force: true, recursive: true });
    }

}

