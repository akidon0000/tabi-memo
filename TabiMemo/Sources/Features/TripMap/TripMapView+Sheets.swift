import Domain
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
                EditPhotoView(viewModel: dependencies.makeEditPhotoViewModel(photo: photo))
            }
            .sheet(isPresented: $showPhotoList) {
                PhotoListView(viewModel: dependencies.makePhotoListViewModel(tripID: trip.id), onSelect: open)
            }
            .sheet(isPresented: $showRecentlyDeleted) {
                RecentlyDeletedView(viewModel: dependencies.makeRecentlyDeletedViewModel(tripID: trip.id))
            }
            .sheet(item: $addFlow) { flow in
                AddPhotosView(viewModel: flow.viewModel, items: flow.items) { addFlow = nil }
            }
    }

    func addPhoto() {
        showPhotoPicker = true
    }

    /// ピッカーが閉じたあと、詳細入力のモーダルを(読み込み中の状態で)すぐ開く。
    private func startAddFlow(with items: [PhotosPickerItem], trip: Trip) {
        let viewModel = dependencies.makeAddPhotosViewModel(count: items.count, trip: trip, fallbackCenter: fallbackCenter(for: trip))
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
