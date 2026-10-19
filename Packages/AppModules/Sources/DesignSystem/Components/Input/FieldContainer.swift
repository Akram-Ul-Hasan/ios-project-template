import SwiftUI

/// Label above, bordered box, error below: the chrome every input shares.
struct FieldContainer<Content: View>: View {
    let label: String?
    let errorMessage: String?
    let isFocused: Bool
    @ViewBuilder let content: Content

    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.s6) {
            if let label {
                Text(label)
                    .font(AppTypography.subheadline)
                    .foregroundStyle(AppColors.textSecondary)
            }
            content
                .font(AppTypography.body)
                .foregroundStyle(isEnabled ? AppColors.textPrimary : AppColors.textDisabled)
                .padding(.horizontal, AppSpacing.s12)
                .frame(minHeight: AppSize.textFieldHeight)
                .background(AppColors.surface, in: RoundedRectangle(cornerRadius: AppRadius.r12))
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.r12)
                        .stroke(
                            borderColor,
                            lineWidth: isFocused || errorMessage != nil
                                ? AppSize.focusedBorderWidth : AppSize.borderWidth)
                )
            if let errorMessage {
                Label(errorMessage, systemImage: "exclamationmark.circle.fill")
                    .font(AppTypography.footnote)
                    .foregroundStyle(AppColors.error)
                    .transition(.opacity)
            }
        }
        .animation(AppAnimation.fast, value: errorMessage)
        .accessibilityElement(children: .contain)
    }

    private var borderColor: Color {
        if errorMessage != nil { return AppColors.error }
        return isFocused ? AppColors.brandPrimary : AppColors.border
    }
}

/// Keyboard and autofill hints. iOS only; ignored elsewhere.
public enum AppKeyboard: Sendable {
    case text
    case name
    case phone
    case email
    case number
    case oneTimeCode
}

extension View {
    @ViewBuilder
    func appKeyboard(_ keyboard: AppKeyboard) -> some View {
        #if os(iOS)
            switch keyboard {
            case .text: self
            case .name: textContentType(.name).textInputAutocapitalization(.words)
            case .phone: keyboardType(.phonePad).textContentType(.telephoneNumber)
            case .email:
                keyboardType(.emailAddress).textContentType(.emailAddress).textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            case .number: keyboardType(.numberPad)
            case .oneTimeCode: keyboardType(.numberPad).textContentType(.oneTimeCode)
            }
        #else
            self
        #endif
    }
}
