#!/bin/bash

release_version=$1
beta=$2
implementation=$3
print_latest=$4

prefix=$implementation

suffix=build
if [[ "$beta" == "true" ]]; then
    suffix=beta
fi

legacy="false"
tags=$(git tag | grep "$prefix-v$release_version-$suffix")
if [[ -z "$tags" && "$implementation" == "cpython" ]]; then
    tags=$(git tag | grep "v$release_version-$suffix")
    legacy="true"
fi

if [[ -z "$tags" ]]; then
    if [[ "$print_latest" != "true" ]]; then
        echo "$prefix-v$release_version-$suffix.0"
    fi
    exit 0
fi

sed_pattern="s/^$prefix-v$release_version-$suffix\.//"
if [[ "$legacy" == "true" ]]; then
    sed_pattern="s/^v$release_version-$suffix\.//"
fi

most_recent=0
while read tag; do
    tag_postfix=$(echo $tag | sed $sed_pattern)
    if [ "$tag_postfix" -gt "$most_recent" ]; then
        most_recent=$tag_postfix
    fi
done <<< "$tags"

if [[ "$print_latest" == "true" ]]; then
    if [[ "$legacy" == "true" ]]; then
        echo "v$release_version-$suffix.$most_recent"
    else
        echo "$prefix-v$release_version-$suffix.$most_recent"
    fi
else
    echo "$prefix-v$release_version-$suffix.$(expr $most_recent + 1)"
fi
