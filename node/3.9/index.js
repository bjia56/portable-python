import { platform } from "os";
import { join } from "path";
import pythonVersion from "./pythonVersion";

export default join(__dirname, pythonVersion, "bin", "python" + (platform() === "win32" ? ".exe" : ""));