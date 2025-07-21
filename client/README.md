## Phylum Client

The Phylum client is written using Flutter, and building requires no special configuration as long as your toolchain is [set up properly](https://docs.flutter.dev/get-started/). Of course, you will need a running server to connect to.

It is usually easiest to work on the desktop app, and only test on devices/web if needed for platform-specific integration.

`flutter run -d macos/linux/web/pixel`

#### Web

If you want to work on the web client specifically, then the simplest way is to create a link to the web client build folder from the server's working directory, and then run the server, which will serve the app.
```
$ ln -st data ../client/build/web/
```

Please note that the web client must be built with WASM using `flutter build web --wasm`
