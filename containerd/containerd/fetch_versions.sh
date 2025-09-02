#!/bin/bash
set -eo pipefail

fetch_versions(){
    local versions
    versions=$(curl -s "https://api.github.com/repos/containerd/containerd/tags?per_page=100&page=1" \
        | jq -r '.[].name' \
	| grep -E '^v[0-9]+(\.[0-9]+)*(-rc\.[0-9]+)?$' \
        | head -n 30 \
        | grep -Fxv -f ignore_versions.txt \
        | grep -Fxv -f processed_versions.txt)

    echo "$versions"
}

fetch_versions
