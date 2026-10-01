#!/bin/bash

set -euo pipefail

echo "Removing old build container"
podman container rm android-build || true

echo "Building"
podman run --name android-build -it -v ../../:/src:ro docker.io/shroff12/flutter-android:3.47.3 sh -c 'mkdir -p app \
        && cd app \
        && cp -R /src/pubspec.* /src/android /src/lib /src/assets /src/fonts . \
        && flutter pub get \
        && flutter build apk --no-pub'

echo "Copying outputs"
podman cp --overwrite android-build:app/build/app/outputs/apk/release/ .
cp -f release/*.apk .

echo "Cleaning up"
rm -rf release
podman container rm android-build
