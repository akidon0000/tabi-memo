import AddPhotosFeature
import CameraFeature
import Domain
import EditPhotoFeature
import PhotoListFeature
import RecentlyDeletedFeature
import SharedUI
import PhotosUI
import SwiftUI

extension TripMapView {
    /// 写真ピッカー、取り除く確認、編集・一覧・最近取り除いた項目・追加のシート。
    func withSheets(_ screen: some View, trip: Trip) -> some View {
        withAddChoice(screen, trip: trip)
            .photosPicker(isPresented: $showPhotoPicker, selection: $pickedItems, maxSelectionCount: nil, matching: .images)
            .onChange(of: pickedItems) { _, items in
                guard !items.isEmpty else { return }
                pickedItems = []
                startAddFlow(source: .library(items), trip: trip)
            }
            .confirmationDialog("この写真を取り除きますか?", isPresented: $confirmRemove, titleVisibility: .visible) {
                Button("写真を取り除く", role: .destructive, action: removeSelectedPhoto)
            } message: {
                Text("取り除いた写真は「最近取り除いた項目」に\(PhotoRetention.days)日間残ります。")
            }
            .sheet(item: $editingPhoto) { photo in
                EditPhotoView(viewModel: children.makeEditPhoto(photo))
            }
            .sheet(isPresented: $showPhotoList) {
                PhotoListView(viewModel: children.makePhotoList(trip.id), makeEditPhoto: children.makeEditPhoto, onSelect: open)
            }
            .sheet(isPresented: $showRecentlyDeleted) {
                RecentlyDeletedView(viewModel: children.makeRecentlyDeleted(trip.id))
            }
            .sheet(item: $addFlow) { flow in
                AddPhotosView(viewModel: flow.viewModel, source: flow.source) { saved in
                    addFlow = nil
                    if saved { fitsAfterAdding = true }
                }
            }
    }

    /// 「+」の選択(カメラ・ライブラリ)と、カメラの画面。
    private func withAddChoice(_ screen: some View, trip: Trip) -> some View {
        screen
            .confirmationDialog("写真を追加", isPresented: actionSheetBinding, titleVisibility: .visible) {
                Button("カメラで撮る") { showCamera = true }
                Button("ライブラリから選ぶ") { showPhotoPicker = true }
            }
            .sheet(isPresented: sheetBinding, onDismiss: openPendingAdd) {
                AddChoiceSheet { source in
                    pendingAdd = source
                    showAddChoice = false
                }
                .presentationDetents([.height(200)])
            }
            .fullScreenCover(isPresented: $showCamera) {
                CameraView(viewModel: children.makeCamera()) { photos in
                    showCamera = false
                    if !photos.isEmpty { startAddFlow(source: .captured(photos), trip: trip) }
                }
            }
    }

    /// 「+」から写真を追加する。カメラで撮るか、ライブラリから選ぶかを選ぶ。位置は写真の位置情報(撮った場所)から決める。
    func addPhoto() {
        placement = nil
        showAddChoice = true
    }

    /// 地図の長押しで、その場所に写真を追加する。選んだ(撮った)写真は、すべてその位置に置く。
    func addPhoto(at coordinate: Coordinate) {
        placement = coordinate
        showAddChoice = true
    }

    private var actionSheetBinding: Binding<Bool> {
        Binding(get: { showAddChoice && addChoice == .actionSheet }, set: { showAddChoice = $0 })
    }

    private var sheetBinding: Binding<Bool> {
        Binding(get: { showAddChoice && addChoice == .bottomSheet }, set: { showAddChoice = $0 })
    }

    /// 選択のシートが閉じ終わってから、選んだ出どころを開く。
    private func openPendingAdd() {
        guard let source = pendingAdd else { return }
        pendingAdd = nil
        switch source {
        case .camera: showCamera = true
        case .library: showPhotoPicker = true
        }
    }

    /// カメラ・ピッカーが閉じたあと、詳細入力のモーダルを(読み込み中の状態で)すぐ開く。
    private func startAddFlow(source: AddPhotosSource, trip: Trip) {
        let viewModel = children.makeAddPhotos(source.count, trip, fallbackCenter(for: trip), placement)
        Task {
            try? await Task.sleep(for: .milliseconds(400))
            addFlow = AddFlow(viewModel: viewModel, source: source)
        }
    }

    /// 選んでいる写真を取り除き、隣の写真へ地図を動かす。最後の1枚ならパネルが閉じる。
    private func removeSelectedPhoto() {
        if let next = viewModel.removeSelectedPhoto() { focusMap(on: next) }
    }
}
