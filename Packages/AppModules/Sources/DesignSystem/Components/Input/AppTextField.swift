import Core
import SwiftUI

/// A text input bound to a `FormField`: shows its localized error after the first blur (§6o).
/// `AppTextField(L10n.Login.phone, field: viewModel.phone, keyboard: .phone)`
public struct AppTextField: View {
    private let label: String
    private let placeholder: String
    @Bindable private var field: FormField<String>
    private let keyboard: AppKeyboard
    @FocusState private var isFocused: Bool

    public init(_ label: String, placeholder: String = "", field: FormField<String>, keyboard: AppKeyboard = .text) {
        self.label = label
        self.placeholder = placeholder
        self.field = field
        self.keyboard = keyboard
    }

    public var body: some View {
        FieldContainer(label: label, errorMessage: field.errorMessage, isFocused: isFocused) {
            TextField(placeholder, text: $field.value)
                .focused($isFocused)
                .appKeyboard(keyboard)
                .accessibilityLabel(label)
        }
        .onChange(of: isFocused) { wasFocused, focused in
            if wasFocused && !focused { field.onBlur() }
        }
    }
}

#Preview {
    @Previewable @State var phone = FormField(name: "phone", "017", rules: [])
    VStack(spacing: AppSpacing.s16) {
        AppTextField("Phone number", placeholder: "01XXXXXXXXX", field: phone, keyboard: .phone)
        AppTextField("Disabled", field: FormField(name: "x", "Read only", rules: [])).disabled(true)
    }
    .padding(AppSpacing.s16)
    .onAppear { phone.setServerError("This number is already registered") }
}
