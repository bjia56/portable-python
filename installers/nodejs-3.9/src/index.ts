import path from "path";
import { PortablePython } from "@bjia56/portable-python";
import { pythonVersion } from "./pythonVersion";
new PortablePython(pythonVersion, path.dirname(__dirname)).install()
