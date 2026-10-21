#if canImport(UIKit)
    import UIKit
#endif

/// Push permission and APNs registration (§6c, §6j). Ask after onboarding or the first order, never at launch.
@MainActor
public struct PushPermissionService {
    private let permissions: any PermissionManager

    public init(permissions: any PermissionManager) {
        self.permissions = permissions
    }

    /// Shows the system prompt if needed, then registers for remote notifications when allowed.
    @discardableResult
    public func requestAndRegister() async -> PermissionStatus {
        let status = await permissions.request(.notifications)
        if status.isUsable { register() }
        return status
    }

    /// At launch: refreshes the APNs token only if the user already allowed notifications. Never prompts.
    public func registerIfAuthorized() async {
        if await permissions.status(of: .notifications).isUsable { register() }
    }

    private func register() {
        #if canImport(UIKit)
            UIApplication.shared.registerForRemoteNotifications()
        #endif
    }
}
