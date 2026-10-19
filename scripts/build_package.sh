#!/bin/sh
# Builds the AppModules package for the iOS Simulator (the package is iOS-only, so plain `swift build` targets macOS and fails).
set -e
root=$(cd "$(dirname "$0")/.." && pwd)
cd "$root/Packages/AppModules"
xcodebuild build -quiet -scheme AppModules -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath "$root/.build/DerivedData-package" "$@"
