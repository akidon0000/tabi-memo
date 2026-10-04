import Domain
import SwiftUI

/// 地図にある写真の一覧。リストとグリッドを切り替えて見比べられる(決まったら1つにする)。
/// 行を押すとその写真を開く。並べ替え・取り除く・編集ができる。
struct PhotoListView: View {
    enum Style: String, CaseIterable, Identifiable {
        case list = "リスト", grid = "グリッド"
        var id: String { rawValue }
    }

    @State private var viewModel: PhotoListViewModel
    var onSelect: (Photo) -> Void

    @Environment(AppDependencies.self) private var dependencies
    @Environment(\.dismiss) private var dismiss
    @AppStorage("photoListStyle") private var styleRaw = Style.list.rawValue
    @State private var editing: Photo?
    @State private var photoToRemove: Photo?

    init(viewModel: PhotoListViewModel, onSelect: @escaping (Photo) -> Void) {
        _viewModel = State(initialValue: viewModel)
        self.onSelect = onSelect
    }

    private var style: Style { Style(rawValue: styleRaw) ?? .list }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.photos.isEmpty {
                    ContentUnavailableView("写真はまだありません", systemImage: "photo.on.rectangle")
                } else if style == .list {
                    PhotoListRows(viewModel: viewModel, onOpen: open, onEdit: { editing = $0 }, onRemove: { photoToRemove = $0 })
                } else {
                    PhotoGrid(viewModel: viewModel, onOpen: open, onEdit: { editing = $0 }, onRemove: { photoToRemove = $0 })
                }
            }
            .navigationTitle("写真の一覧")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbar }
            .sheet(item: $editing) { EditPhotoView(viewModel: dependencies.makeEditPhotoViewModel(photo: $0)) }
            .confirmationDialog(
                "この写真を取り除きますか?",
                isPresented: Binding(get: { photoToRemove != nil }, set: { if !$0 { photoToRemove = nil } }),
                titleVisibility: .visible
            ) {
                Button("写真を取り除く", role: .destructive) {
                    if let photo = photoToRemove { viewModel.remove(photo) }
                    photoToRemove = nil
                }
            } message: {
                Text("取り除いた写真は「最近取り除いた項目」に\(PhotoRetention.days)日間残ります。")
            }
        }
        .task { await viewModel.start() }
    }

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("閉じる") { dismiss() }
        }
        ToolbarItem(placement: .principal) {
            Picker("表示", selection: $styleRaw) {
                ForEach(Style.allCases) { Text($0.rawValue).tag($0.rawValue) }
            }
            .pickerStyle(.segmented)
            .frame(width: 180)
        }
        if style == .list {
            ToolbarItem(placement: .confirmationAction) { EditButton() }
        }
    }

    private func open(_ photo: Photo) {
        onSelect(photo)
        dismiss()
    }
}
