#!/bin/bash

podman run --rm -it -v .:/build -v ../../build/:/src:ro appimagecrafters/appimage-builder sh -c 'cd /build && appimage-builder --recipe AppImageBuilder.yml --skip-tests'
