#!/bin/bash
#

BUILD_DEB=0
BUILD_RPM=0

while [[ $# > 0 ]]; do
    lowerI="$(echo $1 | awk '{print tolower($0)}')"
    case $lowerI in
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo
            echo "Global Options:"
            echo -e "  -h, --help  \t Show this help message and exit"
            echo -e "  --distro  \t Specify the distribution (e.g., debian, anolis)"
            echo -e "  --suite   \t Specify the suite or release codename (e.g., trixie, 23)"
            exit 0
            ;;
        --distro)
            DISTRO=$2
            shift
            ;;
        --suite)
            SUITE=$2
            shift
            ;;
        *)
            echo "Error: Unknown option $1"
            echo "eg: $0 --distro debian --suite trixie"
            exit 1
            ;;
    esac
    shift
done

################################################################
# REF: v2.0.0
#
REF=${CONTAINERD_VERSION:?}

TMPDIR=$(mktemp -d)

git clone --depth=1 https://github.com/docker/containerd-packaging "${TMPDIR}"

case "${DISTRO}" in
    debian)
        BUILD_DEB=1
        ;;
    openanolis)
        BUILD_RPM=1
        cp -f anolis-23/Dockerfile "${TMPDIR}/dockerfiles/rpm.dockerfile"
        ;;
    opencloudos)
        BUILD_RPM=1
        cp -f opencloudos-23/Dockerfile "${TMPDIR}/dockerfiles/rpm.dockerfile"
        ;;
    loongnix-server)
        BUILD_RPM=1
        cp -f loongnix-server-23/Dockerfile "${TMPDIR}/dockerfiles/rpm.dockerfile"
        ;;
    openeuler)
        BUILD_RPM=1
        cp -f openeuler-24/Dockerfile "${TMPDIR}/dockerfiles/rpm.dockerfile"
        ;;
    *)
        echo "Error: Unknown distribution ${DISTRO}"
        exit 1
        ;;
esac

cp -f containerd.patch /tmp/containerd.patch
cp -f patch_loong64.sh ${TMPDIR}/
pushd "${TMPDIR}" || exit 1
################################################################
# See. https://hub.docker.com/r/docker/dockerfile/tags
# docker.io/docker/dockerfile not support linux/loong64
#
# sed -i '/syntax=docker/d' dockerfiles/deb.dockerfile
#sed -i 's@GOLANG_IMAGE=golang@GOLANG_IMAGE=ghcr.io/loong64/golang@g' common/common.mk
sed -i 's|GOLANG_VERSION?.*|GOLANG_VERSION=1.23.12|' common/common.mk
sed -i 's@ARCH=$(shell uname -m)@ARCH=loong64@g' Makefile

################################################################
# See. https://github.com/opencontainers/runc
# libcontainer/seccomp/patchbpf/enosys_linux.go not support linux/loong64
# vendor/github.com/seccomp/libseccomp-golang/seccomp_internal.go not support linux/loong64
#
# See. https://github.com/containerd/containerd
# libcontainer/system/syscall_linux_64.go not support linux/loong64
# vendor/github.com/cilium/ebpf not support linux/loong64
#
git apply /tmp/containerd.patch || exit 1
sed -i '/\.\/scripts\/checkout.sh src\/github.com\/opencontainers\/runc.*determine-runc-version/a\
\tcp -f patch_loong64.sh src/github.com/containerd/containerd/ && cd src/github.com/containerd/containerd && bash patch_loong64.sh' Makefile
#sed -i 's/output=/output=\/tmp\/abc/g' Makefile
file="Makefile"
tmpfile="$(mktemp)"

while IFS= read -r line; do
    echo "$line" >> "$tmpfile"
    # 碰到目标行，插入新行
    if [[ "$line" == *'--build-arg GID="$(shell id -g)"'* ]]; then
        echo "                --build-arg https_proxy=\"\$(https_proxy)\" \\" >> "$tmpfile"
        echo "                --build-arg http_proxy=\"\$(http_proxy)\" \\" >> "$tmpfile"
    fi
done < "$file"

# 替换原文件
mv "$tmpfile" "$file"

image=""
tag=""
case "$DISTRO" in
    debian)
        image="debian"
	tag="trixie"
        ;;
    openanolis)
        image="openanolis/anolisos"   # 统一命名
        tag="23.3"
        ;;
    opencloudos)
	image="ghcr.io/loong64/opencloudos"   # 统一命名
        tag="23"
        ;;
    loongnix-server)
	image="loongnix/loongnix-server"
        tag="23.1"
        ;;
    openeuler)
        image="openeuler/openeuler"
        tag="24.03-LTS-SP2"
        ;;
    *)
        echo "Unsupported DISTRO: $DISTRO"
        exit 1
        ;;
esac

echo "image=$image"
echo "tag=$tag"
make REF=${REF} BUILD_IMAGE=${image}:${tag}

popd || exit 1

mkdir -p dist
if [ "${BUILD_DEB}" = '1' ]; then
    mv "${TMPDIR}/build/${DISTRO}/${SUITE}/loong64/"* dist/
elif [ "${DISTRO}" = "loongnix-server" ]; then
    mv "${TMPDIR}/build/loongnix/${SUITE}/loongarch64/"* dist/
elif [ "${DISTRO}" = "openeuler" ]; then
    mv "${TMPDIR}/build/openEuler/${SUITE}/loongarch64/"* dist/
elif [ "${DISTRO}" = "openanolis" ]; then
    mv "${TMPDIR}/build/anolis/${SUITE}/loongarch64/"* dist/
elif [ "${BUILD_RPM}" = '1' ]; then
    mv "${TMPDIR}/build/${DISTRO}/${SUITE}/loongarch64/"* dist/
fi

rm -rf "${TMPDIR:?}"
