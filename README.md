Phylum
======

![Phylum Logo](https://codeberg.org/shroff/phylum/raw/commit/db7fa8bfe3cd9733e686f60dce74384d29ebc2f1/client/web/icons/icon-192.png)

Phylum is a self-hosted cloud file browser with native clients on all platforms(*), meant as a replacement for Google Drive, Dropbox, etc.

It is in very early stages of testing, so bugs are to be expected. While the backend is quite robust and its data model fairly fixed, don't even think about putting the only copy of any data that you care about.


### Features

 - Offline-first native clients on all platforms (*)
 - Public shares
 - Users and permissions
 - WebDAV-compatible server
 - Jailed users

* Not yet built/tested on MacOS, iOS, and Windows. 

### Roadmap

In no particular order, here are some things that are planned

 - User management
 - Storage backends like S3, B2, Minio, etc. (partially implemented)
 - Thumbnails and grid view
 - Auth backends (LDAP, OAuth)
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

```
$ podman run -it -e POSTGRES_USER=phylum -e POSTGRES_PASSWORD=phylum -v ./data/db:/var/lib/postgresql/data docker.io/postgres:17
$ PHYLUM_DB_PASSWORD=phylum go run -C server cmd/phylum.go -W .. serve
```

`-W ..` will ensure that all paths are relative to the root directory of this repo, so the default storage won't end up inside the server source.

#### Client

The client is written using Flutter, and building requires no special configuration as long as your toolchian is [set up properly](https://docs.flutter.dev/get-started/). Of course, you will need a running server to connect to.

It is usually easiest to work on the desktop app, and only test on devices/web if needed for platform integration.

##### Web

If you want to work on the web app using `flutter run`, then you will need to enable CORS on the server. This can be done by either passing in the `--cors-enabled` flag or by setting `PHYLUM_SERVER_CORS_ENABLED=1`. This is not required for mobile/desktop clients.
```
$ PHYLUM_DB_PASSWORD=phylum go run -C server cmd/phylum.go -W .. --web-app-dir client/build/web serve --cors-enabled
```

#### Creating a user

There is currently no interface for user management, so all users have to be added by cli. You will need to do this at least once initially to set up the first user.

If you're already using compose, you can just run

```
podman exec -it phylum_server ./phylum user add <username>
```

