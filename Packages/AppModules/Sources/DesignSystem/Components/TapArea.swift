import SwiftUI

/// Makes any content tappable with a pressed state (rule 10: no `.onTapGesture` for actions).
/// It's a real `Button`, so VoiceOver, keyboard and pointer support come for free.
public struct TapArea<Label: View>: View {
    private let action: () -> Void
    private let label: Label

    public init(action: @escaping () -> Void, @ViewBuilder label: () -> Label) {
        self.action = action
        self.label = label()
    }

    public var body: some View {
        Button(action: action) {
            label.contentShape(Rectangle())
        }
        .buttonStyle(PressableButtonStyle())
    }
}

/// Dims content while pressed. The plain style for custom tappable rows and cards.
public struct PressableButtonStyle: ButtonStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? AppOpacity.pressed : 1)
            .animation(AppAnimation.fast, value: configuration.isPressed)
    }
}

#Preview {
    TapArea {
    } label: {
        HStack {
            Image(systemName: "shippingbox")
            Text(verbatim: "Orders")
            Spacer()
            Image(systemName: "chevron.forward")
        }
        .padding(AppSpacing.s16)
        .foregroundStyle(AppColors.textPrimary)
    }
}
