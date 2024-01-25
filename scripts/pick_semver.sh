#!/bin/bash

python_version=$1
beta=$2


suffix=build
if [[ "$beta" == "true" ]]; then
    suffix=beta
fi

tags=$(git tag | grep "$python_version-$suffix")

if [[ -z "$tags" ]]; then
    echo "v$python_version-$suffix.0"
    exit 0
fi

most_recent=0
while read tag; do
    tag_postfix=$(echo $tag | sed "s/^v$python_version-$suffix\.//")
    if [ "$tag_postfix" -gt "$most_recent" ]; then
        most_recent=$tag_postfix
    fi
done <<< "$tags"

echo "v$python_version-$suffix.$(expr $most_recent + 1)"