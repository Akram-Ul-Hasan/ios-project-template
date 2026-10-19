import Testing

@testable import Core

@Suite("PermissionManager")
struct PermissionManagerTests {
    private struct Fake: PermissionHandler {
        let current: PermissionStatus
        let afterRequest: PermissionStatus
        func status() async -> PermissionStatus { current }
        func request() async -> PermissionStatus { afterRequest }
    }

    @Test("Dispatches to the handler for each permission")
    func dispatch() async {
        let manager = SystemPermissionManager(handlers: [
            .camera: Fake(current: .notDetermined, afterRequest: .granted),
            .photos: Fake(current: .limited, afterRequest: .limited),
        ])
        #expect(await manager.status(of: .camera) == .notDetermined)
        #expect(await manager.request(.camera) == .granted)
        #expect(await manager.status(of: .photos) == .limited)
    }

    @Test("A permission without a handler is treated as restricted")
    func missingHandler() async {
        let manager = SystemPermissionManager(handlers: [:])
        #expect(await manager.status(of: .contacts) == .restricted)
        #expect(await manager.request(.contacts) == .restricted)
    }

    @Test("Usable means granted or limited")
    func usable() {
        #expect(PermissionStatus.granted.isUsable && PermissionStatus.limited.isUsable)
        #expect(!PermissionStatus.denied.isUsable && !PermissionStatus.restricted.isUsable)
        #expect(!PermissionStatus.notDetermined.isUsable)
    }

    @Test("FixedPermissionManager returns what it was given")
    func fixed() async {
        let manager = FixedPermissionManager(statuses: [.camera: .denied], afterRequest: .granted)
        #expect(await manager.status(of: .camera) == .denied)
        #expect(await manager.status(of: .photos) == .notDetermined)
        #expect(await manager.request(.photos) == .granted)
    }
}
