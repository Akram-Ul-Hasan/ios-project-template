import Darwin
import Foundation

/// Device-integrity signals (§6l). Signals, not proof: a determined attacker can hide them, which is why
/// the server stays the real authority (and App Attest can back it up).
public struct SecurityReport: Equatable, Sendable {
    public let isJailbroken: Bool
    public let isDebuggerAttached: Bool
    public let isSimulator: Bool
    /// The running bundle id isn't one of ours: a re-signed or repackaged copy.
    public let isUnexpectedBundle: Bool

    public init(isJailbroken: Bool, isDebuggerAttached: Bool, isSimulator: Bool, isUnexpectedBundle: Bool) {
        self.isJailbroken = isJailbroken
        self.isDebuggerAttached = isDebuggerAttached
        self.isSimulator = isSimulator
        self.isUnexpectedBundle = isUnexpectedBundle
    }

    /// Anything that suggests a tampered environment.
    public var isCompromised: Bool { isJailbroken || isDebuggerAttached || isUnexpectedBundle }
}

public struct SecurityGuard: Sendable {
    private let fileExists: @Sendable (String) -> Bool
    private let canWriteOutsideSandbox: @Sendable () -> Bool
    private let bundleIdentifier: String?
    private let expectedBundlePrefix: String

    /// Paths only present on jailbroken devices.
    static let jailbreakPaths = [
        "/Applications/Cydia.app", "/Applications/Sileo.app", "/Library/MobileSubstrate/MobileSubstrate.dylib",
        "/usr/sbin/sshd", "/etc/apt", "/private/var/lib/apt/", "/var/jb", "/usr/lib/libjailbreak.dylib",
    ]

    /// `expectedBundlePrefix`: the base bundle id; flavor suffixes (`.dev`, `.stg`) are allowed.
    public init(
        expectedBundlePrefix: String,
        bundleIdentifier: String? = Bundle.main.bundleIdentifier,
        fileExists: @escaping @Sendable (String) -> Bool = { FileManager.default.fileExists(atPath: $0) },
        canWriteOutsideSandbox: @escaping @Sendable () -> Bool = SecurityGuard.sandboxWriteSucceeds
    ) {
        self.expectedBundlePrefix = expectedBundlePrefix
        self.bundleIdentifier = bundleIdentifier
        self.fileExists = fileExists
        self.canWriteOutsideSandbox = canWriteOutsideSandbox
    }

    public func evaluate() -> SecurityReport {
        #if targetEnvironment(simulator)
            let isSimulator = true
        #else
            let isSimulator = false
        #endif
        // Jailbreak checks only mean something on a real iOS device.
        #if os(iOS) && !targetEnvironment(simulator)
            let jailbroken = hasJailbreakSignals()
        #else
            let jailbroken = false
        #endif
        let unexpected = bundleIdentifier.map { !$0.hasPrefix(expectedBundlePrefix) } ?? true
        return SecurityReport(
            isJailbroken: jailbroken, isDebuggerAttached: Self.isDebuggerAttached(), isSimulator: isSimulator,
            isUnexpectedBundle: unexpected)
    }

    func hasJailbreakSignals() -> Bool {
        Self.jailbreakPaths.contains(where: fileExists) || canWriteOutsideSandbox()
    }

    /// `P_TRACED` from sysctl: true while a debugger is attached.
    static func isDebuggerAttached() -> Bool {
        var info = kinfo_proc()
        var size = MemoryLayout<kinfo_proc>.stride
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]
        let result = sysctl(&mib, u_int(mib.count), &info, &size, nil, 0)
        return result == 0 && (info.kp_proc.p_flag & P_TRACED) != 0
    }

    /// A sandboxed app can't write outside its container; on a jailbroken device it can.
    public static func sandboxWriteSucceeds() -> Bool {
        let path = "/private/\(UUID().uuidString).txt"
        do {
            try Data().write(to: URL(filePath: path))
            try? FileManager.default.removeItem(atPath: path)
            return true
        } catch {
            return false
        }
    }
}

/// What the app does about a compromised device, per flavor (§6l).
public enum SecurityPolicy: Sendable {
    /// Development: debuggers and simulators are normal.
    case ignore
    /// Staging: log, so QA sees it, but don't block testing.
    case log
    /// Production: log and refuse sensitive actions (checkout, payment, changing credentials).
    case logAndRestrict

    public init(environment: AppEnvironment) {
        switch environment {
        case .development: self = .ignore
        case .staging: self = .log
        case .production: self = .logAndRestrict
        }
    }

    /// Call when the app starts; logs according to the policy.
    public func record(_ report: SecurityReport) {
        guard self != .ignore, report.isCompromised else { return }
        AppLogger.security.fault(
            "device integrity: jailbreak=\(report.isJailbroken, privacy: .public) debugger=\(report.isDebuggerAttached, privacy: .public) repackaged=\(report.isUnexpectedBundle, privacy: .public)"
        )
    }

    /// Gate for sensitive flows: `guard securityPolicy.allowsSensitiveActions(report) else { … }`.
    public func allowsSensitiveActions(_ report: SecurityReport) -> Bool {
        self != .logAndRestrict || !report.isCompromised
    }
}
