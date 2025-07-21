Phylum
======

[![License: AGPL v3](https://img.shields.io/badge/License-AGPL_v3-blue.svg)](https://www.gnu.org/licenses/agpl-3.0)
[![Matrix Chat](https://img.shields.io/matrix/phylum_cloud%3Amatrix.org)](https://matrix.to/#/#phylum_cloud:matrix.org)

Phylum is a self-hosted file storage platform with offline-first web and native clients, meant as a replacement for Google Drive, Dropbox, etc. It is licensed under GNU Affero GPL 3.0, and is intended to be forever free and non-commercial.

Fair warning: Phylum is under very active development. Don't even think about putting the only copy of any data that you care about.

- [Features](#features)
- [Quick Start](#quick-start)
- [CLI](#cli)
- [Help](#help)
- [Screenshots](#screenshots)
- [Development](#development)


## Features

- Native clients which are designed to work well with unreliable/no internet connection (*)
- Users and [Permissions](wiki/Permissions)
- [File version history](wiki/Version-History)
- [Remote storage backends](wiki/Content-Storage)
- [Auth backends (LDAP, OIDC)](wiki/User-Authentication)
- [WebDAV access](wiki/WebDAV)
- Publicly share files/folders

*: Not yet built/tested on MacOS, iOS, and Windows. 

## Quick-Start

```
# download compose.yml
wget https://codeberg.org/shroff/phylum/src/branch/main/compose.yml 
# create a new DB password and put it into .env
echo "PHYLUM_DB_PASSWORD=$(head -c 32 /dev/urandom | md5sum | cut -d ' ' -f 1)" > .env
# Create data/config.yml
touch data/config.yml
# Spin it up and start to print the logs
docker compose up -d && docker compose logs -f
```


Once the server is up and running (it may take a minute or so the first time), create a user using the CLI
```
docker exec -it phylum_server phylum admin user create
```

6. Go to `http://localhost:2448`

It is highly recommended to take a look at `config.defaults.yml` to see a full list of configuration options.


## CLI
The CLI is a powerful way to interact with and manage a locally running phylum instance. It also enables many advanced admin use-cases that are not yet possible using the app or API yet. You can run it on docker using
```
$ docker exec -it phylum_server phylum <cmd>
```

Use the `help` command (or leave out the command) to get a list of options

Please note that for `fs` operations, `<path>`s can have a `<uuid>:` prefix to make the path relative to that UUID. This also means that if you know the UUID of the resource, you can simply use `<uuid>:` as the path. If no `<uuid>:` prefix is specified then the path is relative to the root directory, or the home directory of the user if one is specified using the `--user-email` flag.


## Help
Reach out on Matrix at [#phylum_cloud:matrix.org](https://matrix.to/#/#phylum_cloud:matrix.org) if you need help.


## Screenshots

![Desktop Screnshot](https://codeberg.org/shroff/phylum/raw/branch/main/screenshots/desktop.png)

![Mobile Screenshot](https://codeberg.org/shroff/phylum/raw/branch/main/screenshots/mobile.png)

