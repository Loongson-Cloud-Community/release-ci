#!/bin/bash

# Usage: process_version.sh $version

set -eo pipefail
set -u
# debug
set -x

source 'lib.sh'

version="$1"


readonly ORG='influxdata'
readonly PROJ='telegraf'
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
    cp -f Makefile.replace $PROJ-${version#v}/Makefile

    popd
}

build()
{
    log INFO "Building $version"

    pushd $RESOURCES/$PROJ-${version#v}

    make build
    make config
    make loong64.deb linux_loong64.tar.gz

    popd
}

upload()
{
    log INFO "Upload releases $version"
    #upload_release $org $proj $version $file
    upload_release "$ORG" "$PROJ" "${version#v}" "$RESOURCES"/$PROJ-${version#v}/build/dist/"$PROJ"_${version#v}-1_$ARCH.deb
    upload_release "$ORG" "$PROJ" "${version#v}" "$RESOURCES"/$PROJ-${version#v}/build/dist/"$PROJ"-${version#v}_linux_$ARCH.tar.gz
}

main()
{
    prepare
    build
    upload
}

main "$@"
