#!/bin/bash

set -eo pipefail

source "../lib.sh"

readonly ARCH=loong64
readonly ORG='etcd-io'
readonly PROJ='etcd'
readonly BIN_UPLOAD='etcd'

build(){
    docker buildx build --platform linux/loong64 \
            -t etcd-static-loong64:$tag \
            --build-arg ETCD_VERSION=$tag  \
            --build-arg https_proxy=${https_proxy} \
            -f ../binaries/Dockerfile . --load
    mkdir -p dist
          docker run --rm -v $PWD/dist:/dist \
            etcd-static-loong64:$tag \
            bash -c 'cp /opt/etcd/dist/* /dist/ || true'
    mkdir -p "$PKG_NAME"
    cp dist/* "$PKG_NAME"/
    tar czf "${PKG_NAME}.tar.gz" "$PKG_NAME"
}

upload(){
    local tag=$1
    local -r upload_url="http://cloud.loongnix.xa/releases/loongarch64/$ORG/$PROJ/$tag"
    no_proxy=cloud.loongnix.xa curl -F file=@./${PKG_NAME}.tar.gz "$upload_url"
}

delete(){
    rm -rf dist etcd*
    docker rmi -f etcd-static-loong64:$tag
}

process(){
    local tag=$1
    local PKG_NAME="etcd-$tag-linux-${ARCH}"
    build "$tag"
    log INFO "############## $tag: 二进制构建完毕"

    upload "$tag"
    log INFO "############## $tag: 二进制上传完毕"

    delete "$tag"
    log INFO "############## $tag: 清理构建产物完毕"
}

process "$1"
