Stripped down version of LibreOffice suitable for document conversion on a headless server.

The recipe is adapted from [aports](https://gitlab.alpinelinux.org/alpine/aports/-/tree/master/community/libreoffice) and modified to remove support for additional languages, and as many features as possible while still getting it to build and work as expected.

Please note that no fonts are bundled with this package, and are not added as dependencies to allow for maximum flexibility, so you must install some on the system.
