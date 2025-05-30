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

FROM alpine
WORKDIR /app
COPY --from=server /bin/phylum /app/phylum
COPY --from=webapp /src/build/web /app/web
ENTRYPOINT ["/app/phylum"]
CMD ["serve"]
