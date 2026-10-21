# ios-project-template

TechnoNext's starting point for iOS apps: feature-first Clean Architecture with SwiftUI + MVVM, Swift 6 strict
concurrency, iOS 17+, and **no third-party dependencies**. It ships working reference features (login, a paged
product catalog with an offline cache, settings) that show every pattern end to end.

## Setup

Requirements: macOS with **Xcode 27.1** (pinned in `.xcode-version`; `setup.sh` and CI check it).

```sh
git clone <repo-url> && cd ios-project-template
./setup.sh                       # installs the git hooks (core.hooksPath) and checks the Xcode version
open ios-project-template.xcodeproj
```

Pick the **ProjectTemplate-Development** scheme and run. Development uses bundled mock JSON, so it works with no
backend: sign in with any valid Bangladeshi mobile number (e.g. `01712345678`) and any password; the password
`wrong` shows the server-error path.

## Flavors

| Scheme | Configs | Bundle id | Data | Pinning | Diagnostics |
|---|---|---|---|---|---|
| ProjectTemplate-Development | Debug-Development | `….dev` | mock JSON (`App/Resources/Mock`) | off | logs, export |
| ProjectTemplate-Staging | Debug-Staging / Release-Staging | `….stg` | staging API | on | logs, export |
| ProjectTemplate-Production | Release-Production | base id | production API | on | off |

Per-flavor values live in `Config/<Flavor>.xcconfig` (on top of `Config/Base.xcconfig`) and reach the code through
`App/Resources/Info.plist` → `Env`:

| Setting | Meaning |
|---|---|
| `APP_ENV` | `development` / `staging` / `production` |
| `BASE_URL` | API base URL (`https:/$()/…`: `$()` stops `//` being read as a comment) |
| `PINNED_PUBLIC_KEY_HASHES` | base64 SHA-256 of the API host's public keys, primary + backup (staging/production) |
| `ASSOCIATED_DOMAIN` | universal-link host |
| `APP_DISPLAY_NAME`, `BUNDLE_ID_SUFFIX` | home-screen name, bundle id suffix |

Only public values belong in xcconfig: anything shipped in the app is extractable. Local overrides go in an
untracked `*.secrets.xcconfig`. Mock fixtures (`*.mock.json`) are excluded from every non-development build.

## Starting a new app from the template

1. Rename: target/module `ProjectTemplate` → your app name (letters and digits only), `BASE_BUNDLE_IDENTIFIER` in
   `Config/Base.xcconfig`, `PRODUCT_NAME`, display names, the URL scheme (`Info.plist` + `DeepLinkConstants`), the
   background task ids (`Info.plist` + `BackgroundTaskID`) and the keychain/subsystem defaults.
2. Fill in per-flavor `BASE_URL`, `PINNED_PUBLIC_KEY_HASHES`, `ASSOCIATED_DOMAIN`, and the App Store id in
   `App/Root/BlockingView.swift`.
3. Replace the colour sets in `DesignSystem/Resources/Colors.xcassets` and the tokens in `DesignSystem/Theme` with
   the Figma values; set `AppTypography.fontFamily` and add the font files if the design uses a custom font.
4. Remove permissions you don't use (`AppPermission`, `Info.plist`, `InfoPlist.xcstrings`) and keep
   `App/Resources/PrivacyInfo.xcprivacy` accurate.
5. Enable the capabilities on the App ID: Push Notifications, Associated Domains, App Attest, Data Protection.
6. Replace the placeholder screens (`App/Placeholder`) with real features: `scripts/create_feature.sh <Name>`.

## Everyday commands

```sh
scripts/create_feature.sh OrderHistory     # new feature: targets, tests, container, fixture, string
swift test --package-path Packages/AppModules
scripts/test_package.sh                    # package tests on the iOS Simulator
xcrun simctl push booted scripts/push/order.apns
```

See `CLAUDE.md` for the full command list, rules and component catalog.
