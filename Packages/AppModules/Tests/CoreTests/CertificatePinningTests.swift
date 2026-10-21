import Foundation
import Security
import Testing

@testable import Core

/// Expected pins were produced with openssl (`openssl pkey -pubin -outform der | openssl dgst -sha256 -binary | base64`),
/// so these tests prove the delegate computes the same value the server team will hand over.
@Suite("CertificatePinningDelegate")
struct CertificatePinningTests {
    private func key(_ base64: String, type: CFString, bits: Int) throws -> SecKey {
        let data = try #require(Data(base64Encoded: base64))
        let attributes: [CFString: Any] = [
            kSecAttrKeyType: type, kSecAttrKeyClass: kSecAttrKeyClassPublic, kSecAttrKeySizeInBits: bits,
        ]
        return try #require(SecKeyCreateWithData(data as CFData, attributes as CFDictionary, nil))
    }

    @Test("EC P-256 key hash matches openssl")
    func ecPin() throws {
        let raw = "BMcV98FrWJS8XTvo9gpQ0wo1p/AL1ib9z8tpCvoXV8cthTI+Dibnd4k8GNSXzQBok01xUbtiSXHGgZMLvg1/570="
        let ecKey = try key(raw, type: kSecAttrKeyTypeECSECPrimeRandom, bits: 256)
        #expect(CertificatePinningDelegate.spkiHash(of: ecKey) == "XHjwzyRb7pLhQzPTA3jRTdLsKgu7cCrjzAbBL93snaI=")
    }

    @Test("RSA 2048 key hash matches openssl")
    func rsaPin() throws {
        let pkcs1 =
            "MIIBCgKCAQEAnQ0KQhdgDb4kDmt0s9Y0NsEyfTq/tzbcRA4d3qvSSzR+L7h9fKtbnz/dakladDqqbiWwWDpkhjtlWpNCp28Ex+pf1UoWwASjTZXYub/Sx/6S8MwXdUFx28r2i24fhGSvO4HL0OIPz/EG8bfXheBVOeSUQY4YhABXBs6RbAGmHT04Quk8oZ79CdWDk1/McdztIapg+GUP8TYVilAZI3upvRh3EypShz3GKVbLQEK6Kd3z9JKl+NnlZhAz9EuDWtpwlpA+PWzSazsTqKZ7g5qxRlyMde3xiAVXDb8XhQFcMGgAP8rpoU66EtJwdA22+/j6oFsAGJc/iIwD7v0sRGavfQIDAQAB"
        let rsaKey = try key(pkcs1, type: kSecAttrKeyTypeRSA, bits: 2048)
        #expect(CertificatePinningDelegate.spkiHash(of: rsaKey) == "uHF6yL4vpVIOJdy2WITNKIE9KVBWhnWGqnrA5g5DoH8=")
    }

    @Test("Unsupported key sizes have no header, so they never match")
    func unsupported() {
        #expect(CertificatePinningDelegate.spkiHeader(keyType: kSecAttrKeyTypeRSA as String, bits: 1024) == nil)
        #expect(
            CertificatePinningDelegate.spkiHeader(keyType: kSecAttrKeyTypeECSECPrimeRandom as String, bits: 521) == nil)
    }
}
