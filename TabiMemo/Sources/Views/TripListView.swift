import SwiftData
import SwiftUI

struct TripListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Trip.startedAt, order: .reverse) private var trips: [Trip]
    @State private var path: [Route] = []

    var body: some View {
        NavigationStack(path: $path) {
            List {
                ForEach(trips) { trip in
                    Button {
                        path.append(.tripDetail(trip))
                    } label: {
                        TripRow(trip: trip)
                    }
                }
                .onDelete(perform: deleteTrips)
            }
            .navigationTitle("旅メモ")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        startNewTrip()
                    } label: {
                        Label("トリップ開始", systemImage: "plus")
                    }
                }
            }
            .navigationDestination(for: Route.self) { route in
                switch route {
                case let .tripDetail(trip):
                    TripDetailView(trip: trip)
                case let .replay(trip):
                    ReplayView(trip: trip)
                }
            }
            .overlay {
                if trips.isEmpty {
                    ContentUnavailableView(
                        "まだトリップがありません",
                        systemImage: "map",
                        description: Text("右上の＋から最初のトリップを開始しましょう")
                    )
                }
            }
        }
    }

    private func startNewTrip() {
        let trip = Trip(name: Trip.defaultName(for: .now))
        modelContext.insert(trip)
        path.append(.tripDetail(trip))
    }

    private func deleteTrips(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(trips[index])
        }
    }
}

private struct TripRow: View {
    let trip: Trip

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(trip.name)
                    .font(.headline)
                Text(trip.startedAt, style: .date)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if trip.isActive {
                Label("記録中", systemImage: "location.fill")
                    .labelStyle(.iconOnly)
                    .foregroundStyle(Color.accentColor)
            }
        }
    }
}

extension Trip {
    static func defaultName(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "M月d日の旅"
        return formatter.string(from: date)
    }
}
