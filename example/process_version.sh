#!/bin/bash

# Usage: process_version.sh $version

set -eo pipefail
set -u

source 'lib.sh'

version="$1"


readonly ORG=''
readonly PROJ=''
readonly ARCH='loong64'

readonly RESOURCES='resources'
# 存放本地构建可能会用到的源码，避免重复下载耗时，需要在 git 中忽略
readonly DISTS='dists'

download_github_archive()
{
    local org=$1
    local proj=$2
    local version=$3

    if [ ! -f $DISTS/$version.zip ]; then
        wget -O $DISTS/$version.zip --quiet --show-progress https://github.com/$org/$proj/archive/refs/tags/$version.zip
    fi

    if [ ! -d $proj-${version#v} ]; then
        unzip -q $DISTS/$version.zip
    fi
}

prepare()
{
    log INFO "Prepare $version"
    mkdir -pv $RESOURCES/$DISTS
    pushd "$RESOURCES"

    # download source
    download_github_archive $ORG $PROJ $version

    # patch

    popd

    popd
}

build()
{
    log INFO "Building $version"

    pushd $RESOURCES/$PROJ-${version#v}

    goreleaser release --clean --skip publish,sbom

    popd
}

upload()
{
    log INFO "Upload releases $version"
    #upload_release $org $proj $version $file
}

main()
{
    prepare
    build
    upload
}

main "$@"
