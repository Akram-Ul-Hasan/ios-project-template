import Core
import Localization
import SharedDomain
import SwiftUI

/// One box per digit over a single hidden text field, so SMS autofill (`.oneTimeCode`), paste and VoiceOver
/// all work as with a normal field. Calls `onComplete` once all digits are entered.
public struct OTPField: View {
    @Bindable private var field: FormField<String>
    private let length: Int
    private let onComplete: (String) -> Void
    @FocusState private var isFocused: Bool

    public init(
        field: FormField<String>, length: Int = ValidationConstants.otpLength, onComplete: @escaping (String) -> Void
    ) {
        self.field = field
        self.length = length
        self.onComplete = onComplete
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.s6) {
            ZStack {
                TextField("", text: $field.value)
                    .appKeyboard(.oneTimeCode)
                    .focused($isFocused)
                    .opacity(0.01)
                    .accessibilityLabel(L10n.Input.verificationCode)
                TapArea {
                    isFocused = true
                } label: {
                    HStack(spacing: AppSpacing.s8) {
                        ForEach(0..<length, id: \.self) { index in
                            box(at: index)
                        }
                    }
                }
                .accessibilityHidden(true)
            }
            if let message = field.errorMessage {
                Text(message)
                    .font(AppTypography.footnote)
                    .foregroundStyle(AppColors.error)
            }
        }
        .onChange(of: field.value) { _, newValue in
            let digits = String(newValue.filter(\.isNumber).prefix(length))
            if digits != newValue {
                field.value = digits
            } else if digits.count == length {
                onComplete(digits)
            }
        }
        .onAppear { isFocused = true }
    }

    private func box(at index: Int) -> some View {
        let characters = Array(field.value)
        let isCurrent = isFocused && index == min(characters.count, length - 1)
        return Text(index < characters.count ? String(characters[index]) : "")
            .font(AppTypography.title2)
            .foregroundStyle(AppColors.textPrimary)
            .frame(width: AppSize.otpBox, height: AppSize.otpBox)
            .background(AppColors.surface, in: RoundedRectangle(cornerRadius: AppRadius.r12))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.r12)
                    .stroke(
                        field.errorMessage != nil
                            ? AppColors.error : (isCurrent ? AppColors.brandPrimary : AppColors.border),
                        lineWidth: isCurrent ? AppSize.focusedBorderWidth : AppSize.borderWidth)
            )
    }
}

#Preview {
    OTPField(field: FormField(name: "otp", "12", rules: [])) { _ in }
        .padding(AppSpacing.s16)
}
