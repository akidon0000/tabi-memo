import SwiftUI

@main
struct TabiMemoApp: App {
    @State private var dependencies: AppDependencies
    @State private var tripMapViewModel: TripMapViewModel

    init() {
        do {
            let dependencies = try AppDependencies.live()
            _dependencies = State(initialValue: dependencies)
            _tripMapViewModel = State(initialValue: dependencies.makeTripMapViewModel())
        } catch {
            fatalError("保存先を開けませんでした: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            TripMapView(viewModel: tripMapViewModel)
                .environment(dependencies)
        }
    }
}
