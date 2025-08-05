#!/bin/bash

set -eo pipefail

process(){

    local tag=$1
    pushd build
        ./build.sh "$tag"
    popd

}

process "$1"
