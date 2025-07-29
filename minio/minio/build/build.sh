#!/bin/bash

set -eo pipefail

source "../lib.sh"

readonly ORG='minio'
readonly PROJ='minio'

git_clone(){
    local tag=$1
    rm -rf "$PROJ-src"
    git clone --depth=1 --branch $tag "https://github.com/$ORG/$PROJ" "$PROJ-src"
}

build(){
    pushd "$PROJ-src"
    make build
    popd
}

upload(){
    local tag=$1
    local -r upload_url="http://cloud.loongnix.xa/releases/loongarch64/$ORG/$PROJ/$tag"
    # curl -F file=@./xxx "http://cloud.loongnix.xa/releases/loongarch64/$ORG/$PROJ/$tag"
    pushd "$PROJ-src"
    no_proxy=cloud.loongnix.xa curl -F file=@./minio "$upload_url"
    popd
}

process(){
    local tag=$1

    git_clone "$tag"
    log INFO "############## $tag: 代码下载完毕"
    
    build "$tag"
    log INFO "############## $tag: 二进制构建完毕"

    upload "$tag"
    log INFO "############## $tag: 二进制上传完毕"
}

process "$1"
