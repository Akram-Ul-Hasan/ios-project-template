import CryptoKit
import DeviceCheck
import Foundation

/// App Attest (§6l): lets the backend verify that requests come from the genuine app on a real Apple device,
/// not a modified or scripted client. Needs backend support:
/// 1. backend issues a one-time challenge → `attest(challenge:)` → send `keyID` + `attestation` to the backend once;
/// 2. for protected requests, `assertion(for: requestBody)` → send it in a header for the backend to verify.
public protocol AppAttesting: Sendable {
    var isSupported: Bool { get }
    func attest(challenge: Data) async throws -> (keyID: String, attestation: Data)
    func assertion(for requestData: Data) async throws -> (keyID: String, assertion: Data)
}

public enum AppAttestError: Error, Equatable, Sendable {
    /// Simulator, Mac, or an old device: fall back to server-side risk checks.
    case unsupported
    /// `assertion` was called before a successful `attest`.
    case notAttested
}

public struct AppAttestService: AppAttesting {
    private let keychain: any KeychainStoring

    public init(keychain: any KeychainStoring) {
        self.keychain = keychain
    }

    public var isSupported: Bool { DCAppAttestService.shared.isSupported }

    public func attest(challenge: Data) async throws -> (keyID: String, attestation: Data) {
        guard isSupported else { throw AppAttestError.unsupported }
        let keyID = try await existingOrNewKeyID()
        let attestation = try await DCAppAttestService.shared.attestKey(keyID, clientDataHash: Self.hash(challenge))
        return (keyID, attestation)
    }

    public func assertion(for requestData: Data) async throws -> (keyID: String, assertion: Data) {
        guard isSupported else { throw AppAttestError.unsupported }
        guard let stored = try keychain.data(for: .appAttestKeyID) else { throw AppAttestError.notAttested }
        let keyID = String(decoding: stored, as: UTF8.self)
        let assertion = try await DCAppAttestService.shared.generateAssertion(
            keyID, clientDataHash: Self.hash(requestData))
        return (keyID, assertion)
    }

    private func existingOrNewKeyID() async throws -> String {
        if let stored = try keychain.data(for: .appAttestKeyID) { return String(decoding: stored, as: UTF8.self) }
        let keyID = try await DCAppAttestService.shared.generateKey()
        try keychain.set(Data(keyID.utf8), for: .appAttestKeyID)
        return keyID
    }

    static func hash(_ data: Data) -> Data {
        Data(SHA256.hash(data: data))
    }
}
