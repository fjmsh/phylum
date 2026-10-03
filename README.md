<div align="center">
  
[![License: AGPL v3](https://img.shields.io/badge/License-AGPL--3.0--or--later-blue.svg?logo=gnu&style=for-the-badge)](https://www.gnu.org/licenses/agpl-3.0)
[![Matrix Chat](https://img.shields.io/matrix/phylum_cloud%3Amatrix.org?logo=matrix&style=for-the-badge)](https://matrix.to/#/#phylum_cloud:matrix.org)

<img src="https://codeberg.org/shroff/phylum/raw/branch/main/client/dist/graphics/banner-dark.png" width="360px" alt="Phylum Logo">  

</div>

<br />
<br/>

Phylum is a self-hosted cloud file storage platform with offline-first web and native clients, meant as a replacement for Google Drive, Dropbox, etc.

It may be for you if you want:
- [x] To own your data
- [x] A file browser with selective sync
- [x] A fast file manager with native apps - nothing more, nothing less
- [x] To support free software without mixed-licensing or paywalls
- [x] AI-free software
- [x] Something like Immich, but for files
- [ ] Something that is fully baked

Phylum is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version. It is intended to be forever free and non-commercial.


> [!WARNING]  
> While the server is fairly stable, it remains to be battle tested.


- [Features](#features)
- [Quick Start](#quick-start)
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

Open `http://localhost:2448` (or connect to it via an app) to continue setup.

Take a look at [Configuration and Management](https://codeberg.org/shroff/phylum/wiki/Configuration-and-Management) for more details.


## Help and Contributing
The best way to help is to use the app regularly and report bugs.

Reach out on Matrix at [#phylum_cloud:matrix.org](https://matrix.to/#/#phylum_cloud:matrix.org) if you need help to get set up, or want to contribute.


## Screenshots
<figure>
  <a href="https://codeberg.org/shroff/phylum/raw/branch/main/screenshots/ipad-3-light-menu.png">
    <img src="https://codeberg.org/shroff/phylum/raw/branch/main/screenshots/ipad-3-light-menu.png" width="720px" alt="Desktop/Web/Tablet - Light">
  </a>
  <figcaption>Desktop/Web/Tablet - Light</figcaption>
</figure>

<figure>
  <a href="https://codeberg.org/shroff/phylum/raw/branch/main/screenshots/ipad-3-dark-menu.png">
    <img src="https://codeberg.org/shroff/phylum/raw/branch/main/screenshots/ipad-3-dark-menu.png" width="720px" alt="Desktop/Web/Tablet - Dark">
  </a>
  <figcaption>Desktop/Web/Tablet - Dark</figcaption>
</figure>

<figure>
  <a href="https://codeberg.org/shroff/phylum/raw/branch/main/screenshots/iphone-large-1-light-home.png">
    <img src="https://codeberg.org/shroff/phylum/raw/branch/main/screenshots/iphone-large-1-light-home.png" width="300px" alt="Mobile - Light">
  </a>
  <figcaption>Mobile - Light</figcaption>
</figure>

<figure>
  <a href="https://codeberg.org/shroff/phylum/raw/branch/main/screenshots/iphone-large-4-dark-sidebar.png">
    <img src="https://codeberg.org/shroff/phylum/raw/branch/main/screenshots/iphone-large-4-dark-sidebar.png" width="300px" alt="Mobile - Dark">
  </a>
  <figcaption>Mobile - Dark</figcaption>
</figure>
