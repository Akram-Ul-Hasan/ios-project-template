import Core
import Localization
import Observation
import SwiftUI

public enum ThemeMode: String, CaseIterable, Identifiable, Sendable {
    case system
    case light
    case dark

    public var id: String { rawValue }

    /// `nil` follows the device setting.
    public var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }

    public var title: String {
        switch self {
        case .system: L10n.Theme.system
        case .light: L10n.Theme.light
        case .dark: L10n.Theme.dark
        }
    }
}

/// The user's appearance choice, saved in preferences and applied at the root with `.preferredColorScheme`.
@MainActor
@Observable
public final class ThemeManager {
    public private(set) var mode: ThemeMode

    @ObservationIgnored private let preferences: any PreferencesStore

    public init(preferences: any PreferencesStore) {
        self.preferences = preferences
        mode = ThemeMode(rawValue: preferences.value(.themeMode)) ?? .system
    }

    public var colorScheme: ColorScheme? { mode.colorScheme }

    public func set(_ mode: ThemeMode) {
        preferences.set(mode.rawValue, for: .themeMode)
        self.mode = mode
    }
}
