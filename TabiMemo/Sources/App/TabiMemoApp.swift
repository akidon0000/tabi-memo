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
            SampleData.seedIfNeeded(modelContainer.mainContext)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            MapRootView()
        }
        .modelContainer(modelContainer)
    }
}

/// 地図画面だけを確認するための暫定ルート。軌跡のある最新のトリップを開く。
private struct MapRootView: View {
    @Query(sort: \Trip.startedAt, order: .reverse) private var trips: [Trip]

    var body: some View {
        NavigationStack {
            if let trip = trips.first(where: { !$0.locationPoints.isEmpty }) {
                TripDetailView(trip: trip)
            } else {
                ContentUnavailableView("トリップがありません", systemImage: "map")
            }
        }
    }
}
