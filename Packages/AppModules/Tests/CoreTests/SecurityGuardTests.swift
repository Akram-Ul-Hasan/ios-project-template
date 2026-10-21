import Testing

@testable import Core

@Suite("SecurityGuard")
struct SecurityGuardTests {
    private func guardWith(
        paths: Set<String> = [], sandboxWrite: Bool = false, bundle: String? = "com.technonext.projecttemplate.dev"
    )
        -> SecurityGuard
    {
        SecurityGuard(
            expectedBundlePrefix: "com.technonext.projecttemplate", bundleIdentifier: bundle,
            fileExists: { paths.contains($0) }, canWriteOutsideSandbox: { sandboxWrite })
    }

    @Test("Jailbreak signals: known paths or a write outside the sandbox")
    func jailbreak() {
        #expect(!guardWith().hasJailbreakSignals())
        #expect(guardWith(paths: ["/Applications/Cydia.app"]).hasJailbreakSignals())
        #expect(guardWith(sandboxWrite: true).hasJailbreakSignals())
    }

    @Test("Off-device (simulator, macOS) jailbreak checks never fire")
    func offDevice() {
        #expect(!guardWith(paths: ["/Applications/Cydia.app"]).evaluate().isJailbroken)
    }

    @Test("A foreign bundle id means a repackaged copy; flavor suffixes are fine")
    func bundle() {
        #expect(!guardWith(bundle: "com.technonext.projecttemplate.stg").evaluate().isUnexpectedBundle)
        #expect(guardWith(bundle: "com.attacker.clone").evaluate().isUnexpectedBundle)
        #expect(guardWith(bundle: nil).evaluate().isUnexpectedBundle)
    }

    @Test("Debugger detection runs without crashing")
    func debugger() {
        _ = SecurityGuard.isDebuggerAttached()
    }

    @Test("Only production restricts sensitive actions on a compromised device")
    func policy() {
        let compromised = SecurityReport(
            isJailbroken: true, isDebuggerAttached: false, isSimulator: false, isUnexpectedBundle: false)
        let clean = SecurityReport(
            isJailbroken: false, isDebuggerAttached: false, isSimulator: true, isUnexpectedBundle: false)
        #expect(SecurityPolicy(environment: .development).allowsSensitiveActions(compromised))
        #expect(SecurityPolicy(environment: .staging).allowsSensitiveActions(compromised))
        #expect(!SecurityPolicy(environment: .production).allowsSensitiveActions(compromised))
        #expect(SecurityPolicy(environment: .production).allowsSensitiveActions(clean))
    }
}
