import AddPhotosFeature
import Domain
import EditPhotoFeature
import PhotoListFeature
import RecentlyDeletedFeature
import SharedUI
import MapKit
import PhotosUI
import SwiftUI

/// 地図画面。軌跡と写真のピンを地図に出し、ピンを押すと下のパネルに写真とメモを出す。
///
/// ファイルの分け方: 地図とカメラは +Map、パネルとボタンは +Panel、シートと確認ダイアログは +Sheets。
public struct TripMapView: View {
    @State var viewModel: TripMapViewModel
    /// 子画面の ViewModel の作り方。組み立ては App が行い、この画面は作り方を知らない。
    let children: TripMapChildren

    // 見た目だけの状態(ViewModel に置かない)。別ファイルの extension から触るので private にしない。
    @State var sheetConfig = CustomSheetConfig()
    @State var zoomedPhoto: Photo?
    @State var cameraPosition: MapCameraPosition = .automatic
    /// いまの地図の表示範囲。スワイプで移動するとき、拡大率を保ったまま中心だけ動かすのに使う。
    @State var visibleRegion: MKCoordinateRegion?
    @State var showPhotoPicker = false
    @State var pickedItems: [PhotosPickerItem] = []
    @State var addFlow: AddFlow?
    @State var confirmRemove = false
    @State var showRecentlyDeleted = false
    @State var showPhotoList = false
    @State var editingPhoto: Photo?
    /// パネルの全開への進み具合。全開では右上の「…」を消して、パネルの閉じるボタンに譲る。
    @State var panelFullProgress: CGFloat = 0
    /// 地図の大きさ(pt)。ピンの重なりの判定に使う。
    @State var mapSize: CGSize = .zero
    /// 写真を保存した直後。次にトリップが更新されたら、写真が全部収まるよう地図を動かす。
    @State var fitsAfterAdding = false

    /// 写真の追加の流れ。ピッカーで選んだ項目と、その入力状態を一組で持つ。
    struct AddFlow: Identifiable {
        let viewModel: AddPhotosViewModel
        let items: [PhotosPickerItem]
        var id: ObjectIdentifier { ObjectIdentifier(viewModel) }
    }

    public init(viewModel: TripMapViewModel, children: TripMapChildren) {
        _viewModel = State(initialValue: viewModel)
        self.children = children
    }

    public var body: some View {
        NavigationStack {
            if let trip = viewModel.trip {
                content(trip)
            } else if viewModel.hasLoaded {
                ContentUnavailableView("トリップがありません", systemImage: "map")
            }
        }
        .task { await viewModel.start() }
    }

    private func content(_ trip: Trip) -> some View {
        let screen = map(trip)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
            .overlay { panelLayer }
            .overlay(alignment: .topTrailing) { moreMenu }
            // 拡大表示は下からせり上げず、後ろからふわっと(薄い・小さい状態から)出す。
            .overlay {
                if let photo = zoomedPhoto {
                    PhotoZoomView(image: photo.image) { zoomedPhoto = nil }
                        .transition(.opacity.combined(with: .scale(scale: 0.92)))
                        .zIndex(1)
                }
            }
            .animation(.easeOut(duration: 0.3), value: zoomedPhoto?.id)
            .onChange(of: viewModel.selectedPhoto == nil) { _, isClosed in
                if isClosed { panelFullProgress = 0 }
            }
            .onChange(of: trip.activePhotos.map(\.id)) {
                guard fitsAfterAdding else { return }
                fitsAfterAdding = false
                fitAllPhotos(of: trip)
            }
        return withSheets(screen, trip: trip)
    }
}
