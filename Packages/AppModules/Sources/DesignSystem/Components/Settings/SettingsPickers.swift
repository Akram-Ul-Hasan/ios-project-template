import Core
import Localization
import SwiftUI

/// In-app language switch (§6k). Each language is listed in itself, so it's findable whatever the current language.
public struct LanguagePicker: View {
    private let manager: LocalizationManager

    public init(manager: LocalizationManager) {
        self.manager = manager
    }

    public var body: some View {
        Picker(L10n.Settings.language, selection: Binding(get: { manager.language }, set: { manager.set($0) })) {
            ForEach(AppLanguage.allCases, id: \.self) { language in
                Text(language.nativeName).tag(language)
            }
        }
        .pickerStyle(.menu)
    }
}

/// System / light / dark.
public struct ThemePicker: View {
    private let manager: ThemeManager

    public init(manager: ThemeManager) {
        self.manager = manager
    }

    public var body: some View {
        Picker(L10n.Settings.theme, selection: Binding(get: { manager.mode }, set: { manager.set($0) })) {
            ForEach(ThemeMode.allCases) { mode in
                Text(mode.title).tag(mode)
            }
        }
        .pickerStyle(.menu)
    }
}

#Preview {
    Form {
        LanguagePicker(manager: LocalizationManager(preferences: InMemoryPreferencesStore()))
        ThemePicker(manager: ThemeManager(preferences: InMemoryPreferencesStore()))
    }
}
