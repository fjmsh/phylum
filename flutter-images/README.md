Flutter Images
==============

```
# Build Instructions for flutter-web image. Change FLUTTER_VERSION as needed
export FLUTTER_VERSION="3.47.3"
podman build \
    --platform linux/amd64,linux/arm64 \
    --manifest localhost/flutter-web:${FLUTTER_VERSION} \
    --build-arg flutter_version=${FLUTTER_VERSION} \
    --target web \
    .

podman build \
    --platform linux/amd64,linux/arm64 \
    --manifest localhost/flutter-linux:${FLUTTER_VERSION} \
    --build-arg flutter_version=${FLUTTER_VERSION} \
    --target linux \
    .

podman build \
    --platform linux/amd64,linux/arm64 \
    --manifest localhost/flutter-android:${FLUTTER_VERSION} \
    --build-arg flutter_version=${FLUTTER_VERSION} \
    --target android \
    .
```
