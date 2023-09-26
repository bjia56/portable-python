#!/bin/bash

python_tarball=$(basename $1)

build_tuple=$(echo $python_tarball | sed "s/\.tar\.gz//")
python_version=$(echo $build_tuple | cut -d '-' -f 2)
platform=$(echo $build_tuple | cut -d '-' -f 3)
arch=$(echo $build_tuple | cut -d '-' -f 4)

tags=$(git tag | grep $python_version)

if [[ -z "$tags" ]]; then
    echo "v$python_version-0"
    exit 0
fi

most_recent=0
while read tag; do
    tag_postfix=$(echo $tag | sed "s/^v$python_version-//")
    if [ "$tag_postfix" -gt "$most_recent" ]; then
        most_recent=$tag_postfix
    fi
done <<< "$tags"

echo "v$python_version-$(expr $most_recent + 1)"