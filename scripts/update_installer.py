#!/usr/bin/env python3

from distutils.version import StrictVersion, LooseVersion
import json
import os
import subprocess
import sys

if len(sys.argv) != 3:
    print(f'Usage: {sys.argv[0]} <python_version> <release_tag>')
    sys.exit(1)

major_minor = '.'.join(sys.argv[1].split('.')[0:2])

base_installer_dir = os.path.join(
    os.path.dirname(os.path.dirname(os.path.realpath(__file__))),
    "installers",
    "nodejs"
)
base_installer_package_json = os.path.join(base_installer_dir, "package.json")
version_installer_dir = f"{base_installer_dir}-{major_minor}"
version_installer_package_json = os.path.join(version_installer_dir, "package.json")

###
# Update @bjia56/portable-python package.json
###

with open(base_installer_package_json, 'r') as f:
    package_json = json.load(f)

versions = package_json['portablePython']['versions']
if sys.argv[1] not in versions:
    versions.append(sys.argv[1])
    versions.sort(key=StrictVersion)
    versions.reverse()

version_builds = package_json['portablePython']['versionBuilds']
version_builds[sys.argv[1]] = sys.argv[2]

package_version = StrictVersion(package_json["version"])
package_json["version"] = f"{package_version.version[0]}.{package_version.version[1]}.{package_version.version[2] + 1}"

with open(base_installer_package_json, 'w') as f:
    json.dump(package_json, f, indent=2)

###
# Update version-specific package.json
###

with open(version_installer_package_json, 'r') as f:
    package_json = json.load(f)

package_version = StrictVersion(package_json["version"])
package_json["version"] = f"{package_version.version[0]}.{package_version.version[1]}.{package_version.version[2] + 1}"

with open(version_installer_package_json, 'w') as f:
    json.dump(package_json, f, indent=2)