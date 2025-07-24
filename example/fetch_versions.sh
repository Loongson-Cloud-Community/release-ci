#!/bin/bash

set -eo pipefail
set -u

readonly ORG=''
readonly PROJ=''
readonly TAGS_NUM=2

# X.Y.Z
#readonly VERSION_REGEX='^[0-9]+.[0-9]+.[0-9]+$'
# vX.Y.Z
readonly VERSION_REGEX='^v[0-9]+.[0-9]+.[0-9]+$'

declare -ar IGNORE_VERSIONS=()

# Usage: get_github_tags $org $proj
# Return: (tags)
get_github_tags()
{
    local org=$1
    local proj=$2

    git ls-remote --tags https://github.com/$org/$proj.git \
    | cut -d'/' -f3- \
    | cut -d'^' -f1 \
    | grep -E "$VERSION_REGEX" \
    | sort -rV \
    | uniq

}

fetch_versions() {
    local versions=$(get_github_tags "$ORG" "$PROJ" \
            | head -$TAGS_NUM \
            | sort -V
    )
    ## 过滤 忽略和已构建的版本
    (echo "$versions" \
        | grep -Fvx -f <(printf "%s\n" ${IGNORE_VERSIONS[@]}) \
        | grep -Fvx -f versions.txt
    ) || true

}

fetch_versions
