import MapKit
import SwiftData
import SwiftUI

struct TripDetailView: View {
    @Bindable var trip: Trip

    var body: some View {
        Map {
            if trip.locationPoints.count > 1 {
                MapPolyline(coordinates: trip.locationPoints
                    .sorted { $0.timestamp < $1.timestamp }
                    .map(\.coordinate))
                    .stroke(Color.accentColor, lineWidth: 3)
            }
            ForEach(trip.photos) { photo in
                Annotation(photo.takenAt.formatted(date: .omitted, time: .shortened), coordinate: photo.coordinate) {
                    Image(systemName: "photo.circle.fill")
                        .font(.title2)
                        .foregroundStyle(Color.accentColor)
                        .background(.background, in: .circle)
                }
            }
        }
        .navigationTitle(trip.name)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if trip.isActive {
                    Button("トリップ終了") {
                        trip.endedAt = .now
                    }
                } else {
                    NavigationLink(value: Route.replay(trip)) {
                        Label("リプレイ", systemImage: "play.circle")
                    }
                }
            }
        }
    }
}

extension LocationPoint {
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

extension TripPhoto {
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
