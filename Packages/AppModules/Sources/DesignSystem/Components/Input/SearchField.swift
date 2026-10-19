import Localization
import SwiftUI

/// Search input with a clear button. Debounce in the view with `.task(id: query)` (§6n).
public struct SearchField: View {
    @Binding private var text: String
    private let placeholder: String
    private let onSubmit: () -> Void

    public init(text: Binding<String>, placeholder: String = L10n.Input.search, onSubmit: @escaping () -> Void = {}) {
        _text = text
        self.placeholder = placeholder
        self.onSubmit = onSubmit
    }

    public var body: some View {
        HStack(spacing: AppSpacing.s8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(AppColors.textSecondary)
                .accessibilityHidden(true)
            TextField(placeholder, text: $text)
                .font(AppTypography.body)
                .foregroundStyle(AppColors.textPrimary)
                .submitLabel(.search)
                .onSubmit(onSubmit)
                .autocorrectionDisabled()
            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(AppColors.textSecondary)
                }
                .buttonStyle(PressableButtonStyle())
                .accessibilityLabel(L10n.Input.clear)
            }
        }
        .padding(.horizontal, AppSpacing.s12)
        .frame(minHeight: AppSize.buttonHeightSmall)
        .background(AppColors.surfaceVariant, in: RoundedRectangle(cornerRadius: AppRadius.r12))
    }
}

#Preview {
    @Previewable @State var query = "rice"
    SearchField(text: $query).padding(AppSpacing.s16)
}
