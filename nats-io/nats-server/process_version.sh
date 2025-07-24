#!/bin/bash

# Usage: process_version.sh $version

set -eo pipefail
set -u

source 'lib.sh'

version="$1"


readonly ORG='nats-io'
readonly PROJ='nats-server'
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

        pushd $proj-${version#v}
        # go release need a tag
        git init
        git add . 2>&1 >> /dev/null
        git commit --quiet -m init
        git tag $version
        popd
    fi
}

prepare()
{
    log INFO "Prepare $version"
    mkdir -pv $RESOURCES/$DISTS
    pushd "$RESOURCES"

    if [ ! -d $PROJ-${version#v} ]; then
        git clone -b $version --depth=1 https://github.com/$ORG/$PROJ $PROJ-${version#v}
    fi

    # patch
    pushd "$PROJ-${version#v}"
    cp -f ../goreleaser.yml .goreleaser.yml
    git add .goreleaser.yml
    git commit -m "patch: release loong64 only"
    
    # retag
    git tag -d $version
    git tag $version
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
    upload_release "$ORG" "$PROJ" "${version#v}" "$RESOURCES/$PROJ-${version#v}/dist/$PROJ-$version-linux-$ARCH.tar.gz"
    upload_release "$ORG" "$PROJ" "${version#v}" "$RESOURCES/$PROJ-${version#v}/dist/$PROJ-$version-$ARCH.deb"
    upload_release "$ORG" "$PROJ" "${version#v}" "$RESOURCES/$PROJ-${version#v}/dist/$PROJ-$version-$ARCH.rpm"
    upload_release "$ORG" "$PROJ" "${version#v}" "$RESOURCES/$PROJ-${version#v}/dist/SHA256SUMS"
}

main()
{
    prepare
    build
    upload
}

main "$@"
