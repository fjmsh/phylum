#!/bin/bash

set -eo pipefail

if [ $# -lt 1 ]; then
	echo "Usage: $0 <version>"
	exit 1
fi

echo "Building App"
pushd ../..
flutter build macos

rm -rf dist/macos/Phylum\ Drive.app && mv -f build/macos/Build/Products/Release/Phylum\ Drive.app dist/macos
codesign --verbose --force --deep \
    --sign "Developer ID Application: Abhishek Shroff (8H4PYGEL97)" \
    --options runtime \
    --timestamp \
    --entitlements "macos/Runner/Release.entitlements" \
    dist/macos/Phylum\ Drive.app
popd

echo
echo "Notarizing App"
ditto -c -k --keepParent Phylum\ Drive.app app.zip
xcrun notarytool submit app.zip --keychain-profile "notary-profile" --wait
rm -rf app.zip
xcrun stapler staple Phylum\ Drive.app
xcrun stapler validate Phylum\ Drive.app

version=$1
dmg="Phylum Drive-${version}.dmg"

echo
echo "Building DMG"
rm -rf "$dmg"
appdmg config.json "$dmg"

echo
echo "Notarizing DMG"
xcrun notarytool submit "$dmg" --keychain-profile "notary-profile" --wait
xcrun stapler staple "$dmg"
xcrun stapler validate "$dmg"
spctl --assess --type open --context context:primary-signature --verbose=4 "$dmg"

echo
echo "Built $dmg"
