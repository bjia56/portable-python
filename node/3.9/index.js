import { createWriteStream, unlink, existsSync, rm } from "fs";
import redirects from "follow-redirects";
import { dirname, join } from "path";
import { platform, arch } from "os";
import { fileURLToPath } from 'url';
import { x } from "tar";

const __dirname = dirname(fileURLToPath(import.meta.url));

const pythonVersion = "3.9.17";
const releaseTag = `v${pythonVersion}-build.0`;

const dlPlatform = (() => {
    if (platform() == "win32") {
        return "windows";
    }
    return platform();
})();

const dlArch = (() => {
    if (dlPlatform == "darwin") {
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
})();

const pythonFullName = `python-${pythonVersion}-${dlPlatform}-${dlArch}`;
const url = `https://github.com/bjia56/portable-python/releases/download/${releaseTag}/${pythonFullName}.tar.gz`
const downloadPath = join(__dirname, `${pythonFullName}.tar.gz`);
const extractPath = join(__dirname, pythonFullName)

// https://stackoverflow.com/a/32134846
function download(url, dest, cb) {
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

export function isInstalled() {
    return existsSync(extractPath);
}

export async function install() {
    if (isInstalled()) {
        return;
    }
    var dl = new Promise((resolve, reject) =>
        download(url, downloadPath, function(err) {
            if (err) {
                reject(err);
                return;
            }

            x({ file: downloadPath, cwd: __dirname, sync: true });
            unlink(downloadPath, () => resolve());
        })
    );
    await dl;
}

export async function uninstall() {
    return new Promise((resolve, reject) => rm(extractPath, { force: true, recursive: true }, (e) => {
        if (e) {
            reject(e);
        } else {
            resolve();
        }
    }));
}

export const executable = join(__dirname, pythonFullName, "bin", "python" + (platform() === "win32" ? ".exe" : ""));