import Localization
import SwiftUI

extension View {
    /// A designed popup ("Order placed 🎉"): dimmed backdrop, scale + fade, centered on every device.
    /// Item-driven like sheets: `.appPopup(item: $viewModel.popup) { popup in OrderPlacedPopup(popup) }`.
    public func appPopup<Item: Identifiable, Content: View>(
        item: Binding<Item?>,
        dismissOnTapOutside: Bool = true,
        @ViewBuilder content: @escaping (Item) -> Content
    ) -> some View {
        overlay {
            ZStack {
                if let value = item.wrappedValue {
                    Button {
                        if dismissOnTapOutside { item.wrappedValue = nil }
                    } label: {
                        AppColors.scrim.ignoresSafeArea()
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(L10n.Common.close)
                    .transition(.opacity)

                    content(value)
                        .padding(AppSpacing.s24)
                        .frame(maxWidth: AppSize.popupMaxWidth)
                        .background(AppColors.surface, in: RoundedRectangle(cornerRadius: AppRadius.r24))
                        .appShadow(.large)
                        .padding(AppSpacing.s24)
                        .transition(.scale(scale: 0.9).combined(with: .opacity))
                        .accessibilityAddTraits(.isModal)
                }
            }
            .animation(AppAnimation.spring, value: item.wrappedValue != nil)
        }
    }

    /// Blocks the screen with a spinner during a one-shot critical action (place order, payment):
    /// no taps, no swipe-to-dismiss, no back gesture.
    public func loadingOverlay(isPresented: Bool) -> some View {
        overlay {
            if isPresented {
                ZStack {
                    AppColors.scrim.ignoresSafeArea()
                    ProgressView()
                        .controlSize(.large)
                        .tint(AppColors.brandPrimary)
                        .padding(AppSpacing.s24)
                        .background(AppColors.surface, in: RoundedRectangle(cornerRadius: AppRadius.r16))
                }
                .transition(.opacity)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(L10n.State.loading)
                .accessibilityAddTraits(.isModal)
            }
        }
        .animation(AppAnimation.fast, value: isPresented)
        .interactiveDismissDisabled(isPresented)
        #if os(iOS)
            .navigationBarBackButtonHidden(isPresented)
        #endif
    }
}

#Preview("Popup") {
    struct Popup: Identifiable {
        let id = 1
    }
    return Color.clear.appPopup(item: .constant(Popup())) { _ in
        VStack(spacing: AppSpacing.s16) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: AppIconSize.s48))
                .foregroundStyle(AppColors.success)
            Text(verbatim: "Order placed").font(AppTypography.title3)
            PrimaryButton("Track order") {}
        }
    }
}

#Preview("Loading overlay") {
    Text(verbatim: "Checkout").loadingOverlay(isPresented: true)
}
