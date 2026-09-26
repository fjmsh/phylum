Phylum
======

[![License: AGPL v3](https://img.shields.io/badge/License-AGPL_v3-blue.svg)](https://www.gnu.org/licenses/agpl-3.0)
[![Matrix Chat](https://img.shields.io/matrix/phylum_cloud%3Amatrix.org)](https://matrix.to/#/#phylum_cloud:matrix.org)

Phylum is a self-hosted file storage platform with offline-first web and native clients, meant as a replacement for Google Drive, Dropbox, etc. It is licensed under GNU Affero GPL 3.0, and is intended to be forever free and non-commercial.

Phylum may be for you if you want:
- [x] To own your data
- [x] A file browser with selective sync
- [x] A fast file manager with native apps - nothing more, nothing less
- [x] To support free software without mixed-licensing or paywalls
- [x] AI-free software
- [x] Something like Immich, but for files
- [ ] Something that is fully baked


> [!WARNING]  
> This project is under very active development, and no guarantees can be made about stability and backward-compatibility.
> Don't even think about putting the only copy of any data that you care about.


- [Features](#features)
- [Quick Start](#quick-start)
- [CLI](#cli)
- [Help and Contributing](#help-and-contributing)
- [Screenshots](#screenshots)



## Features

- Native clients which are designed to work well with unreliable/no internet connection (*)
- Users and [Permissions](https://codeberg.org/shroff/phylum/wiki/Permissions)
- [File version history](https://codeberg.org/shroff/phylum/wiki/Version-History)
- [Remote storage backends](https://codeberg.org/shroff/phylum/wiki/Content-Storage)
- [Auth backends (LDAP, OIDC)](https://codeberg.org/shroff/phylum/wiki/User-Authentication)
- [WebDAV access](https://codeberg.org/shroff/phylum/wiki/WebDAV)
- Publicly share files/folders

*: Not tested on Windows

## Quick-Start

```
curl -O https://codeberg.org/shroff/phylum/raw/branch/main/compose.yml 
echo "PHYLUM_DB__PASSWORD=$(head -c 32 /dev/urandom | md5sum | cut -d ' ' -f 1)" >> .env
docker compose up -d && docker compose logs -f
```

Open `http://localhost:2448` to continue setup.

Take a look at [Configuration and Management](https://codeberg.org/shroff/phylum/wiki/Configuration-and-Management) for more details about configuration.


## Help and Contributing
Reach out on Matrix at [#phylum_cloud:matrix.org](https://matrix.to/#/#phylum_cloud:matrix.org) if you need help to get set up, or want to contribute.


## Configuration and Management
Configuration is read from from `config.yml` file in the `data/phylum` directory.

It is highly recommended to take a look at `config.defaults.yml` to see a full list of configuration options.

## Screenshots

![Expanded Light](https://codeberg.org/shroff/phylum/raw/branch/main/screenshots/ipad-3-light-menu.png)

![Expanded Dark](https://codeberg.org/shroff/phylum/raw/branch/main/screenshots/ipad-3-dark-menu.png)

![Collapsed Light](https://codeberg.org/shroff/phylum/raw/branch/main/screenshots/iphone-large-1-light-home.png)

![Collapsed Dark](https://codeberg.org/shroff/phylum/raw/branch/main/screenshots/iphone-large-4-dark-sidebar.png)
