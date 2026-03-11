# syntax=docker/dockerfile:1.4
#
# Containerfile for Phylum Development
# 
# Allows for containerized development in case language toolchains
# are not set up locally.


# ============================================
# Stage: Build the API server
# ============================================
FROM docker.io/golang:alpine AS server
WORKDIR /src
COPY server/go.mod server/go.sum .
RUN --mount=type=cache,target=/go/pkg/mod go mod download
COPY server/ .
RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    go build -o /bin/phylum cmd/phylum.go


# ============================================
# Stage: Build the Web App
# ============================================
FROM ghcr.io/cirruslabs/flutter:stable AS webapp
WORKDIR /src
RUN flutter precache --no-universal --web
COPY client/web ./web
COPY client/assets ./assets
COPY client/pubspec.yaml client/pubspec.lock .
RUN --mount=type=cache,target=/root/.pub-cache flutter pub get
COPY client/lib ./lib
RUN --mount=type=cache,target=/root/.pub-cache flutter build web --wasm --debug


# ============================================
# Final Stage: Server
# ============================================
FROM docker.io/alpine:latest AS server
COPY --from=docker.io/shroff12/libreoffice-nogui /libreoffice.apk /tmp/libreoffice.apk
RUN apk add vips-tools vips-poppler font-noto
RUN apk add --allow-untrusted /tmp/libreoffice.apk && rm /tmp/libreoffice.apk
WORKDIR /app
ENV PATH="/app:$PATH"
COPY --from=server /bin/phylum /app/phylum
COPY --from=webapp /src/build/web /app/web
ENTRYPOINT ["phylum"]
CMD ["serve"]
