Phylum
======

[![License: AGPL v3](https://img.shields.io/badge/License-AGPL_v3-blue.svg)](https://www.gnu.org/licenses/agpl-3.0)

![Phylum Logo](https://codeberg.org/shroff/phylum/raw/commit/db7fa8bfe3cd9733e686f60dce74384d29ebc2f1/client/web/icons/icon-192.png)

Phylum is a self-hosted cloud file browser with native clients on all platforms(*), meant as a replacement for Google Drive, Dropbox, etc. It is licensed under GNU Affero GPL 3.0, and is intended to be forever free and non-commercial.

It is in very early stages of testing, so bugs are to be expected. Fair warning: while the backend is quite robust and its data model fairly fixed, don't even think about putting the only copy of any data that you care about.


## Features

 - Offline-first native clients on all platforms (*)
    - Drag and Drop
    - Keyboard navigation and shortcuts on web and desktop
 - Public shares with password protection and expiration
 - Users and permissions
 - WebDAV-compatible

* Not yet built/tested on MacOS, iOS, and Windows. 

## Roadmap

In rough order, here are some things that are planned

 - Thumbnails and icon view
 - Email share notifications
 - In-app user management (update display name/avatar)
 - Quota 
 - Links / Shortcuts
 - Storage backends like S3, B2, Minio, etc. (partially implemented)
 - Auth backends (LDAP, OAuth)
 - Groups
 - Offline single file sync
 - Sync full directory tree metadata
 - 2-way folder sync


## Deployment / Testing

The easiest way to get up and running is to use docker (or podman) compose go to `http://localhost:2448`.

Configuration is read from `config.yml`, if it exists. Any config item can be overridden via environment variables and command-line flags, with '_' separating nested keys, and a`'PHYLUM_' prefix for env.

See `config.defaults.yml` to see a list of all configuration options, and `example.env` for some common overrides.

You must add the first user using the CLI using the `admin user invite` command. You may add others as well, or invite them directly from inside the app.

## Development

### Server

The server is written in Go, and requires a postgres server to be running.

```
$ podman run -it \
    -e POSTGRES_USER=phylum \
    -e POSTGRES_PASSWORD=<password> \
    -v ./data/postgres:/var/lib/postgresql/data \
    docker.io/postgres:17
```

The working directory can be changed by passing in the `-W` flag, which is useful for local development. The `data` folder in the repo root is intended to be the working directory for local development, and is ignored by git.

Add your db password to `data/config.yml`, and run the server:
```
$ go run -C server cmd/phylum.go -W ../data serve
```

### Client

The client is written using Flutter, and building requires no special configuration as long as your toolchian is [set up properly](https://docs.flutter.dev/get-started/). Of course, you will need a running server to connect to.

It is usually easiest to work on the desktop app, and only test on devices/web if needed for platform-specific integration.

#### Web

If you want to work on the web client specifically, then the simplest way is to create a link to the web client build folder from the server's working directory.
```
$ ln -st data ../client/build/web/
```

Please note that the web client must is built with WASM using `flutter build web --wasm`


## CLI

The CLI is a powerful way to interact with and manager a locally running phylum instance. It also enables some admin use-cases that are not possible using the app or API yet.

Depending on whether you are running the program directly or via compose, you can use either 

```
$ go run -C server cmd/phylum.go -W ../data <cmd>
```
or
```
$ podman exec -it phylum_server ./phylum <cmd>
```

