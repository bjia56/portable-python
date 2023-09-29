var os = require("os");

const pythonVersion = "3.9.17";

var platform = (() => {
    if (os.platform() == "win32") {
        return "windows";
    }
    return os.platform();
})();

var arch = (() => {
    if (platform == "darwin") {
        return "universal2";
    }

    switch (os.arch()) {
    case "x64":
        return "x86_64";
    case "arm":
        return "armv7l";
    case "arm64":
        return "aarch64";
    }
})();

module.exports = `python-${pythonVersion}-${platform}-${arch}`;
