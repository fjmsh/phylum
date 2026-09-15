#!/bin/bash

set -eu

VERSION="0.10.0"
SRC_URL="https://codeberg.org/shroff/phylum/archive/releases/v$VERSION.tar.gz"
SRC_URL="local"
tag="localhost/phylum:$VERSION"
REGISTRY="docker.io"
IMAGE_NAME="shroff12/phylum"

build_server() {
  declare -n container="$1"
  arch=$2
  c=$(buildah from --platform linux/${arch} docker.io/golang:alpine)
  buildah config --workingdir /src "$c"
  if [ $SRC_URL = "local" ]; then
    echo "Copying source"
    buildah run $c -- mkdir phylum/
    buildah copy $c ./server phylum/server
  else
    echo "Downloading source from $SRC_URL"
    buildah run $c -- wget "$SRC_URL" -O src.tar.gz
    buildah run $c -- tar -zxf src.tar.gz
  fi
  buildah config --workingdir /src/phylum/server "$c"
  buildah run --env GOOS=linux --env GOARCH=${arch} $c -- go build -o /bin/phylum cmd/phylum.go
  container=$c
}

build_webapp() {
  declare -n container="$1"
  c=$(buildah from "ghcr.io/gmeligio/flutter-web:3.47.3")
  buildah config --workingdir /src "$c"
  if [ $SRC_URL = "local" ]; then
    echo "Copying source"
    buildah run $c -- mkdir phylum/
    buildah copy $c ./client phylum/client
  else
    echo "Downloading source from $SRC_URL"
    buildah run $c -- wget "$SRC_URL" -O src.tar.gz
    buildah run $c -- tar -zxf src.tar.gz
  fi
  buildah config --workingdir /src/phylum/client "$c"
  buildah run $c -- flutter pub get
  buildah run $c -- bash dist/web.sh
  container=$c
}

build_phylum() {
  arch=$1
  webapp=$2
  libreoffice_minimal=$3

  echo "Building server"
  build_server server $arch
  echo "Done"

  echo "Building phylum image"
  c=$(buildah from --platform linux/${arch} docker.io/alpine)
  imagepath=$(buildah run $c printenv PATH)
  buildah config --workingdir /var/lib/phylum \
	  --entrypoint '["phylum"]' \
	  --cmd "serve" \
	  --env PATH="$imagepath:/app" \
	  --env PHYLUM_SERVER__WEBAPPSRC="/app/web" \
	  $c
  echo "Installing Packages"
  buildah run $c -- apk add vips-tools vips-poppler font-noto

  if [ $libreoffice_minimal = true ]; then
    echo "Installing Minimal LibreOffice"
    lo=$(buildah from --platform linux/${arch} docker.io/shroff12/libreoffice-nogui)
    lo_mount=$(buildah mount "$lo")
    buildah copy $c "$lo_mount"/libreoffice.apk /tmp/libreoffice.apk
    buildah unmount "$lo"
    buildah run $c -- apk add --allow-untrusted /tmp/libreoffice.apk
    buildah run $c -- rm /tmp/libreoffice.apk
    buildah rm "$lo"
  else
    echo "Installing Full LibreOffice"
    buildah run $c -- apk add libreoffice
  fi

  echo "Copying server binary"
  server_mount=$(buildah mount "$server")
  buildah copy $c "$server_mount"/bin/phylum /app/phylum
  buildah unmount "$server"

  echo "Copying Web App"
  webapp_mount=$(buildah mount "$webapp")
  buildah copy $c "$webapp_mount"/src/phylum/client/build/web /app/web
  buildah unmount "$webapp"

  buildah rm "$server"

  echo "Building image and adding to $tag"
  image=$(buildah commit --rm $c)
  podman manifest add $tag $image
}

cleanup() {
    echo "Script interrupted. Cleaning up..."
    exit 1
}

######################
#### BEGIN SCRIPT ####
######################

# Trap SIGINT (Ctrl+C) and SIGTERM
trap cleanup INT TERM

echo "Creating Manifest $tag"
podman manifest create --amend $tag

echo "Building Web App"
build_webapp webapp
echo "Web App built at $webapp"

echo "Building x86_64 image"
build_phylum amd64 $webapp true

echo "Building aarch64 image"
build_phylum arm64 $webapp false

buildah rm $webapp

echo "Suffessfully created multi-arch build at $tag."
echo "Use the following command to push:"
echo "podman manifest push --all $tag docker://docker.io/shroff12/phylum:$VERSION"
