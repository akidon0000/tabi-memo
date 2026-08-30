import SwiftData
import SwiftUI

@main
struct TabiMemoApp: App {
    let modelContainer: ModelContainer

    init() {
        do {
            let schema = Schema([Trip.self, LocationPoint.self, TripPhoto.self])
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            modelContainer = try ModelContainer(for: schema, configurations: config)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            TripListView()
        }
        .modelContainer(modelContainer)
    }
}
