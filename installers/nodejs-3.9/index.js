var python = require("@bjia56/portable-python");
var pythonVersion = require("./pythonVersion");
module.exports = new python.PortablePython(pythonVersion, __dirname).executablePath;