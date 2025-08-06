#!/bin/bash

# Usage: process_version.sh $version

set -eo pipefail
set -u
# debug
set -x

source 'lib.sh'

version="$1"


readonly ORG='distribution'
readonly PROJ='distribution'
readonly ARCH='loong64'

readonly RESOURCES='resources'
# 存放本地构建可能会用到的源码，避免重复下载耗时，需要在 git 中忽略
readonly DISTS='dists'

download_github_archive()
{
    local org=$1
    local proj=$2
    local version=$3

    if [ ! -f $DISTS/v${version#v}.zip ]; then
        wget -O $DISTS/v${version#v}.zip --quiet --show-progress https://github.com/$org/$proj/archive/refs/tags/v${version}.zip
    fi

    if [ ! -d $proj-${version#v} ]; then
        unzip -q $DISTS/v${version#v}.zip
    fi
}

prepare()
{
    log INFO "Prepare $version"
    mkdir -pv $RESOURCES/$DISTS
    pushd "$RESOURCES"

    # download source
    download_github_archive $ORG $PROJ $version

    popd
}

build()
{
    log INFO "Building $version"

    pushd $RESOURCES/$PROJ-${version#v}

    make binaries
    cp README.md LICENSE ./bin/

    pushd ./bin
    tar -zcvf registry_${version}_linux_${ARCH}.tar.gz registry README.md LICENSE
    popd

    popd
}

upload()
{
    log INFO "Upload releases $version"
    #upload_release $org $proj $version $file
    pushd $RESOURCES/$PROJ-${version#v}
    upload_release $ORG $PROJ $version ./bin/registry_${version}_linux_${ARCH}.tar.gz
    popd
}

main()
{
    prepare
    build
    upload
}

main "$@"
