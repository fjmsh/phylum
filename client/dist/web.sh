#!/bin/bash

# Build the web app
builddir="build/web"
declare -A versioned_names

version_file() {
    name=$1
    sum=$(sha256sum "$name" | cut -f 1 -d ' ')
    ver=${sum:0:8}
    base=${name%.*}
    ext=${name##*.}
    versioned_names[$name]="$base.$ver.$ext"
    echo "Renaming $name to ${versioned_names[$name]}"
    mv "$name" "${versioned_names[$name]}"
}

version_files() {
    local -n files=$1
    for name in "${files[@]}"; do
        if [ -f $name ]; then
            version_file $name 
        fi
    done
}


use_versioned() {
    target=$1
    local -n files=$2
    echo "Processing $target"
    version_files "${!files}"
    for name in "${files[@]}"; do
        sed -i '' "s/\"$name\"/\"${versioned_names[$name]}\"/g" "$target"
    done
}

rm -rf $builddir
fvm flutter build web --wasm
cd $builddir

srcs=("main.dart.js" "main.dart.mjs" "main.dart.wasm" "phylum_app_worker.js")
use_versioned "flutter_bootstrap.js" srcs

srcs=("flutter_bootstrap.js")
use_versioned "index.html" srcs
