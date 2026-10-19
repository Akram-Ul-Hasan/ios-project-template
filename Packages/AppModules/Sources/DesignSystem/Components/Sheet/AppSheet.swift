import Localization
import SwiftUI

public enum AppSheetDetents: Sendable {
    /// Exactly as tall as its content (pickers, short forms).
    case fitContent
    case medium
    case large
    case mediumAndLarge
}

extension View {
    /// `.sheet` with the house style (§6m): drag indicator, corner radius, surface background, keyboard dismiss on
    /// scroll, a form sheet on iPad. Item-driven, never a `Bool` plus separate data:
    /// `.appSheet(item: $sheet) { sheet in AddressPicker(sheet) }`.
    public func appSheet<Item: Identifiable, Content: View>(
        item: Binding<Item?>,
        detents: AppSheetDetents = .fitContent,
        isDismissDisabled: Bool = false,
        @ViewBuilder content: @escaping (Item) -> Content
    ) -> some View {
        sheet(item: item) { value in
            AppSheetContainer(detents: detents, isDismissDisabled: isDismissDisabled) { content(value) }
        }
    }
}

private struct AppSheetContainer<Content: View>: View {
    let detents: AppSheetDetents
    let isDismissDisabled: Bool
    @ViewBuilder let content: Content
    @State private var contentHeight: CGFloat = AppSize.bannerHeight

    var body: some View {
        sized
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(AppRadius.r24)
            .presentationBackground(AppColors.surface)
            .scrollDismissesKeyboard(.interactively)
            .interactiveDismissDisabled(isDismissDisabled)
            .modifier(FormSheetSizing())
    }

    @ViewBuilder
    private var sized: some View {
        switch detents {
        case .fitContent:
            content
                .fixedSize(horizontal: false, vertical: true)
                .onGeometryChange(for: CGFloat.self) {
                    $0.size.height
                } action: {
                    contentHeight = $0
                }
                .presentationDetents([.height(contentHeight)])
        case .medium: content.presentationDetents([.medium])
        case .large: content.presentationDetents([.large])
        case .mediumAndLarge: content.presentationDetents([.medium, .large])
        }
    }
}

/// Centered form-sized sheet on iPad (iOS 18+), so sheets never need a tablet variant.
private struct FormSheetSizing: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 18, macOS 15, *) {
            content.presentationSizing(.form)
        } else {
            content
        }
    }
}

/// Title and close button, so every sheet looks the same.
public struct SheetHeader: View {
    private let title: String
    private let onClose: () -> Void

    public init(_ title: String, onClose: @escaping () -> Void) {
        self.title = title
        self.onClose = onClose
    }

    public var body: some View {
        HStack {
            Text(title)
                .font(AppTypography.headline)
                .foregroundStyle(AppColors.textPrimary)
                .accessibilityAddTraits(.isHeader)
            Spacer()
            AppIconButton(systemImage: "xmark", accessibilityLabel: L10n.Common.close, action: onClose)
        }
        .padding(.leading, AppSpacing.s16)
        .padding(.top, AppSpacing.s8)
    }
}

#Preview {
    struct Sheet: Identifiable {
        let id = 1
    }
    return Color.clear.appSheet(item: .constant(Sheet())) { _ in
        VStack(alignment: .leading, spacing: AppSpacing.s16) {
            SheetHeader("Delivery area") {}
            Text(verbatim: "Choose where we should deliver.")
                .padding(.horizontal, AppSpacing.s16)
            PrimaryButton("Confirm") {}
                .padding(AppSpacing.s16)
        }
    }
}
