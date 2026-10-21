---
name: add-permission
description: Add a device permission end to end: AppPermission case, handler, Info.plist usage text in every language, and PermissionGate usage. Use when a feature needs camera, location, contacts or similar access.
---

# Add a permission

1. `Core/Permission/AppPermission.swift`: add the case. `Core/Permission/Handlers/`: a handler wrapping the Apple
   API, mapping to `PermissionStatus` (partial access → `.limited`); delegate APIs via a continuation
   (see `LocationPermissionHandler`). Register it in `SystemPermissionManager.init()`.
2. DesignSystem: add its `title` and `systemImage` in `Components/Permission/PermissionGate.swift`, plus the
   `permission.<name>` string (both languages).
3. `App/Resources/Info.plist`: the `NS…UsageDescription` key (English); `App/Resources/InfoPlist.xcstrings`: every
   language. A missing key crashes on request.
4. If it's a required-reason API or collects data, update `App/Resources/PrivacyInfo.xcprivacy`.
5. Use it in the screen: `PermissionGate(.camera, rationale: L10n.X.cameraRationale) { ScannerView() }`.
   Ask at the moment of use, never at launch.
6. Test the mapping (`PermissionHandlerMappingTests`) and the screen with `FixedPermissionManager`.
