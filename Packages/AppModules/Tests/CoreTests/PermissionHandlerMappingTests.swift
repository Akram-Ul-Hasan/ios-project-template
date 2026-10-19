import AVFoundation
import CoreLocation
import Photos
import Testing
import UserNotifications

@testable import Core

@Suite("Permission handler mapping")
struct PermissionHandlerMappingTests {
    @Test("Notifications: provisional counts as limited")
    func notifications() {
        #expect(NotificationPermissionHandler.map(.authorized) == .granted)
        #expect(NotificationPermissionHandler.map(.provisional) == .limited)
        #expect(NotificationPermissionHandler.map(.denied) == .denied)
    }

    @Test("Location: approximate accuracy counts as limited")
    func location() {
        #expect(LocationPermissionHandler.map(.authorizedAlways, reducedAccuracy: false) == .granted)
        #expect(LocationPermissionHandler.map(.authorizedAlways, reducedAccuracy: true) == .limited)
        #expect(LocationPermissionHandler.map(.restricted, reducedAccuracy: false) == .restricted)
    }

    @Test("Photos: selected photos counts as limited")
    func photos() {
        #expect(PhotosPermissionHandler.map(.limited) == .limited)
        #expect(PhotosPermissionHandler.map(.authorized) == .granted)
    }

    @Test("Camera and microphone")
    func capture() {
        #expect(CapturePermissionHandler.map(.notDetermined) == .notDetermined)
        #expect(CapturePermissionHandler.map(.authorized) == .granted)
    }
}
