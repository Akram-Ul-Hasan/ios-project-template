import Testing

/// Parent for suites that switch the process-wide active language: `.serialized` applies to everything nested,
/// so they never run at the same time as each other.
@Suite(.serialized)
enum LanguageSensitive {}
