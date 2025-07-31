#!/bin/bash
set -eo pipefail

fetch_versions(){

	local versions=$(gh api repos/minio/mc/tags --paginate --jq '.[].name' \
        | grep -v '2015' \
        | grep -v 'OFFICIAL' \
        | grep -E '^RELEASE' \
        | sort)

    echo "$versions" \
        | grep -Fxv -f ignore_versions.txt \
        | { grep -Fxv -f processed_versions.txt || [ $? -eq 1 ]; }

}

fetch_versions
