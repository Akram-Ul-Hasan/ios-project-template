import Core
import Localization
import SwiftUI

extension EnvironmentValues {
    /// Set at the root from `AppContainer`; previews can inject a `FixedPermissionManager`.
    @Entry public var permissionManager: any PermissionManager = SystemPermissionManager()
}

/// The whole permission UX in one line (§6j):
/// `PermissionGate(.camera, rationale: L10n.Scanner.cameraRationale) { ScannerView() }`
/// - not asked yet: a rationale card first, then the system prompt on Continue;
/// - denied: explanation with "Open Settings"; restricted: explanation only;
/// - granted or limited: the content. Re-checks when the user comes back from Settings.
public struct PermissionGate<Content: View>: View {
    private let permission: AppPermission
    private let rationale: String
    private let onNotNow: (() -> Void)?
    private let content: Content

    @Environment(\.permissionManager) private var manager
    @Environment(\.scenePhase) private var scenePhase
    @State private var status: PermissionStatus?

    public init(
        _ permission: AppPermission,
        rationale: String,
        onNotNow: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.permission = permission
        self.rationale = rationale
        self.onNotNow = onNotNow
        self.content = content()
    }

    public var body: some View {
        Group {
            switch status {
            case nil:
                LoadingView()
            case .notDetermined:
                PermissionRationaleCard(permission, rationale: rationale, onNotNow: onNotNow) {
                    Task { status = await manager.request(permission) }
                }
            case .denied:
                EmptyStateView(
                    systemImage: permission.systemImage, title: L10n.Permission.deniedTitle,
                    message: L10n.Permission.deniedMessage, actionTitle: L10n.Common.openSettings,
                    action: manager.openAppSettings)
            case .restricted:
                EmptyStateView(
                    systemImage: permission.systemImage, title: L10n.Permission.deniedTitle,
                    message: L10n.Permission.restrictedMessage)
            case .granted, .limited:
                content
            }
        }
        .task { status = await manager.status(of: permission) }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            Task { status = await manager.status(of: permission) }
        }
    }
}

/// The soft ask before the system prompt: why the app needs it, Continue, and optionally Not now.
public struct PermissionRationaleCard: View {
    private let permission: AppPermission
    private let rationale: String
    private let onNotNow: (() -> Void)?
    private let onContinue: () -> Void

    public init(
        _ permission: AppPermission,
        rationale: String,
        onNotNow: (() -> Void)?,
        onContinue: @escaping () -> Void
    ) {
        self.permission = permission
        self.rationale = rationale
        self.onNotNow = onNotNow
        self.onContinue = onContinue
    }

    public var body: some View {
        VStack(spacing: AppSpacing.s16) {
            Image(systemName: permission.systemImage)
                .font(.system(size: AppIconSize.s48))
                .foregroundStyle(AppColors.brandPrimary)
                .accessibilityHidden(true)
            Text(permission.title)
                .font(AppTypography.title3)
                .foregroundStyle(AppColors.textPrimary)
            Text(rationale)
                .font(AppTypography.body)
                .foregroundStyle(AppColors.textSecondary)
                .multilineTextAlignment(.center)
            PrimaryButton(L10n.Common.continue, action: onContinue)
                .padding(.top, AppSpacing.s8)
            if let onNotNow {
                AppTextButton(L10n.Permission.notNow, action: onNotNow)
            }
        }
        .padding(AppSpacing.s24)
        .frame(maxWidth: AppSpacing.readableWidth)
    }
}

extension AppPermission {
    var systemImage: String {
        switch self {
        case .notifications: "bell.badge"
        case .locationWhenInUse: "location"
        case .camera: "camera"
        case .microphone: "mic"
        case .photos: "photo.on.rectangle"
        case .contacts: "person.crop.circle"
        case .tracking: "hand.raised"
        }
    }

    var title: String {
        switch self {
        case .notifications: L10n.Permission.notifications
        case .locationWhenInUse: L10n.Permission.location
        case .camera: L10n.Permission.camera
        case .microphone: L10n.Permission.microphone
        case .photos: L10n.Permission.photos
        case .contacts: L10n.Permission.contacts
        case .tracking: L10n.Permission.tracking
        }
    }
}

#Preview("Not asked") {
    PermissionGate(.camera, rationale: "Scan product barcodes to find them faster.") { Color.green }
        .environment(
            \.permissionManager, FixedPermissionManager(statuses: [.camera: .notDetermined], afterRequest: .granted))
}

#Preview("Denied") {
    PermissionGate(.photos, rationale: "Pick a photo for your profile.") { Color.green }
        .environment(\.permissionManager, FixedPermissionManager(statuses: [.photos: .denied], afterRequest: .denied))
}
