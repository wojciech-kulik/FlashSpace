#!/bin/bash

NEW_VERSION=$(grep "MARKET" ../project.yml | tr -d ' ' | sed 's/MARKETING_VERSION://g')
echo "Bumping to version $NEW_VERSION"

SHA=$(shasum -a 256 ../.build/FlashSpace.app.zip | cut -d ' ' -f 1)
echo "SHA256: $SHA"

cd ../../homebrew-tap
sed -i '' "s/version \"[^\"]*\"/version \"$NEW_VERSION\"/g" Casks/flashspace.rb
sed -i '' "s/sha256 \"[^\"]*\"/sha256 \"$SHA\"/g" Casks/flashspace.rb

git add Casks/flashspace.rb
git commit -m "bump FlashSpace to $NEW_VERSION"
