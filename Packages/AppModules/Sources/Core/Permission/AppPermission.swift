/// Every permission the app may ask for. Each needs its `NS…UsageDescription` in Info.plist, localized in
/// `App/Resources/InfoPlist.xcstrings` — a missing key crashes on request. Remove the ones an app doesn't use.
public enum AppPermission: String, CaseIterable, Sendable {
    case notifications
    case locationWhenInUse
    case camera
    case microphone
    case photos
    case contacts
    case tracking
}
