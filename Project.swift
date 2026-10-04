import ProjectDescription

// 層の構成は docs/handbook/architecture.md。依存の向きは App → Data → Domain の一方向で、
// ターゲットを分けてコンパイラに守らせる(Domain から SwiftData や SwiftUI は import できない)。

let deploymentTarget = "27.0"

/// SwiftLint をビルド時に走らせる(ルールは .swiftlint.yml)。
let swiftLint = TargetDependency.package(product: "SwiftLintBuildToolPlugin", type: .plugin)

let project = Project(
    name: "TabiMemo",
    options: .options(
        defaultKnownRegions: ["ja", "en"],
        developmentRegion: "ja"
    ),
    packages: [
        .remote(url: "https://github.com/SimplyDanny/SwiftLintPlugins", requirement: .exact("0.65.1")),
    ],
    settings: .settings(base: [
        "SWIFT_VERSION": "6.0",
        "IPHONEOS_DEPLOYMENT_TARGET": "\(deploymentTarget)",
        "SWIFT_STRICT_CONCURRENCY": "complete",
        "SWIFT_DEFAULT_ACTOR_ISOLATION": "MainActor",
        // 配信用。バージョンは Info.plist から $(...) で参照する(リテラルだと上書きが効かない)。
        "DEVELOPMENT_TEAM": "XSC9AJPSP3",
        "MARKETING_VERSION": "1.0",
        "CURRENT_PROJECT_VERSION": "1",
    ]),
    targets: [
        // 純粋な型とルール。Foundation だけに依存する。既定のアクターは持たせず、必要な型だけ @MainActor を書く。
        .target(
            name: "Domain",
            destinations: .iOS,
            product: .framework,
            bundleId: "com.akidon0000.tabimemo.domain",
            deploymentTargets: .iOS(deploymentTarget),
            sources: ["Domain/Sources/**"],
            dependencies: [swiftLint],
            settings: .settings(base: ["SWIFT_DEFAULT_ACTOR_ISOLATION": "nonisolated"])
        ),
        .target(
            name: "DomainTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.akidon0000.tabimemo.domain-tests",
            deploymentTargets: .iOS(deploymentTarget),
            sources: ["Domain/Tests/**", "TestSupport/**"],
            dependencies: [.target(name: "Domain")]
        ),
        // 保存と外部(写真のメタデータ・AI)の実装。Domain のプロトコルを満たす。
        .target(
            name: "DataLayer",
            destinations: .iOS,
            product: .framework,
            bundleId: "com.akidon0000.tabimemo.datalayer",
            deploymentTargets: .iOS(deploymentTarget),
            sources: ["DataLayer/Sources/**"],
            dependencies: [.target(name: "Domain"), swiftLint]
        ),
        .target(
            name: "DataLayerTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.akidon0000.tabimemo.datalayer-tests",
            deploymentTargets: .iOS(deploymentTarget),
            sources: ["DataLayer/Tests/**"],
            dependencies: [.target(name: "DataLayer")]
        ),
        .target(
            name: "TabiMemo",
            destinations: .iOS,
            product: .app,
            bundleId: "com.akidon0000.tabimemo",
            deploymentTargets: .iOS(deploymentTarget),
            infoPlist: .extendingDefault(with: [
                "CFBundleDisplayName": "旅メモ",
                "CFBundleShortVersionString": "$(MARKETING_VERSION)",
                "CFBundleVersion": "$(CURRENT_PROJECT_VERSION)",
                "ITSAppUsesNonExemptEncryption": false,
                "UILaunchScreen": [:],
                "NSLocationWhenInUseUsageDescription": "トリップ記録中の現在地を地図に表示するために使用します",
                "NSLocationAlwaysAndWhenInUseUsageDescription": "トリップ記録中はアプリを閉じていても経路を記録し続けるために使用します",
                "NSCameraUsageDescription": "撮影した写真をその場所のピンとして記録するために使用します",
                "NSPhotoLibraryUsageDescription": "トリップ中に撮った写真をライブラリから選んで経路に追加するために使用します",
                "UIBackgroundModes": ["location"],
            ]),
            sources: ["TabiMemo/Sources/**"],
            resources: ["TabiMemo/Resources/**"],
            dependencies: [.target(name: "Domain"), .target(name: "DataLayer"), swiftLint]
        ),
        .target(
            name: "TabiMemoTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.akidon0000.tabimemo.tests",
            deploymentTargets: .iOS(deploymentTarget),
            infoPlist: .default,
            sources: ["TabiMemo/Tests/**", "TestSupport/**"],
            dependencies: [.target(name: "TabiMemo"), .target(name: "Domain")]
        ),
    ],
    schemes: [
        // テストは層ごとの3ターゲットを、このスキーム1つでまとめて動かす。
        .scheme(
            name: "TabiMemo",
            shared: true,
            buildAction: .buildAction(targets: ["TabiMemo"]),
            testAction: .targets(["DomainTests", "DataLayerTests", "TabiMemoTests"]),
            runAction: .runAction(executable: "TabiMemo"),
            archiveAction: .archiveAction(configuration: .release)
        ),
    ]
)
