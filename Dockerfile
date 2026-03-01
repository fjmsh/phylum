# syntax=docker/dockerfile:1.4
# Main Dockerfile for Phylum
#
# Usage:
#   buildah build --platform linux/amd64 -t phylum:latest-amd64 .
#   buildah build --platform linux/arm64 --target phylum-lofull -t phylum:latest-arm64 .
#
# The LibreOffice APK is pulled from a pre-built image.
# To build LibreOffice locally, use Dockerfile.libreoffice first.

# ============================================
# Stage: Build the Go server
# ============================================
FROM docker.io/golang:alpine AS server
ARG TARGETARCH
WORKDIR /src
COPY server/ .
RUN GOOS=linux GOARCH=${TARGETARCH} go build -o /bin/phylum cmd/phylum.go

# ============================================
# Stage: Build the Flutter webapp
# ============================================
FROM ghcr.io/cirruslabs/flutter:stable AS webapp
WORKDIR /src
RUN flutter precache --no-universal --web
COPY client/pubspec.yaml client/pubspec.lock .
COPY client/lib ./lib
COPY client/web ./web
COPY client/assets ./assets
RUN flutter pub get
RUN flutter build web --wasm

# ============================================
# Final Stage A: Phylum with full LibreOffice
# ============================================
FROM docker.io/alpine AS phylum-lofull
RUN apk add vips-tools vips-poppler font-noto libreoffice
WORKDIR /app
ENV PATH="/app:$PATH"
COPY --from=server /bin/phylum /app/phylum
COPY --from=webapp /src/build/web /app/web
ENTRYPOINT ["phylum"]
CMD ["serve"]

# ============================================
# Final Stage B: Phylum with custom LibreOffice
# ============================================
FROM docker.io/alpine AS phylum
COPY --from=docker.io/shroff12/libreoffice-nogui /libreoffice.apk /tmp/libreoffice.apk
RUN apk add vips-tools vips-poppler font-noto
RUN apk add --allow-untrusted /tmp/libreoffice.apk && rm /tmp/libreoffice.apk
WORKDIR /app
ENV PATH="/app:$PATH"
COPY --from=server /bin/phylum /app/phylum
COPY --from=webapp /src/build/web /app/web
ENTRYPOINT ["phylum"]
CMD ["serve"]
