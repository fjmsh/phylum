## Tag the release
```
git tag releases/v<version>
git push --tags
```

## Bump Versions

- server/internal/command/command.go
- client/pubspec.yaml (flutter pub get)
- client/dist/appimage/AppImageBuilder.yml
- client/dist/arch/phylum-drive/PKGBUILD

## Build and Publish Server Images
```
podman manifest create phylum:<version>

podman build --platform linux/amd64 --target phylum --tag localhost/phylum:<version>-amd64.
podman manifest add phylum:<version> containers-storage:localhost/phylum:<version>-amd64

podman build --platform linux/arm --target phylum-lofull --tag localhost/phylum:<version>-arm.
podman manifest add phylum:<version> containers-storage:localhost/phylum:<version>-arm64

podman manifest push --all localhost/phylum:<version> docker://docker.io/shroff12/phylum:<version>
```

## Build Clients

### Android
```
flutter build apk
```
Consider using `--split-per-abi`later

### Linux AppImage
1. Build the linux client

```
flutter build linux --release
```

2. Build the AppImage
```
cd dist/appimage && ./build.sh
```

### ArchLinux PKGBUILD
