import { createWriteStream, unlink, existsSync, rm, mkdirSync } from "fs";
import redirects from "follow-redirects";
import { join } from "path";
import { platform, arch } from "os";
import { x } from "tar";

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
    case "x64":
        return "x86_64";
    case "arm":
        return "armv7l";
    case "arm64":
        return "aarch64";
    }

    return "unknown";
})();

const VERSIONS = [
    "3.9.17",
    "3.8.17",
];

const VERSION_BUILDS = new Map<string, string>([
   [ "3.9.17", "v3.9.17-build.1"],
    ["3.8.17", "v3.8.17-build.1"],
]);

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
function download(url: string, dest: string, cb: (s: any) => void) {
    const file = createWriteStream(dest);

    const request = redirects.https.get(url, (response) => {
        // check if response is success
        if (response.statusCode !== 200) {
            return cb('Response status was ' + response.statusCode);
        }

        response.pipe(file);
    });

    // close() is async, call cb after close completes
    file.on('finish', () => file.close(cb));

    // check for request error too
    request.on('error', (err) => {
        unlink(dest, () => cb(err.message)); // delete the (partial) file and then return the error
    });

    file.on('error', (err) => {
        unlink(dest, () => cb(err.message)); // delete the (partial) file and then return the error
    });
}

export class PortablePython {
    _version: string

    constructor(version: string, public installDir: string) {
        if (!version) {
            throw Error("version must not be empty");
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
        return VERSION_BUILDS.get(this.version) as string;
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

        const url = `https://github.com/bjia56/portable-python/releases/download/${this.releaseTag}/${this.pythonDistributionName}.tar.gz`
        const downloadPath = join(this.installDir, `${this.pythonDistributionName}.tar.gz`);

        mkdirSync(this.installDir, { recursive: true });

        const installDir = this.installDir;
        await new Promise<void>((resolve, reject) =>
            download(url, downloadPath, function(err) {
                if (err) {
                    reject(err);
                    return;
                }

                x({ file: downloadPath, cwd: installDir, sync: true });
                unlink(downloadPath, () => resolve());
            })
        );

        if (!this.isInstalled()) {
            throw Error("something went wrong and the installation failed");
        }
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

