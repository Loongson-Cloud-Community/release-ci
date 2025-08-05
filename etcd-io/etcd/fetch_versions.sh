#!/bin/bash
set -eo pipefail

fetch_versions(){
    local versions
    versions=$(curl -s "https://api.github.com/repos/etcd-io/etcd/tags?per_page=100&page=1" \
        | jq -r '.[].name' \
        | head -n 70 \
        | grep -Fxv -f ignore_versions.txt \
        | grep -Fxv -f processed_versions.txt)

    echo "$versions"
}

fetch_versions
