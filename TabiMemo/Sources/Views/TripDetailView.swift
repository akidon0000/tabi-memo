import MapKit
import SwiftData
import SwiftUI

struct TripDetailView: View {
    @Bindable var trip: Trip
    /// パネルに表示中の写真。別のピンをタップしても、パネルは閉じずに中身だけ差し替える。
    @State private var selectedPhoto: TripPhoto?
    @State private var sheetConfig = CustomSheetConfig()
    @State private var zoomedPhoto: TripPhoto?

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
                        onImageTap: { zoomedPhoto = photo },
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
        // 拡大表示は下からせり上げず、後ろからふわっと(薄い・小さい状態から)出す。
        .overlay {
            if let photo = zoomedPhoto {
                PhotoZoomView(photo: photo) { zoomedPhoto = nil }
                    .transition(.opacity.combined(with: .scale(scale: 0.92)))
                    .zIndex(1)
            }
        }
        .animation(.easeOut(duration: 0.3), value: zoomedPhoto?.id)
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

/// 写真の拡大表示。ピンチで拡大・ダブルタップで切り替え・拡大中はドラッグで移動。下に引くか×で閉じる。
private struct PhotoZoomView: View {
    let photo: TripPhoto
    var dismiss: () -> Void
    @State private var scale: CGFloat = 1
    @State private var baseScale: CGFloat = 1
    @State private var offset: CGSize = .zero
    @State private var baseOffset: CGSize = .zero

    var body: some View {
        ZStack {
            Color.black.opacity(1 - min(max(offset.height, 0) / 600, 0.5)).ignoresSafeArea()
            photo.image
                .resizable()
                .scaledToFit()
                .scaleEffect(scale)
                .offset(offset)
                .gesture(
                    MagnifyGesture()
                        .onChanged { scale = max(baseScale * $0.magnification, 1) }
                        .onEnded { _ in
                            baseScale = scale
                            if scale <= 1.01 { reset() }
                        }
                )
                .simultaneousGesture(
                    DragGesture()
                        .onChanged { value in
                            if scale > 1 {
                                offset = CGSize(width: baseOffset.width + value.translation.width,
                                                height: baseOffset.height + value.translation.height)
                            } else {
                                offset = CGSize(width: 0, height: max(value.translation.height, 0))
                            }
                        }
                        .onEnded { value in
                            if scale <= 1 {
                                if value.translation.height > 120 { dismiss() } else { withAnimation(.spring) { offset = .zero } }
                            } else {
                                baseOffset = offset
                            }
                        }
                )
                .onTapGesture(count: 2) {
                    withAnimation(.spring(duration: 0.3)) {
                        if scale > 1 { reset() } else { scale = 2.5; baseScale = 2.5 }
                    }
                }
        }
        .overlay(alignment: .topTrailing) {
            Button { dismiss() } label: { Image(systemName: "xmark") }
                .buttonStyle(.glass)
                .buttonBorderShape(.circle)
                .padding()
                .accessibilityLabel("閉じる")
        }
    }

    private func reset() {
        withAnimation(.spring(duration: 0.3)) {
            scale = 1; baseScale = 1; offset = .zero; baseOffset = .zero
        }
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
