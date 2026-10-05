// swift-tools-version: 6.2
import PackageDescription

// 画面ごとのモジュール。依存の向きはここ(dependencies)で決まり、逆向きの import はビルドが失敗する。
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
            dependencies: [.product(name: "Domain", package: "Domain")],
            swiftSettings: [.defaultIsolation(MainActor.self)],
            plugins: [.plugin(name: "SwiftLintBuildToolPlugin", package: "SwiftLintPlugins")]
        ),
        .target(
            name: "EditPhotoFeature",
            dependencies: [.product(name: "Domain", package: "Domain"), "SharedUI"],
            swiftSettings: [.defaultIsolation(MainActor.self)],
            plugins: [.plugin(name: "SwiftLintBuildToolPlugin", package: "SwiftLintPlugins")]
        ),
        .target(
            name: "AddPhotosFeature",
            dependencies: [.product(name: "Domain", package: "Domain"), "SharedUI"],
            swiftSettings: [.defaultIsolation(MainActor.self)],
            plugins: [.plugin(name: "SwiftLintBuildToolPlugin", package: "SwiftLintPlugins")]
        ),
        .target(
            name: "PhotoListFeature",
            dependencies: [.product(name: "Domain", package: "Domain"), "SharedUI", "EditPhotoFeature"],
            swiftSettings: [.defaultIsolation(MainActor.self)],
            plugins: [.plugin(name: "SwiftLintBuildToolPlugin", package: "SwiftLintPlugins")]
        ),
        .target(
            name: "RecentlyDeletedFeature",
            dependencies: [.product(name: "Domain", package: "Domain"), "SharedUI"],
            swiftSettings: [.defaultIsolation(MainActor.self)],
            plugins: [.plugin(name: "SwiftLintBuildToolPlugin", package: "SwiftLintPlugins")]
        ),
        .target(
            name: "TripMapFeature",
            dependencies: [.product(name: "Domain", package: "Domain"), "SharedUI", "EditPhotoFeature", "PhotoListFeature", "RecentlyDeletedFeature", "AddPhotosFeature"],
            swiftSettings: [.defaultIsolation(MainActor.self)],
            plugins: [.plugin(name: "SwiftLintBuildToolPlugin", package: "SwiftLintPlugins")]
        ),
        .testTarget(
            name: "FeaturesTests",
            dependencies: ["SharedUI", "EditPhotoFeature", "AddPhotosFeature", "PhotoListFeature", "RecentlyDeletedFeature", "TripMapFeature", .product(name: "Domain", package: "Domain"), .product(name: "TestSupport", package: "Domain")],
            swiftSettings: [.defaultIsolation(MainActor.self)],
            plugins: [.plugin(name: "SwiftLintBuildToolPlugin", package: "SwiftLintPlugins")]
        ),
    ]
)
