#!/bin/bash

set -eo pipefail

source "../lib.sh"

readonly ORG='containerd'
readonly PROJ='containerd'

create_repodata_rpm(){
    local os=$1
    local version=$2
    local SERVER="10.130.0.141"
    local USER="merore"
    local REMOTE_RPM_DIR="/data/file-server/os-packages/containerd/$os/$version/RPMS"
    local REMOTE_SRPM_DIR="/data/file-server/os-packages/containerd/$os/$version/SRPMS"

    # 判断服务器端是否已有 repodata/repomd.xml（使用 sudo）
    if ssh -o StrictHostKeyChecking=no $USER@$SERVER "sudo test -f $REMOTE_RPM_DIR/repodata/repomd.xml"; then
        echo "Server repodata exists. Will use createrepo --update"
        ssh -o StrictHostKeyChecking=no $USER@$SERVER "sudo createrepo --update $REMOTE_RPM_DIR"
    else
        echo "Server repodata not found. Will create new repodata"
        ssh -o StrictHostKeyChecking=no $USER@$SERVER "sudo createrepo $REMOTE_RPM_DIR"
    fi
# 在docker中使用，containerd没有SRPM
    # 判断服务器端是否已有 repodata/repomd.xml（使用 sudo）
#    if ssh -o StrictHostKeyChecking=no $USER@$SERVER "sudo test -f $REMOTE_SRPM_DIR/repodata/repomd.xml"; then
#        echo "Server repodata exists. Will use createrepo --update"
#        ssh -o StrictHostKeyChecking=no $USER@$SERVER "sudo createrepo --update $REMOTE_SRPM_DIR"
#    else
#        echo "Server repodata not found. Will create new repodata"
#        ssh -o StrictHostKeyChecking=no $USER@$SERVER "sudo createrepo $REMOTE_SRPM_DIR"
#    fi
}


upload_rpm(){
    local os=$1
    local version=$2

    # 上传 RPMS
    local rpm_dir="dist"
    find "$rpm_dir" -type f -name "*.rpm" | while read -r file; do
        echo "Uploading $file..."
        curl -f -F "file=@$file" "http://cloud.loongnix.xa/os-packages/containerd/$os/$version/RPMS/"
    done

}

check_rpm(){
	local os=$1
        local version=$2
	local tag=$3

	http://cloud.loongnix.xa/os-packages/containerd/$os/$version/RPMS/containerd.io-$3*.rpm
}

build_com(){
	local distro=$1
	local tag=$2
	rm -rf dist
	./build-containerd.sh --distro $1 --suite $2
	upload_rpm $1 $2
	create_repodata_rpm $1 $2
	log INFO "############## $tag: rpm源更新完毕 openanolis opencloudos openeuler loongnix-server"
	rm -rf dist
}

build(){
	rm -rf dist
        export CONTAINERD_VERSION=$tag
#       ./build-containerd.sh --distro debian --suite trixie
#	build_com openanolis 23
	build_com opencloudos 23
	build_com loongnix-server 23
	build_com openeuler 24
        unset CONTAINERD_VERSION

}

process(){
    local tag=$1

    log INFO "############## $tag: 开始编译"

    build "$tag"
    log INFO "############## $tag: rpm包构建完毕"

}

process "$1"

