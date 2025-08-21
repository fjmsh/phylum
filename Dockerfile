FROM golang:alpine as server
WORKDIR /src
COPY server/ .
RUN go build -o /bin/phylum cmd/phylum.go

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
WORKDIR /build
COPY libreoffice-nogui/ .
RUN apk add alpine-sdk
RUN adduser -D builder && addgroup builder abuild && chown -R builder .
RUN su builder -c 'abuild-keygen -a -n -q \
  && abuild deps fetch verify unpack prepare build rootpkg \
  && mv ~/packages/x86_64/libreoffice-nogui-25.2.5.2-r0.apk /build/libreoffice.apk'

FROM alpine
RUN apk add vips-tools vips-poppler font-noto
WORKDIR /app
ENV PATH="/app:$PATH"
COPY --from=libreoffice /build/libreoffice.apk /tmp
RUN apk add --allow-untrusted /tmp/libreoffice.apk && rm /tmp/libreoffice.apk
COPY --from=server /bin/phylum /app/phylum
COPY --from=webapp /src/build/web /app/web
ENTRYPOINT ["phylum"]
CMD ["serve"]
