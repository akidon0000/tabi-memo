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

/// 地図上の吹き出し型サムネイルピン。タップで写真の半モーダル表示を開く。
private struct PhotoPinCallout: View {
    let photo: TripPhoto
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 0) {
                thumbnail
                    .frame(width: 52, height: 52)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .padding(4)
                    .background(.background, in: RoundedRectangle(cornerRadius: 10))
                CalloutTail()
                    .fill(.background)
                    .frame(width: 14, height: 7)
            }
            .shadow(color: .black.opacity(0.25), radius: 3, y: 1)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var thumbnail: some View {
        if let uiImage = UIImage(data: photo.imageData) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
        } else {
            Color.secondary.opacity(0.3)
        }
    }
}

/// 吹き出しの下向きの尖り部分。
private struct CalloutTail: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.closeSubpath()
        return path
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
