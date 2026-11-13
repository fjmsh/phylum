<div align="center">
  
[![License: AGPL v3](https://img.shields.io/badge/License-AGPL--3.0--or--later-blue.svg?logo=gnu&style=for-the-badge)](https://www.gnu.org/licenses/agpl-3.0)
[![Matrix Chat](https://img.shields.io/matrix/phylum_cloud%3Amatrix.org?logo=matrix&style=for-the-badge)](https://matrix.to/#/#phylum_cloud:matrix.org)

<img src="https://codeberg.org/shroff/phylum/raw/branch/main/assets/banner-dark.png" width="360px" alt="Phylum Logo">  

<br>

[Features](#features) | [Quick Start](#quick-start) | [Screenshots](#screenshots) | [Contributing](#contributing) | [License](#license)

</div>

<br>
<br>

Phylum is a self-hosted cloud file storage platform, meant as a replacement for Google Drive, Dropbox, etc. While it is very much a work in progress, it has enough features and is reliable enough to be used as a daily driver for storing and accessing personal or archival documents and media that you want access to and/or share with others.

It may be for you if you want a fast and native file manager - nothing more, nothing less. Something like [Immich](https://immich.app), but for files.

It is intended to be forever free and non-commercial with no telemetry, paywalls, or subscriptions, and is proudly committed to being AI-free software.

## Features

- Native clients which are designed to work well with unreliable/no internet connection (*)
- Users and [Permissions](https://codeberg.org/shroff/phylum/wiki/Permissions)
- [File version history](https://codeberg.org/shroff/phylum/wiki/Version-History)
- [Remote storage backends](https://codeberg.org/shroff/phylum/wiki/Content-Storage)
- [Auth backends (LDAP, OIDC)](https://codeberg.org/shroff/phylum/wiki/User-Authentication)
- [WebDAV access](https://codeberg.org/shroff/phylum/wiki/WebDAV)
- Publicly shared files/folders

*: Not tested on Windows

## Quick-Start


### 1. Spin up the server
```
mkdir phylum && cd phylum
curl -O https://codeberg.org/shroff/phylum/raw/branch/main/compose.yml
sh -c "echo \"PHYLUM_DB__PASSWORD=$(head -c 32 /dev/urandom | md5sum | cut -d ' ' -f 1)\" >> .env"
docker compose up -d && docker compose logs -f
```

`docker compose` above can be replaced with `podman compose` or `podman-compose` depending on your setup.


### 2. Proceed with setup
Point your browser to `https://<server-url>:2448`, or connect your app to `https://<server-url>:2448` to continue with instance setup.

> [WARNING]
> Instance setup is not password protected. Do not keep the server running without finishing setup, especially if it open to the internet."

> [NOTE]
> While a valid email address is required for setup, it need not be a real email inbox.
>
> If you do not plan to use email-related functionality, including inviting users, share notifications, password reset, and oidc login, you may provide a fake email address.


### 3. Install Client Apps (Optional)

| Platform | Install via |
| --- | --- |
| Android | <a href="https://f-droid.org/packages/cloud.phylum.drive/"><img src="https://f-droid.org/badge/get-it-on.png" alt="Get it on F-Droid" height="80"></a> <a href="https://apps.obtainium.imranr.dev/redirect?r=obtainium://app/%7B%22id%22%3A%22cloud.phylum.drive%22%2C%22url%22%3A%22https%3A%2F%2Fcodeberg.org%2Fshroff%2Fphylum%22%2C%22author%22%3A%22shroff%22%2C%22name%22%3A%22Phylum%22%2C%22preferredApkIndex%22%3A1%2C%22additionalSettings%22%3A%22%7B%5C%22includePrereleases%5C%22%3Afalse%2C%5C%22includeDrafts%5C%22%3Afalse%2C%5C%22fallbackToOlderReleases%5C%22%3Atrue%2C%5C%22filterReleaseTitlesByRegEx%5C%22%3A%5C%22%5C%22%2C%5C%22invertReleaseTitlesFilter%5C%22%3Afalse%2C%5C%22filterReleaseNotesByRegEx%5C%22%3A%5C%22%5C%22%2C%5C%22invertReleaseNotesFilter%5C%22%3Afalse%2C%5C%22verifyLatestTag%5C%22%3Afalse%2C%5C%22sortMethodChoice%5C%22%3A%5C%22date%5C%22%2C%5C%22useLatestAssetDateAsReleaseDate%5C%22%3Afalse%2C%5C%22releaseTitleAsVersion%5C%22%3Afalse%2C%5C%22versionExtractionRegEx%5C%22%3A%5C%22%5Ereleases%2Fv(.*)%24%5C%22%2C%5C%22matchGroupToUse%5C%22%3A%5C%22%241%5C%22%2C%5C%22versionDetection%5C%22%3Atrue%2C%5C%22releaseDateAsVersion%5C%22%3Afalse%2C%5C%22useVersionCodeAsOSVersion%5C%22%3Afalse%2C%5C%22apkFilterRegEx%5C%22%3A%5C%22%5C%22%2C%5C%22invertAPKFilter%5C%22%3Afalse%2C%5C%22autoApkFilterByArch%5C%22%3Atrue%2C%5C%22minimumUpdateAgeDays%5C%22%3A%5C%22%5C%22%2C%5C%22exemptFromBackgroundUpdates%5C%22%3Afalse%2C%5C%22skipUpdateNotifications%5C%22%3Afalse%2C%5C%22refreshBeforeDownload%5C%22%3Afalse%2C%5C%22detectionDateAsReleaseDate%5C%22%3Afalse%2C%5C%22trackOnly%5C%22%3Afalse%2C%5C%22appName%5C%22%3A%5C%22Phylum%5C%22%2C%5C%22appAuthor%5C%22%3A%5C%22shroff%5C%22%2C%5C%22installerMode%5C%22%3A%5C%22%5C%22%2C%5C%22shizukuPretendToBeGooglePlay%5C%22%3Afalse%2C%5C%22allowInsecure%5C%22%3Afalse%2C%5C%22allowedSigningCertHashes%5C%22%3A%5C%22B4%3A29%3AF1%3ADD%3A24%3ADB%3A2C%3A4D%3A97%3A93%3AFC%3A0E%3AA3%3A21%3A57%3A20%3A64%3A10%3AE9%3A9F%3AED%3AA4%3A2D%3A3C%3A06%3A34%3A10%3A15%3A39%3AC9%3AC5%3AFB%5C%22%2C%5C%22about%5C%22%3A%5C%22Self-Hosted%20Cloud%20Storage%20Platform%5C%22%2C%5C%22updateHealthStaleRelease%5C%22%3A%5C%22%5C%22%2C%5C%22updateHealthStaleVersion%5C%22%3A%5C%22%5C%22%2C%5C%22updateHealthFailedChecks%5C%22%3A%5C%22%5C%22%2C%5C%22updateHealthArchived%5C%22%3A%5C%22%5C%22%2C%5C%22updateHealthFilteredReleases%5C%22%3A%5C%22%5C%22%7D%22%2C%22overrideSource%22%3Anull%7D"><img src="https://codeberg.org/shroff/phylum/raw/branch/main/assets/badges/obtainium.png" alt="Get it on Obtainium" height="80"></a> <a href="https://codeberg.org/shroff/phylum/releases/latest"><img src="https://codeberg.org/shroff/phylum/raw/branch/main/assets/badges/codeberg.png" alt="Get it on Codeberg" height="80"></a> <a href="https://play.google.com/store/apps/details?id=cloud.phylum.drive"><img src="https://codeberg.org/shroff/phylum/raw/branch/main/assets/badges/google_play.png" alt="Get it on Codeberg" height="80"></a>|
| iOS | [TestFlight](https://testflight.apple.com/join/Xnsbywyq) |
| MacOS | <a href="https://codeberg.org/shroff/phylum/releases/latest"><img src="https://codeberg.org/shroff/phylum/raw/branch/main/assets/badges/codeberg.png" alt="Get it on Codeberg" height="80"></a>  |
| Linux | <a href="https://codeberg.org/shroff/phylum/releases/latest"><img src="https://codeberg.org/shroff/phylum/raw/branch/main/assets/badges/codeberg.png" alt="Get it on Codeberg" height="80" /></a>  |

Reach out on Matrix at [#phylum_cloud:matrix.org](https://matrix.to/#/#phylum_cloud:matrix.org) if you need help to get set up, or want to contribute.



## Screenshots
<figure>
  <a href="https://codeberg.org/shroff/phylum/raw/branch/main/assets/screenshots/ipad-3-light-menu.png">
    <img src="https://codeberg.org/shroff/phylum/raw/branch/main/assets/screenshots/ipad-3-light-menu.png" width="720px" alt="Desktop/Web/Tablet - Light">
  </a>
  <figcaption>Desktop/Web/Tablet - Light</figcaption>
</figure>

<figure>
  <a href="https://codeberg.org/shroff/phylum/raw/branch/main/assets/screenshots/ipad-3-dark-menu.png">
    <img src="https://codeberg.org/shroff/phylum/raw/branch/main/assets/screenshots/ipad-3-dark-menu.png" width="720px" alt="Desktop/Web/Tablet - Dark">
  </a>
  <figcaption>Desktop/Web/Tablet - Dark</figcaption>
</figure>

<figure>
  <a href="https://codeberg.org/shroff/phylum/raw/branch/main/assets/screenshots/iphone-large-1-light-home.png">
    <img src="https://codeberg.org/shroff/phylum/raw/branch/main/assets/screenshots/iphone-large-1-light-home.png" width="300px" alt="Mobile - Light">
  </a>
  <figcaption>Mobile - Light</figcaption>
</figure>

<figure>
  <a href="https://codeberg.org/shroff/phylum/raw/branch/main/assets/screenshots/iphone-large-4-dark-sidebar.png">
    <img src="https://codeberg.org/shroff/phylum/raw/branch/main/assets/screenshots/iphone-large-4-dark-sidebar.png" width="300px" alt="Mobile - Dark">
  </a>
  <figcaption>Mobile - Dark</figcaption>
</figure>


## Contributing
This project adheres to the [SciActive Human Contribution Policy 2-TR](HUMAN-CONTRIBUTION-POLICY-2-TR.md).

<img src="https://codeberg.org/shroff/phylum/raw/branch/main/assets/badges/seal_of_human_authorship.svg" alt="Seal of Human Authorship" height="300">

For more information about how to contribute, see [CONTRIBUTING.md](CONTRIBUTING.md)


## License
This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as
published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

A copy of the GNU Affero General Public License can be found
[with the source code](https://codeberg.org/shroff/phylum/raw/branch/main/LICENSE)
and at [https://www.gnu.org/licenses/](https://www.gnu.org/licenses/).

