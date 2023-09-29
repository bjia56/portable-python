var os = require("os");
var path = require("path");
var pythonVersion = require("./pythonVersion");

module.exports = path.join(__dirname, pythonVersion, "bin", "python" + (os.platform() === "win32" ? ".exe" : ""));