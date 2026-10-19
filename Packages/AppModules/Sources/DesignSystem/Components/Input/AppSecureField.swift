import Core
import Localization
import SwiftUI

/// Password input with a show/hide toggle. `isNewPassword` lets iOS suggest a strong password on sign-up.
public struct AppSecureField: View {
    private let label: String
    @Bindable private var field: FormField<String>
    private let isNewPassword: Bool
    @State private var isRevealed = false
    @FocusState private var isFocused: Bool

    public init(_ label: String, field: FormField<String>, isNewPassword: Bool = false) {
        self.label = label
        self.field = field
        self.isNewPassword = isNewPassword
    }

    public var body: some View {
        FieldContainer(label: label, errorMessage: field.errorMessage, isFocused: isFocused) {
            HStack(spacing: AppSpacing.s8) {
                Group {
                    if isRevealed {
                        TextField("", text: $field.value)
                    } else {
                        SecureField("", text: $field.value)
                    }
                }
                .focused($isFocused)
                .autocorrectionDisabled()
                #if os(iOS)
                    .textInputAutocapitalization(.never)
                    .textContentType(isNewPassword ? .newPassword : .password)
                #endif
                .accessibilityLabel(label)

                Button {
                    isRevealed.toggle()
                } label: {
                    Image(systemName: isRevealed ? "eye.slash" : "eye")
                        .foregroundStyle(AppColors.textSecondary)
                        .frame(width: AppSize.minTapTarget, height: AppSize.minTapTarget)
                }
                .buttonStyle(PressableButtonStyle())
                .accessibilityLabel(isRevealed ? L10n.Input.hidePassword : L10n.Input.showPassword)
            }
        }
        .onChange(of: isFocused) { wasFocused, focused in
            if wasFocused && !focused { field.onBlur() }
        }
    }
}

#Preview {
    AppSecureField("Password", field: FormField(name: "password", "secret12", rules: []))
        .padding(AppSpacing.s16)
}
