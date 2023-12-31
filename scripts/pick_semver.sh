#!/bin/bash

python_version=$1

tags=$(git tag | grep $python_version)

if [[ -z "$tags" ]]; then
    echo "v$python_version-build.0"
    exit 0
fi

most_recent=0
while read tag; do
    tag_postfix=$(echo $tag | sed "s/^v$python_version-build\.//")
    if [ "$tag_postfix" -gt "$most_recent" ]; then
        most_recent=$tag_postfix
    fi
done <<< "$tags"

echo "v$python_version-build.$(expr $most_recent + 1)"