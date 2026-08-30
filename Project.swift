import ProjectDescription

let project = Project(
    name: "TabiMemo",
    options: .options(
        defaultKnownRegions: ["ja", "en"],
        developmentRegion: "ja"
    ),
    settings: .settings(base: [
        "SWIFT_VERSION": "6.0",
        "IPHONEOS_DEPLOYMENT_TARGET": "26.0",
        "SWIFT_STRICT_CONCURRENCY": "complete",
        "SWIFT_DEFAULT_ACTOR_ISOLATION": "MainActor",
    ]),
    targets: [
        .target(
            name: "TabiMemo",
            destinations: .iOS,
            product: .app,
            bundleId: "com.akidon0000.tabimemo",
            deploymentTargets: .iOS("26.0"),
            infoPlist: .extendingDefault(with: [
                "CFBundleDisplayName": "旅メモ",
                "UILaunchScreen": [:],
                "NSLocationWhenInUseUsageDescription": "トリップ記録中の現在地を地図に表示するために使用します",
                "NSLocationAlwaysAndWhenInUseUsageDescription": "トリップ記録中はアプリを閉じていても経路を記録し続けるために使用します",
                "NSCameraUsageDescription": "撮影した写真をその場所のピンとして記録するために使用します",
                "NSPhotoLibraryUsageDescription": "トリップ中に撮った写真をライブラリから選んで経路に追加するために使用します",
                "UIBackgroundModes": ["location"],
            ]),
            sources: ["TabiMemo/Sources/**"],
            resources: ["TabiMemo/Resources/**"]
        ),
        .target(
            name: "TabiMemoTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.akidon0000.tabimemo.tests",
            deploymentTargets: .iOS("26.0"),
            infoPlist: .default,
            sources: ["TabiMemo/Tests/**"],
            dependencies: [.target(name: "TabiMemo")]
        ),
    ]
)
