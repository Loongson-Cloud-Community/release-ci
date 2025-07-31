#!/bin/bash

set -eo pipefail

source "$(dirname $0)/lib.sh"

git_commit() 
{
    versions=$(echo "$1" | tr '\n' ' ')
	git add .

    git config user.name "qiangxuhui"
    git config user.email "qiangxuhui@loongson.cn"
    git commit -m "Add versions: $versions"
	git pull --rebase
    git push origin main
}


main()
{
    # 1.获取要构建的版本
    IFS=$'\n' versions=($(./fetch_versions.sh))

    if [[ -z "$versions" ]]; then
        log INFO "No versions need updating"
        return 0
    else
        log INFO "Versions needing update: ${versions[@]}"
    fi

    # 2.执行构建
    for version in ${versions[@]}
    do
        log INFO "Process version $version"
        ./process_version.sh ${version}
		update_versions_file "processed_versions.txt" "${version}"
    done

    # git_commit "${versions[*]}"

    log INFO "All Versions:\n$(cat processed_versions.txt)"
}

main

