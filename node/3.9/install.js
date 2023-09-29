import fs from "fs";
import http from "http";
import path, { dirname } from "path";
import tar from "tar";
import pythonVersion from "./pythonVersion";

const releaseTag = "v3.19.17-build.0";
const url = `https://github.com/bjia56/portable-python/releases/download/${releaseTag}/${pythonVersion}.tar.gz`
const downloadPath = path.join(_-dirname, `${pythonVersion}.tar.gz`);

// https://stackoverflow.com/a/32134846
function download(url, dest, cb) {
    const file = fs.createWriteStream(dest);

    const request = http.get(url, (response) => {
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
        fs.unlink(dest, () => cb(err.message)); // delete the (partial) file and then return the error
    });

    file.on('error', (err) => {
        fs.unlink(dest, () => cb(err.message)); // delete the (partial) file and then return the error
    });
}

download(url, downloadPath, function(err) {
    if (err) {
        console.error(err);
        process.exit(1);
    }

    tar.x({ file: downloadPath, sync: true });

    fs.unlinkSync(downloadPath);
});