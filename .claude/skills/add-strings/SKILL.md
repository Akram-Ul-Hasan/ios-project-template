---
name: add-strings
description: Add or change user-facing strings in every language with a type-safe L10n accessor. Use whenever UI text, error messages or plurals are added.
---

# Add strings

1. Edit `Packages/AppModules/Sources/Localization/Resources/Localizable.xcstrings`: add the key
   (`<area>.<name>`, snake_case) with `en` **and** `bn` values. Plurals use `variations.plural` (`one` / `other`)
   with `%lld`.
2. Add the accessor to `Packages/AppModules/Sources/Localization/L10n.swift` inside the matching nested enum
   (alphabetical): `public static var title: String { tr("area.title") }`, or a func for parameters:
   `public static func itemsCount(_ count: Int) -> String { tr("common.items_count", count) }`.
3. Use it as `Text(L10n.Area.title)`. Never a literal in a view; never `String(format:)` for prices or dates
   (use `AppFormatters`).
4. `swift test --package-path Packages/AppModules --filter LocalizationTests` checks every key exists in every language.
5. Info.plist strings (permission usage descriptions) live in `App/Resources/InfoPlist.xcstrings`.
