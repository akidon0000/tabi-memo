import Domain
import SharedUI
import SwiftUI

/// 一覧のグリッド表示。サムネイルを別のサムネイルへドラッグすると並べ替わる。長押しで編集・取り除く。
struct PhotoGrid: View {
    let viewModel: PhotoListViewModel
    var onOpen: (Photo) -> Void
    var onEdit: (Photo) -> Void
    var onRemove: (Photo) -> Void

    var body: some View {
        ScrollView {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 3), count: 3), spacing: 3) {
                ForEach(viewModel.photos) { photo in
                    cell(photo)
                }
            }
        }
    }

    private func cell(_ photo: Photo) -> some View {
        Button { onOpen(photo) } label: {
            Color.clear
                .aspectRatio(1, contentMode: .fit)
                .overlay {
                    photo.image.resizable().scaledToFill()
                }
                .clipped()
        }
        .buttonStyle(.plain)
        // ドラッグして別のサムネイルへ落とすと、その位置へ並べ替わる。
        .draggable(photo.id.uuidString)
        .dropDestination(for: String.self) { ids, _ in
            guard let id = ids.first.flatMap(UUID.init(uuidString:)) else { return false }
            return viewModel.move(id, to: photo)
        }
        .contextMenu {
            Button { onEdit(photo) } label: { Label("編集", systemImage: "pencil") }
            Button(role: .destructive) { onRemove(photo) } label: { Label("取り除く", systemImage: "trash") }
        }
    }
}
