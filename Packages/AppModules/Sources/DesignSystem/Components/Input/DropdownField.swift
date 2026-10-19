import Core
import Localization
import SwiftUI

/// Pick one of a few options (area, gender, payment type), bound to a `FormField<Option?>` so
/// `Rules.selection()` can require a choice. For long lists use a searchable sheet instead.
public struct DropdownField<Option: Hashable & Sendable>: View {
    private let label: String
    private let options: [Option]
    private let title: (Option) -> String
    @Bindable private var field: FormField<Option?>

    public init(_ label: String, options: [Option], field: FormField<Option?>, title: @escaping (Option) -> String) {
        self.label = label
        self.options = options
        self.field = field
        self.title = title
    }

    public var body: some View {
        FieldContainer(label: label, errorMessage: field.errorMessage, isFocused: false) {
            Menu {
                ForEach(options, id: \.self) { option in
                    Button {
                        field.value = option
                        field.onBlur()
                    } label: {
                        if option == field.value {
                            Label(title(option), systemImage: "checkmark")
                        } else {
                            Text(title(option))
                        }
                    }
                }
            } label: {
                HStack {
                    Text(field.value.map(title) ?? L10n.Input.select)
                        .foregroundStyle(field.value == nil ? AppColors.textSecondary : AppColors.textPrimary)
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .foregroundStyle(AppColors.textSecondary)
                        .accessibilityHidden(true)
                }
                .contentShape(Rectangle())
            }
            .accessibilityLabel(label)
        }
    }
}

#Preview {
    DropdownField(
        "Delivery area", options: ["Dhanmondi", "Gulshan", "Mirpur"],
        field: FormField(name: "area", nil, rules: []), title: { $0 }
    )
    .padding(AppSpacing.s16)
}
