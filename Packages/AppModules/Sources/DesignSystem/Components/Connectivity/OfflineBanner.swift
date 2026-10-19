import Core
import Localization
import SwiftUI

extension View {
    /// The global connectivity banner (§6m level 1). Mount once at the root; reads `NetworkMonitor` from the environment.
    public func offlineBanner() -> some View {
        overlay(alignment: .top) { OfflineBanner() }
    }
}

/// "No internet connection" under the status bar while offline; "Back online" for a moment on reconnect.
public struct OfflineBanner: View {
    @Environment(NetworkMonitor.self) private var network: NetworkMonitor?
    @State private var showsBackOnline = false
    private static let backOnlineDuration: Duration = .seconds(2)

    public init() {}

    public var body: some View {
        Group {
            if network?.isOnline == false {
                banner(L10n.Offline.banner, systemImage: "wifi.slash", color: AppColors.warning)
            } else if showsBackOnline {
                banner(L10n.Offline.backOnline, systemImage: "wifi", color: AppColors.success)
            }
        }
        .animation(AppAnimation.standard, value: network?.isOnline)
        .animation(AppAnimation.standard, value: showsBackOnline)
        .onChange(of: network?.isOnline) { wasOnline, isOnline in
            if wasOnline == false, isOnline == true { showsBackOnline = true }
        }
        .task(id: showsBackOnline) {
            guard showsBackOnline else { return }
            try? await Task.sleep(for: Self.backOnlineDuration)
            showsBackOnline = false
        }
    }

    private func banner(_ text: String, systemImage: String, color: Color) -> some View {
        Label(text, systemImage: systemImage)
            .font(AppTypography.captionEmphasized)
            .foregroundStyle(AppColors.onPrimary)
            .padding(.horizontal, AppSpacing.s16)
            .padding(.vertical, AppSpacing.s6)
            .background(color, in: Capsule())
            .padding(.top, AppSpacing.s4)
            .transition(.move(edge: .top).combined(with: .opacity))
            .accessibilityAddTraits(.updatesFrequently)
    }
}

/// Full-screen offline state for a screen with nothing cached (§6m level 2).
public struct OfflineStateView: View {
    private let onRetry: () -> Void

    public init(onRetry: @escaping () -> Void) {
        self.onRetry = onRetry
    }

    public var body: some View {
        EmptyStateView(error: .network, retry: onRetry)
    }
}

#Preview("Offline") {
    Color.clear
        .offlineBanner()
        .environment(NetworkMonitor.preview(isOnline: false))
}

#Preview("Offline state") {
    OfflineStateView {}
}
