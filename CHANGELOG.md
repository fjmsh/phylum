v0.10 (Unreleased)
=====

> [!WARNING]
> Breaking changes:
> - Fix config overrides not working for keys with underscores (breaking: use `__` instead of `_` to delimit env vars, and `.` instead of `_` to delimit command line flags)
> - Update some config keys
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

Fixes:
- Properties not showing on small screens
- Show selected items on large screens
- mp4 audio files sometimes incorrectly tagged as video/mp4
- LDAP config during setup
- System theme (light/dark) not being respected


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
