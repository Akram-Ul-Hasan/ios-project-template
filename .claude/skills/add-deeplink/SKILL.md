---
name: add-deeplink
description: Make a screen openable from a push notification, universal link or the URL scheme. Use when a screen must be reachable from outside the app.
---

# Add a deep link

1. `App/DeepLink/DeepLink.swift`: add a case; map it to its `tab`, full `routes` stack (so Back is natural) and
   `requiresAuth`.
2. `App/DeepLink/DeepLinkParser.swift`: add the path to `link(from:)`. Validate every id with `validID`. Links only
   navigate: never perform an action (pay, delete) from a link.
3. If it's a new screen: a `Route` case in `App/Route/Route.swift` and its mapping in `App/Route/RouteView.swift`.
4. Tests in `AppTests/DeepLinkParserTests.swift`: the scheme form, the universal-link form, and rejected variants
   (bad id, extra segments, foreign host).
5. Add a sample payload `scripts/push/<name>.apns` with `"deeplink": "projecttemplate://..."`.
6. Universal links need the host in `DeepLinkConstants.universalLinkHosts` and `ASSOCIATED_DOMAIN` (xcconfig), and
   the server's `apple-app-site-association`.
7. Try it: `xcrun simctl openurl booted "projecttemplate://..."` and `xcrun simctl push booted scripts/push/<name>.apns`.
