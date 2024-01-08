var python = require("@bjia56/portable-python");
var pythonVersion = require("./pythonVersion");
new python.PortablePython(pythonVersion, __dirname).install()