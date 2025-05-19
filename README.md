Phylum
======

[![License: AGPL v3](https://img.shields.io/badge/License-AGPL_v3-blue.svg)](https://www.gnu.org/licenses/agpl-3.0)

![Phylum Logo](https://codeberg.org/shroff/phylum/raw/commit/db7fa8bfe3cd9733e686f60dce74384d29ebc2f1/client/web/icons/icon-192.png)

Phylum is a self-hosted cloud file browser with native clients on all platforms(*), meant as a replacement for Google Drive, Dropbox, etc. It is licensed under GNU Affero GPL 3.0, and is intended to be forever free and non-commercial.

It is in very early stages of testing, so bugs are to be expected. Fair warning: while the backend is quite robust and its data model fairly fixed, don't even think about putting the only copy of any data that you care about.


### Features

 - Offline-first native clients on all platforms (*)
 - Public shares
 - Users and permissions
 - WebDAV-compatible server

* Not yet built/tested on MacOS, iOS, and Windows. 

### Roadmap

In no particular order, here are some things that are planned

 - User management (invite, change/reset password, update display name/avatar)
 - Storage backends like S3, B2, Minio, etc. (partially implemented)
 - Thumbnails and icon view
 - Auth backends (LDAP, OAuth)
 - Demo instance
 - Email notifications
 - Links / Shortcuts
 - Directory quota 
 - User Groups
 - Offline single file sync
 - Sync full directory tree metadata
 - 2-way folder sync


### Development / Testing

The easiest way to get up and running is to use docker (or podman) compose go to `http://localhost:2448`.


#### Server

The server is written in Go, and requires a postgres server to be running.

Config is read in from a `config.yml`, if it exists. Configurations can be overridden via command-line flags, and environment variables, with '_' separating nested keys, and a`'PHYLUM_' prefix for env.

The working directory can be changed by passing in the `-W` flag, which is useful for local development. The `data` folder in the repo root is intended to be the working directory for local development, and is ignored by git.

Add the following lines to `data/config.yml`:
```
db:
  password: <password>
```

And then

```
$ podman run -it \
    -e POSTGRES_USER=phylum \
    -e POSTGRES_PASSWORD=<password> \
    -v ./data/postgres:/var/lib/postgresql/data \
    docker.io/postgres:17
$ go run -C server cmd/phylum.go -W ../data serve
```


#### Client

The client is written using Flutter, and building requires no special configuration as long as your toolchian is [set up properly](https://docs.flutter.dev/get-started/). Of course, you will need a running server to connect to.

It is usually easiest to work on the desktop app, and only test on devices/web if needed for platform integration.

##### Web

If you want to work on the web app, then you will need to enable CORS on the server, and/or point the server to serving the locally built copy. The easiest way to do this is to add the following lines to your `config.yml`.
```
server:
  webappsrc: ../client/build/web
  cors:
    enabled: true
```
The compose container will not read this config, so if you only want to work on web app development without modifying the server then you can set `PHYLUM_SERVER_CORS_ENABLED=1` in your environment.

All of this is not required for mobile/desktop clients.

#### Creating a user

There is currently no interface for user management, so all users have to be added by cli. You will need to do this at least once initially to set up the first user.

If you're already using compose, you can just run:

```
$ podman exec -it phylum_server ./phylum user add <email>
```
Otherwise, for local development:
```
$ go run -C server cmd/phylum.go -W ../data user add <email>
```
