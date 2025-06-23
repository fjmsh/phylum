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
 - File version history
 - Remote storage backends

* Not yet built/tested on MacOS, iOS, and Windows. 

Note: Please do not try to use multiple instances of the same client on one device (i.e. multiple instances of the app). Doing so will result in unexpected behavior, and possibly corrupt local data. It should not, however, have any impact on the remote server or the integrity its data. The web use-case is handled gracefully, though, so there is no need to worry about accidentally opening another tab.

### Permissions

Please be aware of a few things about permissions:

1. There is no concept of resource owners.
2. It is possible to revoke your own permissions from a folder. If you do so, and you are the only one with share permissions on that folder, you will need to use the cli to regain access
3. It is not possible to revoke permissions down a folder tree, i.e. when you grant someone a permission on a folder, you are also doing so for all current and future sub-folders. Of course, you may revoke permissions on the original folder, or grant additional permissions on sub-folder, but you may not revoke permissions only on certain sub-folders.

## Roadmap

Here's the intended initial feature set for a release in the next few months:
 - Auth backends (LDAP, OAuth)
 - In-app user management (update display name/avatar)
 - Easy backup

Other features to follow:
 - Thumbnails and icon view
 - Quota 
 - Links / Shortcuts
 - In-app share notifications
 - Groups
 - Extended resource metadata (media length, etc.)
 - View more files (audio, video, ebooks)
 - Offline sync
 - Sync full directory tree metadata
 - 2-way folder sync

## Deployment / Testing

The easiest way to get up and running is to use docker (or podman) compose and go to `http://localhost:2448`. You must add the first user via CLI using the `admin user invite` command. You may add others as well, or invite them directly from inside the app.

At the very least, you must specify `PHYLUM_DB_PASSWORD` in your `.env` file. See `example.env` for more options. 

Configuration is read from `config.yml`, if it exists. See `config.defaults.yml` for a list of all configuration options.


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

Use the `help` command (or leave out the command) to get a list of options
