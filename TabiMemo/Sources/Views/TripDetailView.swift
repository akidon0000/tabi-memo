import MapKit
import SwiftData
import SwiftUI

struct TripDetailView: View {
    @Bindable var trip: Trip
    @State private var selectedPhoto: TripPhoto?
    @State private var sheetConfig = CustomSheetConfig()

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
        .mapStyle(.hybrid())
        .onGeometryChange(for: CGSize.self) {
            $0.size
        } action: { newValue in
            sheetConfig.largestDetentHeight = newValue.height - 10
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedPhoto) { photo in
            CustomSheetView(
                config: $sheetConfig,
                title: photo.takenAt.formatted(date: .abbreviated, time: .shortened),
                caption: photo.isLocationManuallyPlaced ? "位置は手動で指定されました" : "",
                headerImage: photo.image
            ) {
                EmptyView()
            }
        }
    }
}

extension TripPhoto {
    var image: Image {
        UIImage(data: imageData).map(Image.init(uiImage:)) ?? Image(systemName: "photo")
    }
}
