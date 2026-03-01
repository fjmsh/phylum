# syntax=docker/dockerfile:1.4
# This Dockerfile builds the custom LibreOffice package for headless document conversion.
# It is designed to be built separately and cached, as it rarely changes and takes a long time to build.
#
# Build: buildah build --platform linux/amd64 -t libreoffice:latest .
# Extract APK: LO=$(buildah from --platform linux/amd64 libreoffice:latest) && cp $(buildah mount $LO)/home/builder/libreoffice.apk ./libreoffice.apk

FROM docker.io/alpine AS libreoffice

RUN apk add alpine-sdk sudo
RUN adduser -G abuild -D builder \
    && echo 'builder ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers

USER builder
WORKDIR /home/builder

RUN abuild-keygen -anq

COPY . .

# Fetch and verify sources (can be cached)
RUN abuild deps

# Build with cache mount for downloaded sources
RUN --mount=type=cache,uid=1000,target="/var/cache/distfiles" \
    abuild fetch verify unpack prepare build

# Package and move to known location
RUN abuild rootpkg && mv ~/packages/home/x86_64/libreoffice-nogui-*.apk ./libreoffice.apk

# Stage to copy out the APK
FROM scratch AS artifact
COPY --from=libreoffice /home/builder/libreoffice.apk /libreoffice.apk
