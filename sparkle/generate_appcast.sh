#!/bin/bash

DATE="$(date "+%a, %d %b %Y %H:%M:%S %z")"
VERSION="$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" ../.build/FlashSpace.app/Contents/Info.plist)"
BUILD="$(/usr/libexec/PlistBuddy -c "Print CFBundleVersion" ../.build/FlashSpace.app/Contents/Info.plist)"
SIGNATURE="$(../.build/derivedData/SourcePackages/artifacts/sparkle/Sparkle/bin/sign_update ../.build/FlashSpace.app.zip)"

TEMPLATE="../sparkle/appcast-template.xml"
OUTPUT="../sparkle/appcast.xml"

rm -f $OUTPUT
cp "$TEMPLATE" "$OUTPUT"
sed -i '' \
  -e "s/#version#/$VERSION/g" \
  -e "s/#build#/$BUILD/g" \
  -e "s/#date#/$DATE/g" \
  $OUTPUT

awk -v sig="               $SIGNATURE" 'NR==16 {$0=sig} {print}' $OUTPUT >$OUTPUT.tmp &&
  mv -f $OUTPUT.tmp $OUTPUT
