/// The flavor the app was built with (`APP_ENV` in Config/<Flavor>.xcconfig).
public enum AppEnvironment: String, Sendable, CaseIterable {
    case development
    case staging
    case production
}
