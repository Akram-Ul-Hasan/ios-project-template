import Core
import Localization
import SwiftUI

public struct DialogButton: Sendable {
    public enum Role: Sendable {
        case `default`
        case cancel
        case destructive
    }

    public let title: String
    public let role: Role
    public let action: @MainActor @Sendable () -> Void

    public init(_ title: String, role: Role = .default, action: @escaping @MainActor @Sendable () -> Void = {}) {
        self.title = title
        self.role = role
        self.action = action
    }

    public static var ok: DialogButton { DialogButton(L10n.Common.ok) }
    public static var cancel: DialogButton { DialogButton(L10n.Common.cancel, role: .cancel) }

    var buttonRole: ButtonRole? {
        switch role {
        case .default: nil
        case .cancel: .cancel
        case .destructive: .destructive
        }
    }
}

/// A yes/no question or a message. Item-driven, so the dialog and its data can't get out of sync (rule 26):
/// `@State var dialog: DialogModel?` … `.confirmDialog(item: $dialog)`.
public struct DialogModel: Identifiable, Sendable {
    public let id = UUID()
    public let title: String
    public let message: String?
    public let primary: DialogButton
    public let secondary: DialogButton?

    public init(title: String, message: String?, primary: DialogButton, secondary: DialogButton?) {
        self.title = title
        self.message = message
        self.primary = primary
        self.secondary = secondary
    }

    /// For `ErrorHandling.showDialog(for:)`: the localized message with OK.
    public init(error: ResponseError) {
        self.init(title: L10n.Error.title, message: error.localizedMessage, primary: .ok, secondary: nil)
    }
}

/// Choose one of several actions (share, report, delete…), shown as an action sheet.
public struct ChoiceModel: Identifiable, Sendable {
    public let id = UUID()
    public let title: String
    public let message: String?
    public let options: [DialogButton]

    public init(title: String, message: String?, options: [DialogButton]) {
        self.title = title
        self.message = message
        self.options = options
    }
}

extension View {
    public func confirmDialog(item: Binding<DialogModel?>) -> some View {
        alert(
            item.wrappedValue?.title ?? "", isPresented: item.isPresent(), presenting: item.wrappedValue
        ) { model in
            Button(model.primary.title, role: model.primary.buttonRole, action: model.primary.action)
            if let secondary = model.secondary {
                Button(secondary.title, role: secondary.buttonRole, action: secondary.action)
            }
        } message: { model in
            if let message = model.message { Text(message) }
        }
    }

    public func choiceDialog(item: Binding<ChoiceModel?>) -> some View {
        confirmationDialog(
            item.wrappedValue?.title ?? "", isPresented: item.isPresent(), titleVisibility: .visible,
            presenting: item.wrappedValue
        ) { model in
            ForEach(Array(model.options.enumerated()), id: \.offset) { _, option in
                Button(option.title, role: option.buttonRole, action: option.action)
            }
        } message: { model in
            if let message = model.message { Text(message) }
        }
    }
}

extension Binding {
    /// `true` while an optional item is set; setting `false` clears it.
    func isPresent<Wrapped: Sendable>() -> Binding<Bool> where Value == Wrapped? {
        Binding<Bool>(get: { wrappedValue != nil }, set: { if !$0 { wrappedValue = nil } })
    }
}

#Preview {
    @Previewable @State var dialog: DialogModel? = DialogModel(
        title: "Remove item?", message: "It will be removed from your cart.",
        primary: DialogButton("Remove", role: .destructive), secondary: .cancel)
    Color.clear.confirmDialog(item: $dialog)
}
