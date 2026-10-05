// swift-tools-version: 6.2
import PackageDescription

// 画面ごとのモジュール。依存の向きはここ(dependsOn)で決まり、逆向きの import はビルドが失敗する。
// 画面を足すときは、products と targets に1行ずつ足す(docs/handbook/architecture.md の「画面を1つ足す」)。

let domain = Target.Dependency.product(name: "Domain", package: "Domain")
let swiftLint = Target.PluginUsage.plugin(name: "SwiftLintBuildToolPlugin", package: "SwiftLintPlugins")

/// 画面のターゲット。Domain と SharedUI への依存、MainActor 既定、SwiftLint は全画面で共通。
@MainActor func feature(_ name: String, dependsOn screens: [Target.Dependency] = []) -> Target {
    .target(
        name: name,
        dependencies: [domain, "SharedUI"] + screens,
        swiftSettings: [.defaultIsolation(MainActor.self)],
        plugins: [swiftLint]
    )
}

let package = Package(
    name: "Features",
    platforms: [.iOS("27.0")],
    products: [
        .library(name: "SharedUI", targets: ["SharedUI"]),
        .library(name: "EditPhotoFeature", targets: ["EditPhotoFeature"]),
        .library(name: "AddPhotosFeature", targets: ["AddPhotosFeature"]),
        .library(name: "PhotoListFeature", targets: ["PhotoListFeature"]),
        .library(name: "RecentlyDeletedFeature", targets: ["RecentlyDeletedFeature"]),
        .library(name: "TripMapFeature", targets: ["TripMapFeature"]),
    ],
    dependencies: [
        .package(path: "../Domain"),
        .package(url: "https://github.com/SimplyDanny/SwiftLintPlugins", exact: "0.65.1"),
    ],
    targets: [
        .target(
            name: "SharedUI",
            dependencies: [domain],
            swiftSettings: [.defaultIsolation(MainActor.self)],
            plugins: [swiftLint]
        ),
        feature("EditPhotoFeature"),
        feature("AddPhotosFeature"),
        feature("PhotoListFeature", dependsOn: ["EditPhotoFeature"]),
        feature("RecentlyDeletedFeature"),
        feature("TripMapFeature", dependsOn: ["EditPhotoFeature", "PhotoListFeature", "RecentlyDeletedFeature", "AddPhotosFeature"]),
        .testTarget(
            name: "FeaturesTests",
            dependencies: [
                "SharedUI", "EditPhotoFeature", "AddPhotosFeature", "PhotoListFeature", "RecentlyDeletedFeature", "TripMapFeature",
                domain, .product(name: "TestSupport", package: "Domain"),
            ],
            swiftSettings: [.defaultIsolation(MainActor.self)],
            plugins: [swiftLint]
        ),
    ]
)
