import SwiftUI

@main
struct TabiMemoApp: App {
    @State private var dependencies: AppDependencies

    init() {
        do {
            _dependencies = State(initialValue: try AppDependencies.live())
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
