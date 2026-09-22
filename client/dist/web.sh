#!/bin/bash

# Build the web app
builddir="build/web"
declare -A versioned_names
build=false
use_fvm=false
dry_run=false
debug=false

usage() {
 echo "Usage: $0 [OPTIONS]"
 echo "Options:"
 echo " -h, --help      Display this help message"
 echo " -b, --build     Build the app"
 echo " -f, --use-fvm   Use FVM to build the app (only with -b)"
 echo " -n, --dry-run   Dry Run"
 echo "     --debug 	Debug build with JS instead of WASM"
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
      -n | --dry-run)
        dry_run=true
        ;;
      --debug)
        debug=true
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

version_files() {
    pattern=$1
    for name in $pattern; do
        if [[ -v versioned_names[$name] ]]; then
            echo "$name is already versioned"
        elif [ -f $name ]; then
            sum=$(sha256sum "$name" | cut -f 1 -d ' ')
            ver=${sum:0:8}
            base=${name%.*}
            ext=${name##*.}
            newname="$base.$ver.$ext"
            versioned_names[${name##*/}]=${newname##*/}
            echo "Using hash $ver for ${name##*/}"
            if [ $dry_run = "true" ]; then
                echo mv "$name" "$newname"
            else
                mv "$name" "$newname"
            fi
        elif [ ! -d $name ]; then
            echo "WARNING: File does not exist: $name"
            # exit 1
        fi
    done
}

use_versioned() {
    target=$1
    echo "Pinning versions in $target"
    for name in "${!versioned_names[@]}"; do
        if [ $dry_run = "true" ]; then
            echo sed -E -i.bak "s:$name\":${versioned_names[$name]}\":g" "$target" \&\& rm "$target.bak"
        else
            sed -E -i.bak "s:$name\":${versioned_names[$name]}\":g" "$target" && rm "$target.bak"
        fi
    done
}

handle_options "$@"

if [ "$build" = true ]; then
    rm -rf $builddir
    build_flags=" --wasm"
    if [ "$debug" = "true" ]; then
        build_flags=" --debug"
    fi
    if [ "$use_fvm" = "true" ]; then
        echo "Building App with FVM"
        fvm flutter build web $build_flags
    else
        echo "Building App"
        flutter build web $build_flags
    fi
fi

cd $builddir

echo "Versioning Assets"
version_files "assets/fonts/*"

use_versioned "assets/FontManifest.json"
#version_files "assets/FontManifest.json"
#use_versioned "main.dart.js"

version_files "phylum.webmanifest"
use_versioned "phylum_app_worker.js"

version_files "main.dart.*"
version_files "phylum_app_worker.js"
use_versioned "flutter_bootstrap.js"
version_files "flutter_bootstrap.js"

use_versioned "index.html"
