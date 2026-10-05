// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "DataLayer",
    platforms: [.iOS("27.0")],
    products: [.library(name: "DataLayer", targets: ["DataLayer"])],
    dependencies: [.package(path: "../Domain"), .package(url: "https://github.com/SimplyDanny/SwiftLintPlugins", exact: "0.65.1")],
    targets: [
        .target(
            name: "DataLayer",
            dependencies: [.product(name: "Domain", package: "Domain")],
            swiftSettings: [.defaultIsolation(MainActor.self)],
            plugins: [.plugin(name: "SwiftLintBuildToolPlugin", package: "SwiftLintPlugins")]
        ),
        .testTarget(
            name: "DataLayerTests",
            dependencies: ["DataLayer", .product(name: "Domain", package: "Domain")],
            swiftSettings: [.defaultIsolation(MainActor.self)],
            plugins: [.plugin(name: "SwiftLintBuildToolPlugin", package: "SwiftLintPlugins")]
        ),
    ]
)
