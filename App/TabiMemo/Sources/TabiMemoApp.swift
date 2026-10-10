import SwiftUI

@main
struct TabiMemoApp: App {
    private let dependencies: AppDependencies

    init() {
        do {
            dependencies = try AppDependencies.live()
        } catch {
            fatalError("保存先を開けませんでした: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            dependencies.makeTripMapView()
        }
    }
}
