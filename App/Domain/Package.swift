// swift-tools-version: 6.2
import PackageDescription

// Domain は Foundation だけに依存する。既定のアクターは nonisolated(プロトコルと UseCase は個別に @MainActor を付ける)。
let package = Package(
    name: "Domain",
    platforms: [.iOS("27.0")],
    products: [
        .library(name: "Domain", targets: ["Domain"]),
        .library(name: "TestSupport", targets: ["TestSupport"]),
    ],
    dependencies: [.package(url: "https://github.com/SimplyDanny/SwiftLintPlugins", exact: "0.65.1")],
    targets: [
        .target(name: "Domain", plugins: [.plugin(name: "SwiftLintBuildToolPlugin", package: "SwiftLintPlugins")]),
        .target(name: "TestSupport", dependencies: ["Domain"], plugins: [.plugin(name: "SwiftLintBuildToolPlugin", package: "SwiftLintPlugins")]),
        .testTarget(name: "DomainTests", dependencies: ["Domain", "TestSupport"], plugins: [.plugin(name: "SwiftLintBuildToolPlugin", package: "SwiftLintPlugins")]),
    ]
)
