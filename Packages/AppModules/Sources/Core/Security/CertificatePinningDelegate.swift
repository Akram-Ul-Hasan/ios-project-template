import CryptoKit
import Foundation
import Security

/// Public-key pinning (§6l). The server's chain must pass normal trust evaluation and contain at least one
/// certificate whose SubjectPublicKeyInfo SHA-256 (base64) is pinned. Pin an intermediate or leaf key plus a
/// backup key, so a certificate rotation doesn't lock users out. Get a pin with:
/// `openssl s_client -connect host:443 </dev/null | openssl x509 -pubkey -noout | openssl pkey -pubin -outform der | openssl dgst -sha256 -binary | base64`
public final class CertificatePinningDelegate: NSObject, URLSessionDelegate, Sendable {
    private let host: String
    private let pins: Set<String>

    /// Only `host` is pinned; other hosts (e.g. an image CDN) get default handling.
    public init(host: String, pins: Set<String>) {
        self.host = host.lowercased()
        self.pins = pins
    }

    public func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge
    ) async -> (URLSession.AuthChallengeDisposition, URLCredential?) {
        let space = challenge.protectionSpace
        guard space.authenticationMethod == NSURLAuthenticationMethodServerTrust,
            space.host.lowercased() == host, let trust = space.serverTrust
        else { return (.performDefaultHandling, nil) }

        guard SecTrustEvaluateWithError(trust, nil), Self.chainMatches(trust, pins: pins) else {
            AppLogger.security.fault("certificate pinning failed for \(space.host, privacy: .public)")
            return (.cancelAuthenticationChallenge, nil)
        }
        return (.useCredential, URLCredential(trust: trust))
    }

    static func chainMatches(_ trust: SecTrust, pins: Set<String>) -> Bool {
        let chain = (SecTrustCopyCertificateChain(trust) as? [SecCertificate]) ?? []
        return chain.contains { certificate in
            SecCertificateCopyKey(certificate).flatMap(spkiHash).map(pins.contains) ?? false
        }
    }

    /// base64(SHA-256(SubjectPublicKeyInfo)): the raw key from Security plus its ASN.1 algorithm header.
    static func spkiHash(of key: SecKey) -> String? {
        guard let attributes = SecKeyCopyAttributes(key) as? [CFString: Any],
            let type = attributes[kSecAttrKeyType] as? String,
            let bits = attributes[kSecAttrKeySizeInBits] as? Int,
            let header = spkiHeader(keyType: type, bits: bits),
            let raw = SecKeyCopyExternalRepresentation(key, nil) as Data?
        else { return nil }
        return Data(SHA256.hash(data: header + raw)).base64EncodedString()
    }

    static func spkiHeader(keyType: String, bits: Int) -> Data? {
        let algorithm: KeyAlgorithm
        if keyType == (kSecAttrKeyTypeRSA as String) {
            algorithm = .rsa
        } else if keyType == (kSecAttrKeyTypeECSECPrimeRandom as String) {
            algorithm = .ec
        } else {
            return nil
        }
        return headers[KeySpec(algorithm: algorithm, bits: bits)]
    }

    private enum KeyAlgorithm {
        case rsa
        case ec
    }

    private struct KeySpec: Hashable {
        let algorithm: KeyAlgorithm
        let bits: Int
    }

    /// ASN.1 SubjectPublicKeyInfo prefixes for the key types servers use.
    private static let headers: [KeySpec: Data] = [
        KeySpec(algorithm: .rsa, bits: 2048): Data([
            0x30, 0x82, 0x01, 0x22, 0x30, 0x0D, 0x06, 0x09, 0x2A, 0x86, 0x48, 0x86, 0xF7, 0x0D, 0x01, 0x01, 0x01,
            0x05, 0x00, 0x03, 0x82, 0x01, 0x0F, 0x00,
        ]),
        KeySpec(algorithm: .rsa, bits: 4096): Data([
            0x30, 0x82, 0x02, 0x22, 0x30, 0x0D, 0x06, 0x09, 0x2A, 0x86, 0x48, 0x86, 0xF7, 0x0D, 0x01, 0x01, 0x01,
            0x05, 0x00, 0x03, 0x82, 0x02, 0x0F, 0x00,
        ]),
        KeySpec(algorithm: .ec, bits: 256): Data([
            0x30, 0x59, 0x30, 0x13, 0x06, 0x07, 0x2A, 0x86, 0x48, 0xCE, 0x3D, 0x02, 0x01, 0x06, 0x08, 0x2A, 0x86,
            0x48, 0xCE, 0x3D, 0x03, 0x01, 0x07, 0x03, 0x42, 0x00,
        ]),
        KeySpec(algorithm: .ec, bits: 384): Data([
            0x30, 0x76, 0x30, 0x10, 0x06, 0x07, 0x2A, 0x86, 0x48, 0xCE, 0x3D, 0x02, 0x01, 0x06, 0x05, 0x2B, 0x81,
            0x04, 0x00, 0x22, 0x03, 0x62, 0x00,
        ]),
    ]
}
