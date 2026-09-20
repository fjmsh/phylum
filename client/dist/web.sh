#!/bin/bash

# Build the web app
builddir="build/web"
declare -A versioned_names
build=false
use_fvm=false

usage() {
 echo "Usage: $0 [OPTIONS]"
 echo "Options:"
 echo " -h, --help      Display this help message"
 echo " -b, --build     Build the app"
 echo " -f, --use-fvm   Use FVM to build the app (only with -b)"
}

# Function to handle options and arguments
handle_options() {
  while [ $# -gt 0 ]; do
    case $1 in
      -h | --help)
        usage
        exit 0
        ;;
      -b | --build)
        build=true
        ;;
      -f | --use-fvm)
        use_fvm=true
        ;;
      *)
        echo "Invalid option: $1" >&2
        usage
        exit 1
        ;;
    esac
    shift
  done
}

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
        echo "WARNING: File does not exist: $name"
        # exit 1
    fi
}

use_versioned() {
    target=$1
    echo "Pinning versions in $target"
    for name in "${!versioned_names[@]}"; do
        sed -E -i '' "s/\"(\/)?$name\"/\"\1${versioned_names[$name]}\"/g" "$target"
    done
}

handle_options "$@"

if [ "$build" = true ]; then
    rm -rf $builddir
    if [ "$use_fvm" = true ]; then
        echo "Building App with FVM"
        fvm flutter build web --wasm
    else
        echo "Building App"
        flutter build web --wasm
    fi
fi

cd $builddir

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
