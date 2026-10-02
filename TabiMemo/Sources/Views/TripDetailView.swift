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
        .toolbar(.hidden, for: .navigationBar)
        .overlay {
            ZStack {
                if let photo = selectedPhoto {
                    CustomSheetView(
                        config: $sheetConfig,
                        title: photo.takenAt.formatted(date: .abbreviated, time: .shortened),
                        caption: photo.isLocationManuallyPlaced ? "位置は手動で指定されました" : "",
                        headerImage: photo.image,
                        headerAspectRatio: photo.aspectRatio,
                        onAdd: addPhoto,
                        canPage: { neighbor($0, of: photo) != nil },
                        onPage: { if let next = neighbor($0, of: photo) { selectedPhoto = next } },
                        neighbor: { step in
                            neighbor(step, of: photo).map {
                                PageSnapshot(
                                    title: $0.takenAt.formatted(date: .abbreviated, time: .shortened),
                                    image: $0.image,
                                    aspectRatio: $0.aspectRatio,
                                    content: AnyView(PhotoMemoView(photo: $0))
                                )
                            }
                        }
                    ) {
                        PhotoMemoView(photo: photo)
                    }
                    .transition(.move(edge: .bottom))
                } else {
                    addPhotoButton
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                        .transition(.opacity)
                }
            }
            .ignoresSafeArea()
            .animation(.spring(duration: 0.4), value: selectedPhoto == nil)
        }
    }

    /// 撮影順で隣の写真(step: 前 -1 / 次 +1)。端なら nil。
    private func neighbor(_ step: Int, of photo: TripPhoto) -> TripPhoto? {
        let sorted = trip.photos.sorted { $0.takenAt < $1.takenAt }
        guard let index = sorted.firstIndex(where: { $0.id == photo.id }),
              sorted.indices.contains(index + step) else { return nil }
        return sorted[index + step]
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
                .frame(width: 64, height: 64)
                .glassEffect(.regular.interactive(), in: .circle)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("写真を追加")
        .padding(.trailing, 16)
        .padding(.bottom, 28)
    }
}

/// 写真に添えるメモ。パネルの中身(写真の下)に出て、写真と一緒にスクロールする。
private struct PhotoMemoView: View {
    @Bindable var photo: TripPhoto

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("メモ")
                .font(.headline)
            TextField("メモを書く", text: $photo.memo, axis: .vertical)
                .lineLimit(5...)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        // キーボードで隠れないよう下に余白を取る。写真が上へ流れきるまでスクロールもできる。
        .padding(.bottom, 360)
    }
}

extension TripPhoto {
    /// 幅 / 高さ。画像が読めないときは横長(3:2)として扱う。
    var aspectRatio: CGFloat {
        guard let size = UIImage(data: imageData)?.size, size.height > 0 else { return 1.5 }
        return size.width / size.height
    }

    var image: Image {
        UIImage(data: imageData).map(Image.init(uiImage:)) ?? Image(systemName: "photo")
    }
}
