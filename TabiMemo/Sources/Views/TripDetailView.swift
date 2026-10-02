import MapKit
import SwiftData
import SwiftUI

struct TripDetailView: View {
    @Bindable var trip: Trip
    /// シートに表示中の写真。別のピンをタップしても、シートは閉じずに中身だけ差し替える。
    @State private var sheetItem: PhotoSheetItem?
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
                        sheetItem = PhotoSheetItem(photo: photo)
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
        .overlay(alignment: .bottomTrailing) {
            addPhotoButton
        }
        .sheet(item: $sheetItem) { item in
            let photo = item.photo
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

private extension TripDetailView {
    /// 右下のタブのような円形の追加ボタン。コンパクトのシートが出ているときは、その上に避ける。
    var addPhotoButton: some View {
        Button {
            // TODO: 写真の追加(未実装)
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 22, weight: .bold))
                .frame(width: 56, height: 56)
                .background(.regularMaterial, in: .circle)
                .shadow(color: .black.opacity(0.25), radius: 4, y: 2)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("写真を追加")
        .padding(.trailing, 16)
        .padding(.bottom, sheetItem == nil ? 16 : 80)
        .animation(.spring(duration: 0.35), value: sheetItem == nil)
    }
}

/// id を固定して、写真が変わってもシートを作り直さず中身だけ差し替えるためのラッパー。
private struct PhotoSheetItem: Identifiable {
    let id = "photo-sheet"
    let photo: TripPhoto
}

extension TripPhoto {
    var image: Image {
        UIImage(data: imageData).map(Image.init(uiImage:)) ?? Image(systemName: "photo")
    }
}
