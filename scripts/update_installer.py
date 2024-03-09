#!/usr/bin/env python3

from distutils.version import StrictVersion
import json
import sys

if len(sys.argv) != 4:
    print(f'Usage: {sys.argv[0]} <package.json path> <python_version> <release_tag>')
    sys.exit(1)

with open(sys.argv[1], 'r') as f:
    package_json = json.load(f)

versions = package_json['portablePython']['versions']
if sys.argv[2] not in versions:
    versions.append(sys.argv[2])
    versions.sort(key=StrictVersion)
    versions.reverse()

version_builds = package_json['portablePython']['versionBuilds']
version_builds[sys.argv[2]] = sys.argv[3]

with open(sys.argv[1], 'w') as f:
    json.dump(package_json, f, indent=2)
