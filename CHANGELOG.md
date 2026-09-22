v0.10 (Unreleased)
=====

> [!WARNING]
> Breaking changes:
> - Use `__` instead of `_` to separate config via env vars, and `.` instead of `_` to delimit command line flags
> - Update config keys
>   - server.webappsrc => server.web_app_src
>   - server.publinkpath => server.publink_path
>   - server.logbody => server.log_body
> - Change storage structure for files and image previews (requires manual migration for existing data - See notes below)

Features:
- Generate thumbnails for audios (if present) videos and epubs
- Better web loading screen
- Working Dark theme
- Auth config
- Setup and app settings config respects preset and fixed values (via environment vars)
- OIDC auto login if only one method is configured


Improvements:
- Use vips bindings to generate thumbnails and image previews instead of spawning a new process
- Tons uf UI polish

Fixes:
- Properties not showing on small screens
- Show selected items on large screens
- mp4 audio files sometimes incorrectly tagged as video/mp4
- LDAP config during setup
- System theme (light/dark) not being respected

### Migrations

#### Migrate Directory Structure
The directory structure of storage and previews has changed. Run the `admin migrate img <dir>`
and `admin migrate localstorage` commands to migrate data to this new structure. If you are using
podman (or docker), you can use the following commands:
```
podman-compose run --rm server admin migrate img previews
podman-compose run --rm server admin migrate localstorage
```

#### Get new `compose.yml`
Because of the change in environment variable naming scheme, `compose.yml` has been updated. Get the
latest from [](https://codeberg.org/shroff/phylum/releases/download/releases%2Fv0.10.0/compose.yml)

#### Update `.env`
Use `__` instead of `_` to separate environment variable names. At the very least, rename
`PHYLUM_DB_PASSWORD` => `PHYLUM_DB__PASSWORD`.






v0.9
====
This is a major release that addresses many quality of life issues for setting up and using Phylum as a daily driver.

> [!WARNING]
> There are breaking changes in this release. Please look at the release notes before upgrading.

Of notable mention:
- Instance setup on first-run
- In-app user management
- User permissions
- Improved login flow
- Restyled public shares page
- Better properties dialog
- Fixed UUID generation on web


v0.8
====
This release focuses primarily on feature stability.

Among the issues fixed are:
- Deleting bookmarks when the associated resources are deleted
- Restoring from trash
- Emptying trash
- Thumbnail generation
- Auto-renaming files


v0.7
====
- arm64 server build
- Add support for chunked/resumable uploads
- [android] Don't crash on uploading large files
- [web] Upload folders (Chrome only)
- [linux] Provide AppImage binary and PKGBUILD for ArchLinux
- [linux] OAuth


v0.6
====

- Delete single resource version
- Previews for images, office documents and PDFs.
- Grid view with thumbnails
- Editing API Key description
- Revoke API keys
- Record last use info (timestamp, IP, device) for API keys

v0.5
====

**Server**
- Add support for revokable scoped API Keys
- Hash keys and tokens before storing in DB
- PKCE challenge support for OIDC logins (Thanks @gbw)
- Fix WebDAV access with uuid root
- DB schema improvements
- Magic link login
- Simpler default password requirements

**Client**
- Edit Display Name
- Change Password
- Better Login UI
