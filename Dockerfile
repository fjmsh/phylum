# syntax=docker/dockerfile:1.4
ARG TARGETPLATFORM
ARG TARGETARCH

FROM golang:alpine as server
WORKDIR /src
COPY server/ .
RUN GOOS=linux GOARCH=${TARGETARCH} go build -o /bin/phylum cmd/phylum.go

FROM ghcr.io/cirruslabs/flutter:stable AS webapp
WORKDIR /src
RUN flutter precache --no-universal --web
COPY client/pubspec.yaml client/pubspec.lock .
COPY client/lib ./lib
COPY client/web ./web
COPY client/assets ./assets
RUN flutter pub get
RUN flutter build web --wasm

FROM alpine as libreoffice
RUN apk add alpine-sdk sudo
RUN adduser -G abuild -D builder \
    && echo 'builder ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers
USER builder
WORKDIR /home/builder
RUN abuild-keygen -anq
COPY libreoffice-nogui/ .
RUN abuild deps
RUN --mount=type=cache,uid=1000,target="/var/cache/distfiles" abuild fetch verify unpack prepare build
RUN abuild rootpkg && mv ~/packages/home/x86_64/libreoffice-nogui-*.apk ./libreoffice.apk

FROM alpine AS phylum-lofull
RUN apk add vips-tools vips-poppler font-noto libreoffice
WORKDIR /app
ENV PATH="/app:$PATH"
COPY --from=server /bin/phylum /app/phylum
COPY --from=webapp /src/build/web /app/web
ENTRYPOINT ["phylum"]
CMD ["serve"]

FROM alpine AS phylum
RUN apk add vips-tools vips-poppler font-noto
WORKDIR /app
ENV PATH="/app:$PATH"
COPY --from=libreoffice /home/builder/libreoffice.apk /tmp
RUN apk add --allow-untrusted /tmp/libreoffice.apk && rm /tmp/libreoffice.apk
COPY --from=server /bin/phylum /app/phylum
COPY --from=webapp /src/build/web /app/web
ENTRYPOINT ["phylum"]
CMD ["serve"]
