# CLAUDE.md

TechnoNext iOS template: feature-first Clean Architecture in SwiftUI + MVVM. Swift 6 language mode (strict concurrency),
iOS 17+, Xcode 27.1 (`.xcode-version`). **No third-party packages**: Apple frameworks only.

- App target `ProjectTemplate` (`App/`) is a thin shell: DI containers, router, deep links, root flow.
- All real code is in the local package `Packages/AppModules`, one SPM target per layer per feature, so layer
  boundaries are enforced by the build, not by review.
- Flavors: `ProjectTemplate-Development` (mock JSON, no network), `-Staging`, `-Production`.

## Commands

```sh
./setup.sh                                   # git hooks (core.hooksPath) + Xcode version check
scripts/create_feature.sh OrderHistory       # scaffold Domain/Data/Presentation + tests + container + fixture

# Build
xcodebuild build -project ios-project-template.xcodeproj -scheme ProjectTemplate-Development \
  -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO
scripts/build_package.sh                     # package only, iOS Simulator

# Test
swift test --package-path Packages/AppModules          # fast, macOS host (package compiles for macOS too)
scripts/test_package.sh                                # package tests on the iOS Simulator (IOS_SIMULATOR="iPhone 17")
xcodebuild test -project ios-project-template.xcodeproj -scheme ProjectTemplate-Development \
  -destination 'platform=iOS Simulator,name=iPhone 17' -collect-test-diagnostics never   # everything incl. AppTests

# Checks (also run by pre-commit / pre-push / CI)
swift format lint --strict --recursive App AppTests Packages/AppModules   # fix: swift format format -i <file>
scripts/check_target_graph.sh                # Package.swift edges vs the allowed table below
scripts/check_imports.sh                     # every import is a declared dependency
scripts/banned_api_check.sh                  # print, try!, force unwrap, UserDefaults.standard, AsyncImage …

xcrun simctl push booted scripts/push/order.apns   # push → deep link
```

Run **preflight** before every MR: format lint → target graph → imports → banned APIs → build all three schemes → tests.

## Architecture

### Target graph (exhaustive: anything not listed is forbidden)

| Target | May depend on |
|---|---|
| `Localization`, `SharedDomain` | nothing (leaves) |
| `Core` | SharedDomain, Localization. No SwiftUI. |
| `DesignSystem` | Core, SharedDomain, Localization |
| `<F>Domain` | SharedDomain, other `<G>Domain` (DAG only). Never Core. |
| `<F>Data` | `<F>Domain`, SharedDomain, Core |
| `<F>Presentation` | `<F>Domain`, other `<G>Domain`, SharedDomain, DesignSystem, Core, Localization. **Never any Data.** |
| `TestSupport` | Core, SharedDomain |
| App (`ProjectTemplate`) | everything (only place that sees Data and Presentation together) |

If two features need each other's entity, move it to `SharedDomain`. Presentation-only features (e.g. Settings) are allowed.

### A feature (`Sources/Features/<F>/`)

```
Domain/      Entity/ (data-only structs) · Repository/ (protocol) · UseCase/ (struct + callAsFunction)
Data/        Endpoint/ · Model/Request|Response/ (DTOs mirror the API) · Mapper/ (validate → entity)
             DataSource/ (protocol, Remote/, Mock/, Local/, Factory/) · Repository/ (final class Impl)
Presentation/<Screen>/  <Screen>Screen.swift (owns @State viewModel) · <Screen>ViewModel.swift
App/DI/<F>Container.swift      factory → repository → use cases → view models
App/Resources/Mock/<f>/<f>-<name>.mock.json
```

### Where things go

