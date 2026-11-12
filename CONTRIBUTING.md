This project adheres to the [SciActive Human Contribution Policy 2-TR](HUMAN-CONTRIBUTION-POLICY-2-TR.md).

Phylum is currently a one-man operation with a few contributions from others over years, so I have not yet gone through the overhead of writing architecture or design docs. The code is reasonably well organized into modules, so a good task to pick up (albeit not particularly easy) would be to document the codebase. I am happy to answer questions and assist in the process.


Client
=====
- Install [FVM](https://fvm.app/documentation/getting-started/installation) to make sure you're using the correct version of flutter
- Run the server (build instructions [below](#server))
- Build/run the app using fvm
```
fvm flutter pub get
fvm flutter run -d android
```
Most development can take place on a single platform of your choice (desktop is usually easiest), as only platform-specific features require having to choose that particular platform.

### Building the web app
The web app is built using WASM, so it needs to be built with
```
fvm flutter build web --wasm
```

Server
=====
### Using compose
This is the preferred method if you are not doing any api development and just need an instance running for the client to connect to.
```
podman-compose -f compose.dev.yml up --build
```

### Directly on the local machine
This way is far quicker and easier to iterate on server code, as it doesn't need a docker build. You will still need a database running, which you can spin up using
```
podman-compose -f compose.dev.yml up -d db
```

Make sure you have a `.env` file with `PHYLUM_DB__PASSWORD` set.

To run the server itself, you will need to have the golang toolchain installed. Then you can run the following command  once (per terminal session, or after you modify the file) to read the environment variables:
```
set -a; source .env; set +a
```
and then finally
```
go run -C server cmd/phylum.go  -W ../data/phylum serve
```

This command must be run in the root of the repo 
- `-C server` is effectively doing a `cd server`
- `cmd/phylum.go` is the main entry point
- `-W ../data/phylum` sets the working directory of the app to `data` (`../` since cwd is `server` at this point)
- `serve` is the command to run. Substitute this with another [CLI](cli) command as needed

If you want to do webapp-specific testing, the first build the web app (instructions [above](#building-the-web-app), and set the following environment variable with either an `export` or just for the single command:
```
PHYLUM_SERVER__WEB_APP_SRC=../client/build/web/ go run -C server cmd/phylum.go -W ../data/phylum serve
```

Note that any config changes  need the server to be restarted for those changes to take effect. If those changes are made from inside the app, either during initial setup or via settings, then the server exits, relying on external automatic restarts. If you are running the server with the command above, you will need to run the command again once it exits.
