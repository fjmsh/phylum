Phylum
======

[![License: AGPL v3](https://img.shields.io/badge/License-AGPL_v3-blue.svg)](https://www.gnu.org/licenses/agpl-3.0)

![Phylum Logo](https://codeberg.org/shroff/phylum/raw/commit/db7fa8bfe3cd9733e686f60dce74384d29ebc2f1/client/web/icons/icon-192.png)

Phylum is a self-hosted cloud file browser with native clients on all platforms(*), meant as a replacement for Google Drive, Dropbox, etc. It is licensed under GNU Affero GPL 3.0, and is intended to be forever free and non-commercial.

It is in very early stages of testing, so bugs are to be expected. Fair warning: while the backend is quite robust and its data model fairly fixed, don't even think about putting the only copy of any data that you care about.


## Features

 - Offline-first native clients on all platforms (*)
    - Drag and Drop
    - Keyboard navigation and shortcuts on web(+) and desktop
 - Public shares with password protection and expiration
 - Users and permissions
 - WebDAV-compatible
 - File version history
 - Remote storage backends
 - Auth backends (LDAP, OAuth)

*: Not yet built/tested on MacOS, iOS, and Windows. 
+: Not all shortcuts work on web

Note: Please do not try to use multiple instances of the same client on one device (i.e. multiple instances of the app). Doing so will result in unexpected behavior, and possibly corrupt local data. It should not, however, have any impact on the remote server or the integrity its data. The web use-case is handled gracefully, though, so there is no need to worry about accidentally opening another tab.

### Roadmap

Here is a list of what is planned, in rough order:
 - macOS/iOS clients
 - Login via magic link (no password)
 - Grid icon view with thumbnails
 - Links / Shortcuts
 - Version management (auto/manual delete old versions)
 - Bookmark management
 - User management (list, update display name/avatar)
 - Share with all users
 - Background uploads on mobile
 - In-app share notifications
 - Easy db backup
 - Extended metadata (media length, pages, etc.)
 - View more files (audio, video, ebooks)
 - Offline sync
 - Sync full directory tree metadata
 - 2-way folder sync
 - Storage Quota 
 - Groups

## Deployment / Testing

The easiest way to get up and running is to use docker (or podman) compose and go to `http://localhost:2448`.

At the very least, you must specify `PHYLUM_DB_PASSWORD` in your `.env` file. See `example.env` for more options.

Configuration is read from `config.yml`, if it exists. See `config.defaults.yml` for a list of all configuration options.

### CLI

The CLI is a powerful way to interact with and manage a locally running phylum instance. It also enables many advanced admin use-cases that are not yet possible using the app or API yet. You can run it on docker using

Depending on whether you are running the program directly or via compose, you can use either 

```
$ podman exec -it phylum_server ./phylum <cmd>
```

Use the `help` command (or leave out the command) to get a list of options

Please note that for `fs` operations, `<path>`s can have a `<uuid>:` prefix to make the path relative to that UUID. This also means that if you know the UUID of the resource, you can simply use `<uuid>:` as the path. If no `<uuid>:` prefix is specified then the path is relative to the root directory, or the home directory of the user if one is specified using the `--user-email` flag.


### Adding users
There are a few ways to add users:
1. Use the `admin user invite` command

2. Add entries to your `config.yaml` under `auth.auto_create`. The '`*`' wildcard is supported, so you can add something like `"*@domain.com"` (be sure to add the quotes in case your entry starts with a `*`)

3. Invite directly from the app by sharing a file or folder.


#### Permissions

Please be aware of a few things about the permission model:

1. There is no concept of owners.
2. It is possible to revoke your own permissions from a folder. If you do so, and you are the only one with share permissions on that folder, you will need to use the cli to regain access
3. It is not possible to revoke permissions down a folder tree, i.e. when you grant someone a permission on a folder, you are also doing so for all current and future sub-folders. Of course, you may revoke permissions on the original folder, or grant additional permissions on sub-folder, but you may not revoke permissions only on certain sub-folders.



### Auth Backends
Phylum supports multiple login methods. You can support a combination

#### LDAP
There are two ways to configure LDAP. The simplest way is to set `dn_template`, which will substitute `{email}` with the email of the user trying to log in, and try to authenticate with the password provided.
```
dn_template: cn={email},ou=people,dc=example,dc=com
```

Alternatively, if your CN is not the email of the user trying to log in, then you will have to configure `dn_lookup`, which will make a separate round-trip to the server to the LDAP server to find the DN of the user.
```
dn_lookup:
  bind_dn: cn=phylumbind,ou=people,dc=example,dc=com
  bind_password: ldap_password_for_phylumbind_user
  base_dn: dc=example,dc=com
  filter_template: (mail={email})
```

`dn_template` will be preferred if it is not empty, as it is more efficient, and fall back to `dn_lookup`.


#### OpenID (OAuth)

Start by configuring a new **Web** client with your provider, and use the following redirect url: `https://phylum.example.com/api/v1/auth/oauth/redirect`, of course, replacing `phylum.example.com` with your host name.

Once you have configured your client and have your credentials, add an entry to the auth.openid.clients array:
```
id: google        # internal ID, prefer lower-kebab-case or lower_camel_case
name: Google      # to be displayed to the user as 'Log In with <name>'
issuer_url: https://accounts.google.com
client_id:
client_secret:
```

You can add multiple entries to allow logins from multiple providers


### Content Storage
By default, uploaded file contents are be saved to `storage/default` relative to the current directory.

To configure other locations for saving file contents, start by creating a new backend using the `admin storage create` command, then mount that backend at the desired path using `fs mount`. Note: A single backend may be mounted to multiple locations

Mounting a storage backend will only save future uploads to that backend, and not migrate any existing content. Support for that will come soon in a future release.

Currently supported storage drivers are local filesystem and MinIO (S3-compatible, including Wasabi, Backblaze B2, etc.).


### Version History
Phylum retains full version history of all files, allowing preview (if supported for the file type) and download. Currently, it is not possible to delete previous versions, either automtaically or manually. Better version management is a planned feature that will allow you to delete previous versions manually, and configure a retention policy. For now, the only way to get rid of previous versions is to delete the file and upload another one with the same name.


### WebDAV
By default, WebDAV is access is enabled at the `/webdav` location using HTTP Basic authentication. This is not the most efficient, as the server needs to spend resources to verify password for each request.

In order to access files, you need to specify the path root, which is of the form `~<email>`  or `<uuid>`, so the WebDAV path for `user@exmaple.com` will be `/webdav/~user@example.com`. You can, of course, specify a different username or uuid, but that will only work if you have permissions for the requested resource.


### Keyboard shortcuts
Apart from navigation of resource list, including multi-select using <ctrl> or <shift>, here is the list of keyboard shortcuts

| Key Combo    | Action               |
| ------------ | -------------------- |
| Enter/Space  | Open                 |
| Delete       | Send to Trash        |
| Shift+Delete | Permanently Delete   |
| Ctrl+A       | Select All           |
| Ctrl+N       | New Folder           |
| Ctrl+U       | Upload File          |
| Ctrl+Shift+U | Upload Folder        |
| F2/Ctrl+E    | Rename               |
| Ctrl+C       | Copy to clipboard    |
| Ctrl+X       | Cut to clipboard     |
| Ctrl+V       | Paste from clipboard |
| Ctrl+R       | Refresh              |
| Alt+H        | Home                 |
| Alt+S        | Search               |
| Alt+Up       | Go to Parent         |
| Alt+Left     | Go Back              |
| Alt+Right    | Go Forward           |

These shortcuts were tested on linux, many of these don't quite work as expected on web because of default handlers, and are not yet adapted to macOS.

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

To use the CLI, you can use:
```
$ go run -C server cmd/phylum.go -W ../data <cmd>
```

#### API
An OpenAPI document is a work in progress. If you do intend to look around, note that almost all `<path>`s can have a `<uuid>:` prefix to make the path relative to that UUID. This also means that if you know the UUID of the resource, you can simply use `<uuid>:` as the path. This is the recommended way, and is the way the client app uses the API.


### Client

The client is written using Flutter, and building requires no special configuration as long as your toolchian is [set up properly](https://docs.flutter.dev/get-started/). Of course, you will need a running server to connect to.

It is usually easiest to work on the desktop app, and only test on devices/web if needed for platform-specific integration.

#### Web

If you want to work on the web client specifically, then the simplest way is to create a link to the web client build folder from the server's working directory.
```
$ ln -st data ../client/build/web/
```

Please note that the web client must is built with WASM using `flutter build web --wasm`


