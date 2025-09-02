#!/bin/bash

set -eo pipefail

source "../lib.sh"

readonly ORG='containerd'
readonly PROJ='containerd'

git_clone(){
    local tag=$1
    rm -rf "$PROJ-src"
    git clone --depth=1 --branch $tag "https://github.com/$ORG/$PROJ" "$PROJ-src"
}

build(){
    local tag=$1
    pushd "$PROJ-src"
    bash ../patch_loong64.sh
    make release static-release
    popd
}

#containerd-1.7.2-linux-loong64.tar.gz			cri-containerd.DEPRECATED.txt  v1.2.0.toml  v1.6.0.toml
#containerd-1.7.2-linux-loong64.tar.gz.sha256sum		README.md		       v1.3.0.toml  v1.7.0.toml
#containerd-static-1.7.2-linux-loong64.tar.gz		v1.0.0.toml		       v1.4.0.toml  v1.7.1.toml
#containerd-static-1.7.2-linux-loong64.tar.gz.sha256sum	v1.1.0.toml
upload(){
    local tag=$1
    local tag_no_v=${tag#v}
    local -r upload_url="http://cloud.loongnix.xa/releases/loongarch64/$ORG/$PROJ/$tag"
    # curl -F file=@./xxx "http://cloud.loongnix.xa/releases/loongarch64/$ORG/$PROJ/$tag"
    pushd "$PROJ-src"
    ls -la releases
    no_proxy=cloud.loongnix.xa curl -F file=@./releases/containerd-$tag_no_v-linux-loong64.tar.gz "$upload_url"
    no_proxy=cloud.loongnix.xa curl -F file=@./releases/containerd-$tag_no_v-linux-loong64.tar.gz.sha256sum "$upload_url"
    no_proxy=cloud.loongnix.xa curl -F file=@./releases/containerd-static-$tag_no_v-linux-loong64.tar.gz "$upload_url"
    no_proxy=cloud.loongnix.xa curl -F file=@./releases/containerd-static-$tag_no_v-linux-loong64.tar.gz.sha256sum "$upload_url"
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
