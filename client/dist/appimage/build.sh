#!/bin/bash

set -euo pipefail

echo "Removing old build container"
podman container rm linux-build || true

APP_VERSION=$(git describe --tags | sed 's/releases\/v//g')
echo "Building AppImage v${APP_VERSION}"
podman run --name linux-build -it \
	-v ../../:/src:ro docker.io/shroff12/flutter-linux:3.47.3 \
	sh -c 'mkdir app \
		&& cd app \
		&& cp -R /src/pubspec.* /src/linux/ /src/lib /src/assets /src/fonts . \
		&& flutter build linux'

podman cp --overwrite linux-build:app/build/linux/x64/release .

echo "Building AppImage"
podman container rm appimage-build || true
podman run --name appimage-build -it \
	-e APP_VERSION=${APP_VERSION} \
	-v ./:/src:ro appimagecrafters/appimage-builder \
	sh -c 'mkdir -p /build \
		&& cd /build \
		&& cp -r /src/release /src/phylum-drive.png /src/AppImageBuilder.yml . \
		&& appimage-builder --recipe AppImageBuilder.yml --skip-tests \
		&& mkdir -p appimage \
		&& cp *.AppImage appimage'

podman cp appimage-build:/build/appimage .
mv appimage/* .

echo "Cleaning Up"
podman container rm linux-build
podman container rm appimage-build
rm -rf release
rm -rf appimage

