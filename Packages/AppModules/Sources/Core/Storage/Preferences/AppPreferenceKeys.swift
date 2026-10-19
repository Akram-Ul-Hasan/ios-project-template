import Localization

// App-wide preference keys. Computed because generic types can't have stored statics.

extension PreferenceKey where Value == Bool {
    public static var onboardingSeen: Self { Self(name: "onboarding_seen", defaultValue: false, scope: .device) }
    /// Missing on the first launch after install: the Keychain survives app deletion, so stale items get wiped (§6i).
    public static var hasLaunchedBefore: Self {
        Self(name: "has_launched_before", defaultValue: false, scope: .device)
    }
}

extension PreferenceKey where Value == AppLanguage? {
    /// `nil` until the user picks a language: the device language is used until then.
    public static var language: Self { Self(name: "language", defaultValue: nil, scope: .device) }
}

extension PreferenceKey where Value == String {
    /// Raw value of DesignSystem's `ThemeMode` (system / light / dark).
    public static var themeMode: Self { Self(name: "theme_mode", defaultValue: "system", scope: .device) }
}

extension PreferenceKey where Value == String? {
    public static var lastSelectedTab: Self { Self(name: "last_selected_tab", defaultValue: nil, scope: .user) }
}
