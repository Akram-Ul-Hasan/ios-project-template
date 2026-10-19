// swift-tools-version: 6.0
// Target graph (§4): every edge points to a LOWER level. scripts/check_target_graph.sh enforces it.
//
//   L3  <F>Presentation → <F>Domain, <G>Domain, DesignSystem, Core, SharedDomain, Localization
//   L3  <F>Data         → <F>Domain, Core, SharedDomain
//   L2  DesignSystem    → Core, SharedDomain, Localization
//   L2  <F>Domain       → SharedDomain, <G>Domain
//   L1  Core            → SharedDomain, Localization
//   L0  SharedDomain, Localization → (nothing)
import PackageDescription

let package = Package(
    name: "AppModules",
    defaultLocalization: "en",
    platforms: [.iOS(.v17)],
    products: [
        .library(
            name: "AppModules",
            targets: [
                "Localization", "SharedDomain", "Core", "DesignSystem",
            ])
    ],
    targets: [
        // L0
        .target(name: "Localization"),
        .target(name: "SharedDomain"),
        // L1
        .target(name: "Core", dependencies: ["SharedDomain", "Localization"]),
        // L2
        .target(name: "DesignSystem", dependencies: ["Core", "SharedDomain", "Localization"]),
        // Tests
        .target(name: "TestSupport", dependencies: ["Core", "SharedDomain"], path: "Tests/TestSupport"),
        .testTarget(name: "CoreTests", dependencies: ["Core", "TestSupport"]),
    ],
    swiftLanguageModes: [.v6]
)
