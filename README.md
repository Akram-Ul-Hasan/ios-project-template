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

## Architecture

```
ios-project-template/
├── App/                  app target: DI containers, router + tabs, deep links, root flow, push (thin shell)
├── AppTests/             app unit tests (router, deep links, fixtures)
├── Config/               xcconfig per flavor
├── Packages/AppModules/  all real code: one SPM target per layer per feature
│   ├── Sources/Localization   strings (en, bn), L10n, active language
│   ├── Sources/SharedDomain   UseCase, shared entities, validation rules
│   ├── Sources/Core           env, networking, errors, storage, security, session, images, pagination, forms …
│   ├── Sources/DesignSystem   tokens, theme, components
│   └── Sources/Features/<F>/  Domain · Data · Presentation
└── scripts/              hooks, checks, create_feature.sh, push payloads
```

### Target graph

Every edge points down, so cycles are impossible, and Data and Presentation can never see each other:

```
L4  ProjectTemplate (app)     → everything
L3  <F>Presentation           → <F>Domain, <G>Domain, DesignSystem, Core, SharedDomain, Localization
L3  <F>Data                   → <F>Domain, Core, SharedDomain
L2  DesignSystem              → Core, SharedDomain, Localization
L2  <F>Domain                 → SharedDomain, <G>Domain
L1  Core                      → SharedDomain, Localization
L0  SharedDomain, Localization
```

Three layers of enforcement: Swift won't compile an import of a module that isn't built for the target;
`scripts/check_imports.sh` rejects imports that aren't **declared** dependencies (SwiftPM would otherwise let an
already-built module slip through); `scripts/check_target_graph.sh` rejects disallowed edges added to
`Package.swift`. All three run in CI.

### How a request flows

```
Screen ─▶ ViewModel ─▶ UseCase ─▶ Repository (protocol, Domain)
                                     │
                     RepositoryImpl (Data) ─▶ DataSourceFactory ─▶ Remote (HTTPClient) | Mock (fixtures) | Local (Core Data)
                                     │
                          DTO ─▶ mapper (validates) ─▶ Entity
```

- **DI** by hand: `AppContainer` creates shared infrastructure once; each feature container builds factory →
  repository → use cases → view models. No service locator, so a missing dependency is a compile error.
- **Networking**: `URLSessionHTTPClient` with an interceptor chain (log → auth token → Accept-Language → backend
  error); single-flight token refresh on 401; certificate pinning in staging/production.
- **Errors**: everything becomes a `ResponseError`; `ErrorPolicy` decides full screen / snackbar / inline / dialog /
  logout / blocking screen; view models call `handle(_:context:)`.
- **State**: `ViewState<T>` + `ViewStateContainer`; paged lists with `PaginatedViewModel` + `PaginatedList`.
- **Navigation**: `AppRouter` (tab + one stack per tab + sheet); screens expose callbacks; deep links from push,
  universal links and the URL scheme share one allowlisted parser.
- **Security**: Keychain (`ThisDeviceOnly`), AES-GCM encrypted files, complete data protection, privacy screen,
  biometric re-lock, jailbreak/debugger signals, App Attest, privacy manifest.

## Contributing

### Branches

| Branch | Purpose | From → into |
|---|---|---|
| `main` | what's in the App Store; every merge tagged `vX.Y.Z` | ← `release/*`, `hotfix/*` |
| `dev` | integration, always builds | ← feature branches |
| `feat/…` `fix/…` `refactor/…` `chore/…` `docs/…` `test/…` `ci/…` `perf/…` | one change each | `dev` → MR → `dev` |
| `release/1.4.0` | stabilize + version bump | `dev` → MR → `main`, back-merge to `dev` |
| `hotfix/1.4.1` | urgent production fix | `main` → MR → `main`, back-merge to `dev` |

`dev` and `main` are protected: nobody pushes to them; maintainers merge pull requests (MRs on GitLab) with a green
pipeline and resolved conversations.

### Workflow

```sh
git switch dev && git pull
git switch -c feat/order-history
# small commits, each a one-line Conventional Commit
# run preflight (see CLAUDE.md)
git push -u origin feat/order-history     # then open a PR into dev (the template fills in the checklist)
```

### Commit messages and MR titles

One line, `type(scope)?: subject`, 3–72 characters, imperative and lowercase:
`feat(cart): add quantity stepper`, `fix(image): cancel download when cell disappears`.
Types: `feat` `fix` `refactor` `perf` `test` `docs` `style` `chore` `build` `ci` `revert`; `!` marks a breaking change.

### What the hooks and CI enforce

| Check | Local hook | GitHub Actions (`.github/workflows/ci.yml`) | GitLab CI (`.gitlab-ci.yml`) |
|---|---|---|---|
| branch name, no commits/pushes to `dev`/`main` | pre-commit, pre-push | Lint | `lint:git` |
| one-line Conventional Commits | commit-msg | Lint (every commit + PR title) | `lint:git` |
| `swift format lint --strict` | pre-commit (staged files) | Lint | `lint:format` |
| banned APIs | pre-commit | Lint | `lint:banned-api` |
| target graph / declared imports | pre-commit (Package.swift) / pre-push | Lint | `lint:target-graph`, `lint:imports` |
| secrets (`*.p12`, `*.secrets.xcconfig`, private keys) | pre-commit | — | — |
| build all three schemes | pre-push (package) | Build (Development / Staging / Production) | `build` |
| tests + coverage | — | Test (coverage artifact + job summary) | `test` |

Hooks are a fast first line (they can be bypassed); branch protection and the pipeline are the real gate. Both
pipelines need a macOS runner with the Xcode from `.xcode-version`: on GitHub, `macos-latest` by default, or a
self-hosted Mac via the `MACOS_RUNNER` repository variable; on GitLab, a self-hosted runner tagged `macos`.

### Branch protection (GitHub)

Settings → Branches → add a rule (or ruleset) for **`dev`** and for **`main`**:

- Require a pull request before merging (1 approval; dismiss stale approvals; require review from Code Owners).
- Require status checks to pass, branches up to date: **Lint**, **Build (Development)**, **Build (Staging)**,
  **Build (Production)**, **Test** (they appear in the list after the workflow has run once).
- Require conversation resolution; block force pushes; restrict deletions.
- Optionally allow only squash merges (Settings → General → Pull Requests) so the PR title becomes the commit.

### Before you open an MR

- preflight passes; no new third-party dependency;
- every new string is in every language; screens checked in `PreviewMatrix` (light/dark, large text, iPad);
- no `Package.swift` edge outside the target graph; changes to `Package.swift`, `Core/Security` or `Core/Network`
  need a senior reviewer (`.github/CODEOWNERS`, `.gitlab/CODEOWNERS`).
