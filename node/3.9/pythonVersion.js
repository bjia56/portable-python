import { platform as _platform, arch as _arch } from "os";

const pythonVersion = "3.9.17";

var platform = (() => {
    if (_platform() == "win32") {
        return "windows";
    }
    return _platform();
})();

var arch = (() => {
    if (platform == "darwin") {
        return "universal2";
    }

    switch (_arch()) {
    case "x64":
        return "x86_64";
    case "arm":
        return "armv7l";
    case "arm64":
        return "aarch64";
    }
})();

export default `python-${pythonVersion}-${platform}-${arch}`
