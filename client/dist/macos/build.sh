#!/bin/bash

set -eo pipefail

if [ $# -lt 1 ]; then
	echo "Usage: $0 <version>"
	exit 1
fi

version=$1
dmg="Phylum Drive-${version}.dmg"

echo "Building DMG"
appdmg config.json "$dmg"

echo
echo "Submitting DMG for Notarization"
xcrun notarytool submit "$dmg" --keychain-profile "notary-profile" --wait

echo
echo "Stapling Notarization Ticket"
xcrun stapler staple "$dmg"

echo
echo "Validating Notarization Ticket"
xcrun stapler validate "$dmg"

echo
echo "Built $dmg"
