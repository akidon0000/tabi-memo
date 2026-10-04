import MapKit
import PhotosUI
import SwiftData
import SwiftUI

struct TripDetailView: View {
    @Bindable var trip: Trip
    /// パネルに表示中の写真。別のピンをタップしても、パネルは閉じずに中身だけ差し替える。
    @State private var selectedPhoto: TripPhoto?
    @State private var sheetConfig = CustomSheetConfig()
    @State private var zoomedPhoto: TripPhoto?
    @State private var cameraPosition: MapCameraPosition = .automatic
    /// いまの地図の表示範囲。スワイプで移動するとき、拡大率を保ったまま中心だけ動かすのに使う。
    @State private var visibleRegion: MKCoordinateRegion?
    @State private var showPhotoPicker = false
    @State private var pickedItems: [PhotosPickerItem] = []
    @State private var addFlow: AddFlow?
    @State private var confirmDelete = false
    @State private var showRecentlyDeleted = false
    @Environment(\.modelContext) private var modelContext

    /// 写真の追加の流れ。ピッカーで選んだ項目と、その入力状態を一組で持つ。
    private struct AddFlow: Identifiable {
        let model: AddPhotosModel
        let items: [PhotosPickerItem]
        var id: AddPhotosModel.ID { model.id }
    }

    var body: some View {
        Map(position: $cameraPosition) {
            if trip.locationPoints.count > 1 {
                MapPolyline(coordinates: trip.locationPoints
                    .sorted { $0.timestamp < $1.timestamp }
                    .map(\.coordinate))
                    .stroke(Color.accentColor, lineWidth: 3)
            }
            ForEach(trip.activePhotos) { photo in
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
        .onMapCameraChange(frequency: .onEnd) { visibleRegion = $0.region }
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
                        onPage: { if let next = neighbor($0, of: photo) { selectedPhoto = next; focusMap(on: next) } },
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
        .overlay(alignment: .topTrailing) { moreMenu }
        // 拡大表示は下からせり上げず、後ろからふわっと(薄い・小さい状態から)出す。
        .overlay {
            if let photo = zoomedPhoto {
                PhotoZoomView(photo: photo) { zoomedPhoto = nil }
                    .transition(.opacity.combined(with: .scale(scale: 0.92)))
                    .zIndex(1)
            }
        }
        .animation(.easeOut(duration: 0.3), value: zoomedPhoto?.id)
        .photosPicker(isPresented: $showPhotoPicker, selection: $pickedItems, maxSelectionCount: nil, matching: .images)
        .onChange(of: pickedItems) { _, items in
            guard !items.isEmpty else { return }
            pickedItems = []
            startAddFlow(with: items)
        }
        .task { trip.purgeExpiredPhotos(in: modelContext) }
        .confirmationDialog("この写真は、ライブラリから削除されます。", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("写真を削除", role: .destructive, action: deleteSelectedPhoto)
        } message: {
            Text("削除した写真は「最近削除した項目」に\(PhotoRetention.days)日間残ります。")
        }
        .sheet(isPresented: $showRecentlyDeleted) {
            RecentlyDeletedView(trip: trip)
        }
        .sheet(item: $addFlow) { flow in
            AddPhotosView(model: flow.model, items: flow.items, trip: trip) { addFlow = nil }
        }
    }

    /// 撮影順で隣の写真(step: 前 -1 / 次 +1)。端なら nil。
    private func neighbor(_ step: Int, of photo: TripPhoto) -> TripPhoto? {
        let sorted = trip.activePhotos.sorted { $0.takenAt < $1.takenAt }
        guard let index = sorted.firstIndex(where: { $0.id == photo.id }),
              sorted.indices.contains(index + step) else { return nil }
        return sorted[index + step]
    }

    /// 地図をその写真のスポットへ動かす(パネルに隠れない位置へ)。拡大率は変えない。
    private func focusMap(on photo: TripPhoto) {
        let span = visibleRegion?.span ?? MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
        withAnimation(.easeInOut(duration: 0.8)) {
            // スポットが画面の上から1/4の高さに来るよう、中心を表示範囲の1/4だけ南へずらす(下のパネルに隠れない)。
            let center = CLLocationCoordinate2D(
                latitude: photo.coordinate.latitude - span.latitudeDelta * 0.25,
                longitude: photo.coordinate.longitude
            )
            cameraPosition = .region(MKCoordinateRegion(center: center, span: span))
        }
    }

    /// 選んでいる写真を「最近削除した項目」へ移す。隣の写真(次があれば次、なければ前)へ切り替わり、最後の1枚なら閉じる。
    private func deleteSelectedPhoto() {
        guard let photo = selectedPhoto else { return }
        let next = neighbor(1, of: photo) ?? neighbor(-1, of: photo)
        photo.deletedAt = .now
        try? modelContext.save()
        selectedPhoto = next
        if let next { focusMap(on: next) }
    }

    private func addPhoto() {
        showPhotoPicker = true
    }

    /// ピッカーが閉じたあと、詳細入力のモーダルを(読み込み中の状態で)すぐ開く。
    private func startAddFlow(with items: [PhotosPickerItem]) {
        let fallback = visibleRegion?.center
            ?? trip.activePhotos.first?.coordinate
            ?? CLLocationCoordinate2D(latitude: 35.6812, longitude: 139.7671)
        let model = AddPhotosModel(count: items.count, existingPhotos: trip.activePhotos, fallbackCenter: fallback)
        Task {
            try? await Task.sleep(for: .milliseconds(400))
            addFlow = AddFlow(model: model, items: items)
        }
    }
}

private extension TripDetailView {
    /// 右上に常に出す「…」。写真を選んでいるときだけ「写真を削除」が加わる。
    var moreMenu: some View {
        Menu {
            Button { showRecentlyDeleted = true } label: {
                Label("最近削除した項目", systemImage: "trash")
            }
            if selectedPhoto != nil {
                Button(role: .destructive) { confirmDelete = true } label: {
                    Label("写真を削除", systemImage: "trash")
                }
            }
        } label: {
            Image(systemName: "ellipsis")
                .font(.system(size: 17, weight: .semibold))
                .frame(width: 44, height: 44)
                .contentShape(Circle())
        }
        .buttonStyle(.glass)
        .buttonBorderShape(.circle)
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .accessibilityLabel("メニュー")
    }

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

/// 写真の拡大表示。ピンチで拡大・ダブルタップで切り替え・拡大中はドラッグで移動。下スワイプか×で閉じる。
private struct PhotoZoomView: View {
    let photo: TripPhoto
    var dismiss: () -> Void
    @State private var scale: CGFloat = 1
    @State private var baseScale: CGFloat = 1
    @State private var offset: CGSize = .zero
    @State private var baseOffset: CGSize = .zero

    var body: some View {
        ZStack {
            Color.black.opacity(1 - min(max(offset.height, 0) / 500, 0.6)).ignoresSafeArea()
            photo.image
                .resizable()
                .scaledToFit()
                // 等倍で下に引いているときは、引いた量だけ小さくして「離れていく」ことを伝える。
                .scaleEffect(scale * (scale <= 1 ? 1 - min(max(offset.height, 0) / 1500, 0.2) : 1))
                .offset(offset)
        }
        // 写真の上だけでなく、黒い余白のどこをドラッグしても反応するよう、全体に付ける。
        .contentShape(Rectangle())
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
                        // 80pt 以上引くか、下へ勢いよく払ったら閉じる。
                        if value.translation.height > 80 || value.predictedEndTranslation.height > 300 {
                            dismiss()
                        } else {
                            withAnimation(.spring) { offset = .zero }
                        }
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
