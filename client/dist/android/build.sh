#!/bin/bash

set -euo pipefail

norebuild=false
builddir=${BUILDDIR:-/build/phylum}/cloud.phylum.drive/client

echo "Removing old build container"
podman container rm android-build || true

echo "Building with root ${builddir}"
podman run \
        --name android-build \
        -it \
        -v ../../:/src:ro \
        --user 0:0 \
        docker.io/shroff12/flutter-android:3.47.3 \
        sh -c "\
        mkdir -p $builddir && cd $builddir && chown flutter .\
        && su -c \"sh -c '\
        cp -R /src/pubspec.* /src/android /src/lib /src/assets /src/fonts . \
        && flutter pub get \
        && flutter build apk --no-pub'\" \
        flutter"

echo "Copying outputs"
podman cp --overwrite android-build:$builddir/build/app/outputs/apk/release/ .
cp -f release/*.apk .

echo "Cleaning up"
rm -rf release
podman container rm android-build

