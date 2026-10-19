import Core
import DesignSystem
import Localization
import SwiftUI

extension View {
    /// Blurs the app whenever it isn't active, so the app switcher snapshot never shows user data (§6l).
    func privacyScreen() -> some View {
        modifier(PrivacyScreenModifier())
    }

    /// Covers the app with a lock screen while `SessionManager.isLocked` (biometric re-lock after time away).
    func sessionLock(_ sessionManager: SessionManager, isActive: Bool) -> some View {
        overlay {
            if isActive && sessionManager.isLocked {
                LockView(sessionManager: sessionManager)
                    .transition(.opacity)
            }
        }
    }
}

private struct PrivacyScreenModifier: ViewModifier {
    @Environment(\.scenePhase) private var scenePhase

    func body(content: Content) -> some View {
        content.overlay {
            if scenePhase != .active {
                ZStack {
                    Rectangle().fill(.regularMaterial)
                    Image(systemName: "lock.fill")
                        .font(.system(size: AppIconSize.s48))
                        .foregroundStyle(AppColors.textSecondary)
                }
                .ignoresSafeArea()
                .accessibilityHidden(true)
            }
        }
    }
}

private struct LockView: View {
    let sessionManager: SessionManager

    var body: some View {
        VStack(spacing: AppSpacing.s24) {
            EmptyStateView(systemImage: "faceid", title: L10n.Lock.title)
            PrimaryButton(L10n.Lock.unlock) { Task { await sessionManager.unlock() } }
                .frame(maxWidth: AppSpacing.readableWidth)
        }
        .padding(AppSpacing.s24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.background)
        .task { await sessionManager.unlock() }
    }
}
