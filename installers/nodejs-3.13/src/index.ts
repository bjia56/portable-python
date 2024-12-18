import path from "path";
import { PortablePython } from "@bjia56/portable-python";
import { pythonVersion } from "./pythonVersion";
if (require.main === module) {
    new PortablePython(pythonVersion, path.dirname(__dirname)).install();
} else {
    module.exports = new PortablePython(pythonVersion, path.dirname(__dirname)).executablePath;
}