| Need | Use |
|---|---|
| Call the API | `HTTPClient` + the feature's `Endpoint` enum. Every thrown error is a `ResponseError`. |
| Mock vs remote | chosen once in the feature container via `env.environment == .development` |
| Screen state | `ViewState<T>` rendered by `ViewStateContainer`; paged lists: `PaginatedViewModel` + `PaginatedList`/`PaginatedGrid` |
| Errors in a VM | conform to `ErrorHandling`; one-line `catch { handle(error, context: .action, form: form) }` |
| Forms | `FormField` / `FormState` with `SharedDomain.Rules`; field `name` = API field name |
| Toast / snackbar | inject `ErrorHandler`/`FeedbackPresenting`; `feedback.show(.success(L10n.X.saved))` |
| Navigation | screens expose callbacks; `RouteView` / `MainTabView` turn them into `AppRouter` calls |
| Deep link | `DeepLink` case → `DeepLinkParser` (+ test) → `scripts/push/<name>.apns` |
| Secrets | `SecureTokenStore` / `KeychainService`; larger sensitive data: `EncryptedFileStore` |
| Cache | Core Data model per feature (`Data/Model/Local`), merged by `AppContainer`; decorator repository |
| Settings-like values | `PreferencesStore` + typed `PreferenceKey` (computed statics: generic types can't store them) |
| Strings | `Localizable.xcstrings` (en + bn) + `L10n` accessor; prices/dates via `AppFormatters` (`@Environment(\.appFormatters)`) |
| Logs | `AppLogger.<category>`; `.public` only for non-PII |

### Data classification

| Data | Store |
|---|---|
| Tokens, keys, PIN | Keychain (`ThisDeviceOnly`) |
| Sensitive, larger than a token | `EncryptedFileStore` (AES-GCM + complete file protection) |
| Structured cache | Core Data (complete file protection) |
| Low-security preferences | `PreferencesStore` |

Never: tokens/PII in UserDefaults, logs or plain Core Data. Logout runs `SessionCleaner` over every store.

## Mandatory rules

1. Entities are data only: `let`s, every value passed in `init`, no defaults, no computed getters or formatting.
2. DTOs mirror the API contract; mappers validate and `throw MappingError`. Defaults only where they mean exactly
   "absent" (empty tags), with a comment; never for ids, money, quantities, status, dates or logic flags.
3. Use cases are small structs with `callAsFunction`, one operation each, re-running shared validation rules.
4. Repository impls are `final class`es; only the container names them.
5. No hardcoded sizes: `AppSpacing` / `AppRadius` / `AppIconSize` / `AppSize` (Figma points, no scaling).
6. No hardcoded colours: `AppColors` (asset catalog colour sets via generated symbols).
7. Empty and error states use `EmptyStateView` (`EmptyStateView(error:retry:)` for errors).
8. Navigation bars use `.commonAppBar(...)`.
9. One adaptive view per screen; `AdaptiveLayout` only for a distinct tablet/landscape design. Check `PreviewMatrix`.
10. Taps go through `TapArea` or a `Button` style, never `.onTapGesture`.
11. Every string lives in `Localizable.xcstrings`, in every language (a test enforces it).
12. View models are `@MainActor @Observable`.
13. Remote images use `AppImage`, never `AsyncImage`.
14. Screen state renders through `ViewStateContainer`; paged lists through `PaginatedList` / `PaginatedGrid`.
15. Navigation goes through `AppRouter` via callbacks; no `NavigationLink(destination:)`.
16. Every deep-linkable screen adds a `DeepLink` case + parser test + sample push payload.
17. No third-party packages without team approval; check the component catalog before writing a component.
18. No user-facing string literals; prices, dates, numbers through `AppFormatters`.
19. Secrets only in Keychain / `EncryptedFileStore`; follow the data classification table.
20. Preferences only through `PreferencesStore`; no `@AppStorage`, no `UserDefaults.standard`.
21. Permissions only through `PermissionManager` / `PermissionGate`, each with a localized usage description.
22. No `print`; use `AppLogger`. Never log tokens, OTPs, passwords or card data.
23. No secrets in the binary or repo. Deep links only navigate. Sensitive screens use `.privacySensitive()`.
24. No `static let shared` singletons; everything comes through the containers (except `L10n`, `AppLogger`).
25. Every remote-data screen is `.refreshable`; refresh keeps old data and shows a snackbar on failure.
26. Feedback only through `FeedbackPresenting`; popups `confirmDialog` / `appPopup`; sheets `.appSheet`. Item-driven.
27. Offline at three levels: `OfflineBanner` (root), `ViewStateContainer` auto-retry, `isOnline` guard before submits.
28. Crash-safe: no `!`, `try!`, `as!`, `unowned`, `fatalError`, unchecked subscripts (use `[safe:]`). Exception:
    a proven resource load marked `// crash-safe: <reason>`.
29. UI state only on `@MainActor`; no `DispatchQueue.main`. Networking, decoding, Core Data, images run off main.
30. Long-running work starts from the view with `.task`, or is owned by a `TaskBag` with `[weak self]`.
    Every view model has the DEBUG `deinit` log.
31. Logging through `AppLogger` with the right category and level.
32. Never commit or push to `dev` / `main`. Branch `feat|fix|refactor|chore|docs|test|ci|perf/<name>`, MR into `dev`.
33. Commit messages and MR titles: one-line Conventional Commits, `type(scope)?: subject`, 3–72 chars.
34. No magic numbers or strings: each constant has one owner; single-use values are `private static let` in the type.
35. Validation uses `SharedDomain.Rules` only (UI, use case and server errors). No ad-hoc regex.
36. Errors go `ResponseError.from` → `ErrorPolicy` → `handle(_:context:)`. No swallowed errors except `.cancelled`.

## Component catalog (DesignSystem)

| Component | Use |
|---|---|
| `TapArea`, `PressableButtonStyle` | any tappable custom content |
| `PrimaryButton`, `SecondaryButton`, `AppTextButton`, `AppIconButton`, `LoadingButton` | buttons; `LoadingButton` runs an async action once |
| `EmptyStateView`, `LoadingView`, `.skeleton(isActive:)` | empty / error / loading |
| `ViewStateContainer` | render a `ViewState` with retry, refresh, offline auto-retry |
| `PaginatedList`, `PaginatedGrid` | paged lists over `PaginatedViewModel` |
| `AppTextField`, `AppSecureField`, `OTPField`, `SearchField`, `DropdownField` | inputs bound to `FormField` |
| `FeedbackCenter`, `.feedbackWindow`, `ToastView`, `SnackBarView` | toasts/snackbars above sheets |
| `.confirmDialog(item:)`, `.choiceDialog(item:)`, `.appPopup(item:)`, `.loadingOverlay(isPresented:)` | dialogs |
| `.appSheet(item:)`, `SheetHeader` | bottom sheets (self-sizing) |
| `AppImage`, `AvatarView` | cached, downsampled remote images |
| `.offlineBanner()`, `OfflineStateView` | connectivity |
| `PermissionGate`, `PermissionRationaleCard` | permission UX |
| `.commonAppBar(...)`, `.searchAppBar(...)`, `AppTabBar`, `BadgeView` | navigation chrome |
| `SectionHeader`, `AppCard`, `AppDivider`, `BannerCarousel`, `ProductCard` | layout and content |
| `AppWebView` | allowlisted web pages |
| `LanguagePicker`, `ThemePicker` | settings |
| `AdaptiveLayout`, `PreviewMatrix` | tablet variants, multi-device previews |

## Gotchas

- The app target uses **member import visibility**: import every module whose members you use (`Core`, `os`,
  `Foundation`, `SharedDomain` for `callAsFunction()` …).
- The package also compiles for **macOS** (VS Code / `swift test`): guard UIKit with `#if canImport(UIKit)` or
  `#if os(iOS)`; iOS-only SwiftUI modifiers with `#if os(iOS)`.
- Package tests have **no Keychain entitlement**: use `InMemoryKeychain`. `TestSupport` has `MockHTTPClient`,
  `StubURLProtocol`, `MockFeedbackPresenter`, `TestImage`.
- Suites that switch the process-wide language nest under `LanguageSensitive` (serialized).
- Fixtures are copied flat into the app: name them `<feature>-<name>.mock.json` (unique). Non-dev builds exclude them.
- `swift format` sorts imports: `TestSupport` before `Testing`; run `swift format format -i` on new files.
- Keep `// create_feature:` marker comments in `Package.swift` and `L10n.swift`.

## Git

- `main` = App Store, `dev` = integration; both protected. Work on `feat/…` etc., PR into `dev` (MR on GitLab).
- One-line Conventional Commits (`commit-msg` hook), branch-name regex (`pre-commit`), no pushes to `dev`/`main`
  (`pre-push`). Hooks are installed by `./setup.sh`; CI enforces the same rules.
- CI: GitHub Actions (`.github/workflows/ci.yml`, jobs Lint / Build / Test) and GitLab CI (`.gitlab-ci.yml`) run the
  same checks. PR/MR templates: `.github/pull_request_template.md`, `.gitlab/merge_request_templates/Default.md`.
  `Package.swift`, `Core/Security`, `Core/Network` need a senior reviewer (CODEOWNERS).
