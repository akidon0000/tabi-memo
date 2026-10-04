import Domain
import SwiftUI

/// 一覧のリスト表示。左スワイプで編集、右スワイプで取り除く。編集モードで並べ替える。
struct PhotoListRows: View {
    let viewModel: PhotoListViewModel
    var onOpen: (Photo) -> Void
    var onEdit: (Photo) -> Void
    var onRemove: (Photo) -> Void

    var body: some View {
        List {
            ForEach(viewModel.photos) { photo in
                Button { onOpen(photo) } label: { row(photo) }
                    .buttonStyle(.plain)
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) { onRemove(photo) } label: { Label("取り除く", systemImage: "trash") }
                    }
                    .swipeActions(edge: .leading) {
                        Button { onEdit(photo) } label: { Label("編集", systemImage: "pencil") }
                            .tint(.blue)
                    }
            }
            .onMove { viewModel.move(fromOffsets: $0, toOffset: $1) }
        }
    }

    private func row(_ photo: Photo) -> some View {
        HStack(spacing: 12) {
            photo.image
                .resizable()
                .scaledToFill()
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            VStack(alignment: .leading, spacing: 2) {
                Text(photo.title.isEmpty ? "タイトルなし" : photo.title)
                    .foregroundStyle(photo.title.isEmpty ? .secondary : .primary)
                Text(photo.takenAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .contentShape(Rectangle())
    }
}
