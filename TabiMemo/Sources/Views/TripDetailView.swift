import MapKit
import SwiftData
import SwiftUI

struct TripDetailView: View {
    @Bindable var trip: Trip
    /// パネルに表示中の写真。別のピンをタップしても、パネルは閉じずに中身だけ差し替える。
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
        .navigationBarTitleDisplayMode(.inline)
        .overlay {
            ZStack {
                if let photo = selectedPhoto {
                    CustomSheetView(
                        config: $sheetConfig,
                        title: photo.takenAt.formatted(date: .abbreviated, time: .shortened),
                        caption: photo.isLocationManuallyPlaced ? "位置は手動で指定されました" : "",
                        headerImage: photo.image,
                        onAdd: addPhoto
                    ) {
                        EmptyView()
                    }
                    .transition(.move(edge: .bottom))
                } else {
                    addPhotoButton
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                        .transition(.opacity)
                }
            }
            .ignoresSafeArea(edges: .bottom)
            .animation(.spring(duration: 0.4), value: selectedPhoto == nil)
        }
    }

    private func addPhoto() {
        // TODO: 写真の追加(未実装)
    }
}

private extension TripDetailView {
    /// パネルがないときの、右下の円形の追加ボタン。パネルのコンパクト時のボタンと同じ位置に置く。
    var addPhotoButton: some View {
        Button(action: addPhoto) {
            Image(systemName: "plus")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.primary)
                .frame(width: 56, height: 56)
                .glassEffect(.regular.tint(.yellow.opacity(0.3)).interactive(), in: .circle)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("写真を追加")
        .padding(.trailing, 16)
        .padding(.bottom, 40)
    }
}

extension TripPhoto {
    var image: Image {
        UIImage(data: imageData).map(Image.init(uiImage:)) ?? Image(systemName: "photo")
    }
}
