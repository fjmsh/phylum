#!/bin/bash

# Build the web app
builddir="build/web"
declare -A versioned_names

version_file() {
    name=$1
    if [[ -v versioned_names[$name] ]]; then
        echo "$name is already versioned"
    elif [ -f $name ]; then
        sum=$(sha256sum "$name" | cut -f 1 -d ' ')
        ver=${sum:0:8}
        base=${name%.*}
        ext=${name##*.}
        versioned_names[$name]="$base.$ver.$ext"
        echo "Using hash $ver for $name"
        mv "$name" "${versioned_names[$name]}"
    else
        echo "File does not exist: $name"
        exit 1
    fi
}

use_versioned() {
    target=$1
    echo "Pinning versions in $target"
    for name in "${!versioned_names[@]}"; do
        sed -E -i '' "s/\"(\/)?$name\"/\"\1${versioned_names[$name]}\"/g" "$target"
    done
}

echo "Building App"
rm -rf $builddir
fvm flutter build web --wasm
cd $builddir

echo
echo "Versioning Assets"
version_file "phylum.webmanifest"
use_versioned "phylum_app_worker.js"

version_file "main.dart.js"
version_file "main.dart.mjs"
version_file "main.dart.wasm"
version_file "phylum_app_worker.js"
use_versioned "flutter_bootstrap.js"

version_file "phylum.webmanifest"
version_file "flutter_bootstrap.js"
use_versioned "index.html"
