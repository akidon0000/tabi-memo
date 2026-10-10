import AddPhotosFeature
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
        screen
            .photosPicker(isPresented: $showPhotoPicker, selection: $pickedItems, maxSelectionCount: nil, matching: .images)
            .onChange(of: pickedItems) { _, items in
                guard !items.isEmpty else { return }
                pickedItems = []
                startAddFlow(with: items, trip: trip)
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
                AddPhotosView(viewModel: flow.viewModel, items: flow.items) { saved in
                    addFlow = nil
                    if saved { fitsAfterAdding = true }
                }
            }
    }

    /// 「+」から写真を追加する。位置は写真の位置情報から決める。
    func addPhoto() {
        placement = nil
        showPhotoPicker = true
    }

    /// 地図の長押しで、その場所に写真を追加する。選んだ写真は、すべてその位置に置く。
    func addPhoto(at coordinate: Coordinate) {
        placement = coordinate
        showPhotoPicker = true
    }

    /// ピッカーが閉じたあと、詳細入力のモーダルを(読み込み中の状態で)すぐ開く。
    private func startAddFlow(with items: [PhotosPickerItem], trip: Trip) {
        let viewModel = children.makeAddPhotos(items.count, trip, fallbackCenter(for: trip), placement)
        Task {
            try? await Task.sleep(for: .milliseconds(400))
            addFlow = AddFlow(viewModel: viewModel, items: items)
        }
    }

    /// 選んでいる写真を取り除き、隣の写真へ地図を動かす。最後の1枚ならパネルが閉じる。
    private func removeSelectedPhoto() {
        if let next = viewModel.removeSelectedPhoto() { focusMap(on: next) }
    }
}
