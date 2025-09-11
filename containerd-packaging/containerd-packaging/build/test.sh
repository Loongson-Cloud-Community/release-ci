check_rpm() {
    local os=$1
    local version=$2
    local tag=$3
    echo "$os"
    local base_url="http://cloud.loongnix.xa/os-packages/containerd/$os/$version/RPMS"
    echo "$base_url"    
    # 假设文件名可能有后缀
    local filenames=("containerd.io-$tag.rpm" "containerd.io-$tag-*.rpm")

    for f in "${filenames[@]}"; do
        # 注意 * 需要用 shell 扩展或者直接检查状态码
        # curl -s -I 不会展开 *，需要自己知道完整文件名
        curl -s -I "$base_url/$f" | grep -q "200 OK" && echo "$base_url/$f" && return 0
	echo "失败"
    done
    return 1
}

check_rpm "$1" "$2" "$3"
