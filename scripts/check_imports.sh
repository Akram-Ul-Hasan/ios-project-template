#!/bin/sh
# Fails if any AppModules file imports a target that Package.swift doesn't declare as its dependency.
# SwiftPM puts every built module on one search path, so without this an undeclared
# `import AuthData` in a Presentation target can compile (§4, §14).
set -e
root=$(cd "$(dirname "$0")/.." && pwd)
swift build --package-path "$root/Packages/AppModules" --explicit-target-dependency-import-check=error
echo "✔ imports match declared dependencies"
