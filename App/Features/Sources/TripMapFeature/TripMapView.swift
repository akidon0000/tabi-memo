import AddPhotosFeature
import CameraFeature
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
    /// 「+」を押したあとの、カメラで撮るか・ライブラリから選ぶかの選択。
    @State var showAddChoice = false
    @State var showCamera = false
    /// 選択用のシートを閉じたあとに開くもの(閉じる途中で次の画面を開かないため)。
    @State var pendingAdd: AddSource?
    @Environment(\.dismiss) var dismiss
    @AppStorage(AppearanceKey.backButton) var backButton = BackButtonPlacement.topLeading
    @AppStorage(AppearanceKey.addChoice) var addChoice = AddChoiceStyle.actionSheet
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
    /// 地図の長押しで指定された、追加する写真の位置。「+」から追加するときは nil。
    @State var placement: Coordinate?
    /// 開いた直後の、最初の写真への地図の移動を済ませたか。
    @State var didFocusInitially = false
    /// 経路編集モードで、いま掴んでいる点・線。
    @State var routeDrag: RouteDrag?
    /// 再生の間、地図の拡大率を保つための、再生を始めたときの表示範囲。
    @State var playbackSpan = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    /// 経路編集モード中、地図の移動・拡大を止めるか(止めない案と見比べるための設定)。
    @AppStorage("routeEditLocksMap") var routeEditLocksMap = true

    /// 写真の追加の流れ。ピッカーで選んだ項目と、その入力状態を一組で持つ。
    struct AddFlow: Identifiable {
        let viewModel: AddPhotosViewModel
        let source: AddPhotosSource
        var id: ObjectIdentifier { ObjectIdentifier(viewModel) }
    }

    public init(viewModel: TripMapViewModel, children: TripMapChildren) {
        _viewModel = State(initialValue: viewModel)
        self.children = children
    }

    /// 追加の出どころ。
    enum AddSource { case camera, library }

    public var body: some View {
        Group {
            if let trip = viewModel.trip {
                content(trip)
            } else if viewModel.hasLoaded {
                ContentUnavailableView("トリップがありません", systemImage: "map")
            }
        }
        .navigationBarBackButtonHidden()
        .task { await viewModel.start() }
    }

    private func content(_ trip: Trip) -> some View {
        let screen = map(trip)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
            .overlay { panelLayer }
            // 再生中、写真の場所に着いたら、その写真を拡大して見せる。停止ボタンは、この上に出す。
            .overlay { playbackPhotoLayer(trip) }
            .animation(.spring(duration: 0.45), value: viewModel.playback.featuredPhotoID)
            .overlay(alignment: .topTrailing) { if !viewModel.route.isEditing { topControls } }
            .overlay(alignment: .topLeading) { if backButton == .topLeading { backControl } }
            .overlay(alignment: .bottom) { if viewModel.playback.isPlaying { playbackSpeedControl } }
            .overlay(alignment: .top) { if viewModel.route.isEditing { routeEditBar } }
            // 拡大表示は下からせり上げず、後ろからふわっと(薄い・小さい状態から)出す。
            .overlay {
                if let photo = zoomedPhoto {
                    PhotoZoomView(image: photo.image) { zoomedPhoto = nil }
                        .transition(.opacity.combined(with: .scale(scale: 0.92)))
                        .zIndex(1)
                }
            }
            .animation(.easeOut(duration: 0.3), value: zoomedPhoto?.id)
            .onChange(of: viewModel.playback.sample) { _, sample in
                if let sample { followPlayback(sample) }
            }
            .task(id: trip.id) { await centerOnCurrentLocationIfEmpty(trip) }
            .onAppear {
                // 開いた直後は最初の写真が選ばれているので、地図もそのスポットへ動かす(パネルに隠れないように)。
                guard !didFocusInitially, let photo = viewModel.selectedPhoto else { return }
                didFocusInitially = true
                focusMap(on: photo)
            }
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

    /// 再生で止まっている写真の拡大。広がるときは一定の速さ、閉じるときは下の spring のまま。
    @ViewBuilder
    private func playbackPhotoLayer(_ trip: Trip) -> some View {
        if let photo = featuredPlaybackPhoto(in: trip) {
            PlaybackPhotoView(image: photo.image)
                .transition(.asymmetric(
                    insertion: AnyTransition.opacity.combined(with: .scale(scale: 0.6)).animation(.linear(duration: 0.45)),
                    removal: .opacity.combined(with: .scale(scale: 0.6))
                ))
        }
    }
}
