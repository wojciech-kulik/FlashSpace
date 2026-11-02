#!/bin/sh
set -eu
cd "$(dirname "$0")/../.."
test_binary=$(mktemp -t flashspace-identity)
trap 'rm -f "$test_binary"' EXIT
xcrun swiftc FlashSpace/Extensions/RunningAppIdentity.swift Tests/InstanceIdentity/main.swift -o "$test_binary"
"$test_binary"
