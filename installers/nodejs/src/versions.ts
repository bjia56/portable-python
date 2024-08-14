const packageJson = require("../package.json");
const VERSIONS = packageJson.portablePython;

export function getVersions(implementation: string) {
    const versions = VERSIONS[implementation].versions;
    if (!versions) {
        throw Error("unknown implementation");
    }
    return versions;
}

export function getVersionBuilds(implementation: string) {
    const versionBuilds = VERSIONS[implementation].versionBuilds;
    if (!versionBuilds) {
        throw Error("unknown implementation");
    }
    return versionBuilds;
}

export function pickVersion(implementation: string, version: string) {
    const versions = getVersions(implementation);
    for (let i = 0; i < versions.length; ++i) {
        // TODO: This doesn't handle semver correctly, e.g. 3.8.17 will match 3.8.1
        if (versions[i].startsWith(version)) {
            return versions[i];
        }
    }
    return null;
}