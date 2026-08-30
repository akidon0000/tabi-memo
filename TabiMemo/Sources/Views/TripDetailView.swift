import MapKit
import SwiftData
import SwiftUI

struct TripDetailView: View {
    @Bindable var trip: Trip
    @State private var selectedPhoto: TripPhoto?

    var body: some View {
        Map {
            if trip.locationPoints.count > 1 {
                MapPolyline(coordinates: trip.locationPoints
                    .sorted { $0.timestamp < $1.timestamp }
                    .map(\.coordinate))
                    .stroke(Color.accentColor, lineWidth: 3)
            }
            ForEach(trip.photos) { photo in
                Annotation(
                    photo.takenAt.formatted(date: .omitted, time: .shortened),
                    coordinate: photo.coordinate,
                    anchor: .bottom
                ) {
                    PhotoPinCallout(photo: photo) {
                        selectedPhoto = photo
                    }
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
        .sheet(item: $selectedPhoto) { photo in
            PhotoDetailSheet(photo: photo)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }
}

/// 写真ピンをタップしたときに半モーダル(.medium)で開く詳細表示。
private struct PhotoDetailSheet: View {
    let photo: TripPhoto

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                if let uiImage = UIImage(data: photo.imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                Text(photo.takenAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.headline)
                if photo.isLocationManuallyPlaced {
                    Label("位置は手動で指定されました", systemImage: "hand.tap")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
        }
    }
}
